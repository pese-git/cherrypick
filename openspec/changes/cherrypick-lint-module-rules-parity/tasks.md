## 1. Разведка

- [x] 1.1 Прогнать `moduleBuilder` через `build_test` на кейсах: приватный метод, `static`-метод, абстрактный метод, абстрактный метод с `@provide`, конкретный класс, отсутствие part-директивы, отсутствие `extends Module`
      Итог: приватный и `static` — `[SEVERE]`, сборка падает; абстрактный — отбрасывается,
      сборка проходит; конкретный класс — падает на самом `builder`; без part-директивы —
      `[WARNING]` и `wrote 0 outputs`; без `extends Module` — part пишется и не компилируется.
- [x] 1.2 Проверить, что `unit.declaredFragment?.source.shortName` доступен в `analyzer` 12.1.0 и 14.3.0
      Итог: `CompilationUnit.declaredFragment` → `LibraryFragment.source` есть в обоих.

## 2. Новые правила

- [x] 2.1 `module_requires_part_directive` (`error`) + quick fix `AddModulePartDirectiveFix`
- [x] 2.2 `module_must_extend_module` (`error`, без quick fix), проверка по `allSupertypes`
- [x] 2.3 Регистрация в `lib/main.dart` (`registerWarningRule` + `registerFixForRule`) и экспорт из `lib/cherrypick_lint.dart`
- [x] 2.4 Тесты: 4 кейса на part-директиву (есть/нет/чужая/не модуль), 5 на наследование (прямое/косвенное/нет/чужой класс/не модуль)

## 3. Правки существующих правил

- [x] 3.1 `module_method_missing_binding`: убрать пропуск приватных методов и операторов, оставить только геттеры/сеттеры
- [x] 3.2 Тесты: приватный без аннотации (диагностика), приватный с `@provide` (чисто), `static` без аннотации (диагностика), геттер/сеттер (чисто)
- [x] 3.3 `module_must_be_abstract`: переписать сообщение, correctionMessage и doc-комментарий под реальную причину; severity `error` оставить

## 4. Документация и релиз

- [x] 4.1 `README.md`: таблица annotation-rules + пояснения по четырём пунктам
- [x] 4.2 `CHANGELOG.md`: запись 1.1.0, включая предупреждение о новых диагностиках
- [x] 4.3 `pubspec.yaml`: версия 1.1.0
- [x] 4.4 Шесть руководств (`doc/lint_{en,ru}.md`, `site/` en+ru, `website/` en+ru): секции новых правил, уточнённые формулировки, `extends Module` в примерах, констрейнт `^1.1.0`
- [x] 4.5 Проверка: `dart test` в `cherrypick_lint`, `melos run analyze`, `melos run format`, сборка обеих документационных площадок, `dart pub publish --dry-run`
