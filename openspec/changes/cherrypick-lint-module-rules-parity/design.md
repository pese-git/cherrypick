## Context

`cherrypick_lint` покрывает три правила вокруг `@module`: `module_must_be_abstract`, `module_method_missing_binding` и (через `params_requires_provide`/`named_value_must_not_be_empty`) часть аннотационной валидации. Основание для них — `AnnotationValidator` из `cherrypick_generator`, но сверки с реальным поведением `moduleBuilder` не проводилось: правила писались по документации и по коду валидатора, а не по прогону сборки.

Сверка (эта итерация) выполнена через `build_test`: `testBuilder(moduleBuilder(BuilderOptions.empty), {'a|lib/test_module.dart': input})` на семи вариантах входа, с чтением `assetsWritten` и лога сборки. Результаты — в proposal.md; ниже только выводы, влияющие на дизайн.

## Goals / Non-Goals

**Goals:**

- Привести правила `@module` в соответствие с проверенным поведением генератора: покрыть обязательные условия (part-директива, наследование `Module`) и снять расхождение по видимости методов.
- Сохранить честность мотивировок: в тексте каждого правила должна быть настоящая причина отказа, а не предположение.

**Non-Goals:**

- Полный паритет с `AnnotationValidator`. Четыре его проверки остаются без правил: `@instance` вместе с `@provide`, `@singleton` с `void`-возвратом, `@named` не по правилам идентификатора, `@module`-класс без публичных методов (последняя к тому же мертва для чистого `@module` — `validateClassAnnotations` вызывается только из `inject_generator`). Отдельная итерация.
- Абстрактные методы в `@module`-классе. Прогон показал: генератор их отбрасывает (`!m.isAbstract`), но сгенерированный `final class $Foo extends Foo` их не реализует и не компилируется, а с `@provide` абстрактный метод даёт молча пустой `builder()`. Это отдельный класс проблемы с другой формулировкой, и текущее поведение `module_method_missing_binding` (репортит на них) не меняется.

## Decisions

**`module_requires_part_directive` — severity `error`.** Отказ полностью тихий: сборка успешна, выхлопа нет, единственный сигнал — `[WARNING]` в логе `build_runner`. Именно тот случай, где статический анализ ценнее всего. Quick fix («Add the generated part directive») вставляет `part '<файл>.module.cherrypick.g.dart';` после последней директивы библиотеки.

**Ожидаемое имя part-файла берётся из AST, не из `RuleContext`.** `unit.declaredFragment?.source.shortName` доступен в обоих поддерживаемых мажорах `analyzer` (12.1.0 и 14.3.0) — в отличие от полей `RuleContext`, состав которых между мажорами менялся. Это же имя формирует и генератор (`element.firstFragment.libraryFragment.source.shortName`).

**Классы в part-файлах пропускаются.** Если `@module`-класс объявлен в part-файле, директива принадлежит владеющей библиотеке, которой этот visitor не видит. Наличие `PartOfDirective` в юните — условие выхода, чтобы не давать ложную диагностику.

**`module_must_extend_module` — по `allSupertypes`, не по `extendsClause`.** Промежуточный базовый класс (`abstract class BaseModule extends Module`) — законная композиция, и генератору достаточно, чтобы `builder`/`bind` были доступны. Проверка `element.allSupertypes.any(...)` покрывает и прямой, и косвенный случай. Quick fix'а нет: исправление требует импорта `package:cherrypick/cherrypick.dart` и выбора базового класса.

**`module_must_be_abstract` остаётся `error`.** Формального требования у генератора нет, но работающего конкретного варианта не существует: без `builder` класс отвергает Dart (`non_abstract_class_inherits_abstract_member`), с `builder` — генератор (`Method must be marked with either @instance or @provide annotation`, проверено прогоном на `class TestModule extends Module` с рукописным `builder`). Понижение до `info`/`warning` рассматривалось и отклонено: последствия жёсткие в обоих направлениях, меняется только мотивировка.

**`module_method_missing_binding` освобождает только геттеры и сеттеры.** Ориентир — состав `ClassElement.methods` в новой element-модели: аксессоры лежат в `.getters`/`.setters` и до валидатора не доходят, а операторы, приватные и `static`-методы — доходят. Это меняет поведение правила на существующем коде, что зафиксировано в CHANGELOG как ожидаемое.

## Risks / Trade-offs

- **Новые диагностики на существующем коде.** Приватный хелпер в `@module`-классе теперь `error`. Смягчение: у пользователя есть `diagnostics: module_method_missing_binding: false` и построчный `// ignore:`; кроме того, такой код всё равно не собирается кодогенерацией.
- **Quick fix для part-директивы не покрыт тестами.** Как и остальные пять: в `analyzer_testing` нет API для проверки фиксов, `dart fix` фиксы плагинов не применяет. Проверка глазами в IDE.
- **`module_requires_part_directive` предполагает, что пользователь запускает кодогенерацию.** Написанный руками `Module` без аннотаций правило не трогает (нет `@module`), так что ложных срабатываний на ручных модулях нет.
