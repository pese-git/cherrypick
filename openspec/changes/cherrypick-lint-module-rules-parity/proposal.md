## Why

Правила `@module` в `cherrypick_lint` не совпадают с тем, что на самом деле требует `cherrypick_generator`. Проверено прогоном `moduleBuilder` через `build_test` (по одному кейсу на каждое утверждение):

- **Обязательная part-директива не проверяется.** `moduleBuilder` — это `PartBuilder([ModuleGenerator()], '.module.cherrypick.g.dart')`, поэтому без `part '<файл>.module.cherrypick.g.dart';` сборка завершается **успешно**, не создав ничего: `[WARNING] ... must be included as a part directive in the input library` и `wrote 0 outputs`. Самый тихий из всех отказов — и линта на него нет.
- **Обязательное наследование `Module` не проверяется.** Генератор пишет `final class $Foo extends Foo` с `@override void builder(Scope currentScope)` и вызовами `bind<T>()` внутри — оба члена объявлены только в `Module`. Прогон на `@module abstract class TestModule {}` без наследования подтвердил: генератор молча пишет part, который не компилируется.
- **`module_method_missing_binding` пропускает приватные методы, а генератор — нет.** `GeneratedClass.fromClassElement` фильтрует `ClassElement.methods` только по `!isAbstract`, без проверки видимости, и каждый метод уходит в `AnnotationValidator.validateMethodAnnotations`. Прогон с `String _helper() => "y";` даёт `[SEVERE] Method must be marked with either @instance or @provide annotation` — то есть линт считает чистым код, на котором кодогенерация падает. То же с `static`-методами.
- **`module_must_be_abstract` мотивирован неверно.** Правило (severity `error`) утверждает «generated code may fail to compile»; на самом деле генератор `abstract` не проверяет вовсе и с конкретным классом работает. Причина, по которой конкретный `@module`-класс всё равно нерабочий, другая: `Module.builder` абстрактный, поэтому без переопределения класс отвергает сам Dart, а с переопределением генератор падает на `builder` как на публичном методе без `@provide`/`@instance` (проверено прогоном).

## What Changes

- **Новое правило** `module_requires_part_directive` (severity `error`, quick fix «Add the generated part directive»): `@module`-класс в библиотеке, не объявляющей `part '<файл>.module.cherrypick.g.dart';`.
- **Новое правило** `module_must_extend_module` (severity `error`, без quick fix): `@module`-класс, у которого в цепочке супертипов нет `Module` из `package:cherrypick`. Промежуточный базовый класс допустим.
- `module_method_missing_binding`: убрать пропуск приватных методов и операторов. Исключение остаётся только для геттеров и сеттеров — они не входят в `ClassElement.methods` и генератором не валидируются. Правило начинает репортить на коде, который раньше считался чистым.
- `module_must_be_abstract`: severity `error` сохраняется, переписываются сообщение, correctionMessage-мотивировка и doc-комментарий — под реальную причину (тупиковая вилка `Module.builder`), без ложного «generated code may fail to compile».
- Документация: `README.md`, `CHANGELOG.md` (релиз 1.1.0), и шесть руководств по линту (`doc/lint_{en,ru}.md`, `site/` en+ru, `website/` en+ru) — новые правила, уточнённые формулировки, `extends Module` в примерах `@module`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `lint-rules`: добавляются требования `module_requires_part_directive` и `module_must_extend_module`; меняются требования `module_method_missing_binding` (видимость и `static` больше не освобождают от аннотации) и `module_must_be_abstract` (мотивировка; severity и quick fix прежние).

## Impact

- `cherrypick_lint/lib/src/rules/`: два новых файла правил, правки в `module_method_missing_binding.dart` и `module_must_be_abstract.dart`.
- `cherrypick_lint/lib/src/fixes/add_module_part_directive_fix.dart`: новый quick fix.
- `cherrypick_lint/lib/main.dart`, `lib/cherrypick_lint.dart`: регистрация и экспорт.
- `cherrypick_lint/test/rules/`: два новых теста, расширение `module_method_missing_binding_test.dart` (приватный, `static`, геттер/сеттер); один существующий кейс меняет ожидание с «чисто» на диагностику.
- Для пользователей пакета — не breaking по способу подключения, но `module_method_missing_binding` может дать новые `error`-диагностики на существующем коде с приватными хелперами в `@module`-классах. Минорный релиз 1.1.0.
