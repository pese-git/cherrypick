## Context

CherryPick DI содержит ряд API-контрактов, нарушение которых не обнаруживается компилятором Dart и приводит к тихим ошибкам в рантайме: незакрытые ресурсы из-за пропущенного `await`, некорректные наблюдатели, экспериментальные методы в продакшн-коде. `cherrypick_generator` уже валидирует аннотации при codegen, но только при запуске `build_runner`. Нужен инструмент, который подсвечивает нарушения сразу в IDE.

## Goals / Non-Goals

**Goals:**
- Предоставить `custom_lint`-плагин `cherrypick_lint` с правилами для трёх классов нарушений: пропущенный `await`, неверное использование аннотаций, рантайм-ловушки.
- Каждое правило MUST предоставлять читаемое сообщение с указанием причины и способа исправления.
- Правила с тривиальным исправлением MUST предоставлять quick fix прямо в IDE.
- Плагин MUST работать без `build_runner` как самостоятельная `dev`-зависимость.
- Все правила MUST быть отключаемыми через `analysis_options.yaml`.

**Non-Goals:**
- Дублирование runtime-валидации (исключения, которые бросает `Scope` при установке модуля).
- Поддержка Dart < 3.9 и `custom_lint` < 0.7.
- Правила для кода внутри самого `cherrypick` (пакет нацелен на пользователей библиотеки).

## Decisions

- Реализовать как отдельный пакет `cherrypick_lint/` (Подход A: независимый плагин без общего слоя с генератором).
- Разбить правила на три группы: `await-rules`, `annotation-rules`, `runtime-trap-rules`.
- Каждое правило — отдельный класс `DartLintRule`; quick fix — отдельный класс `DartFix`.
- Тесты через `// expect_lint: <code>` фикстуры в `example/lib` (реальный механизм `custom_lint` — на момент реализации `testLint()`/`testFix()` в API не существует, см. раздел «Тестирование»).

**Альтернативы:**
- Общий слой `cherrypick_analyzer` для lint и generator: отклонено как преждевременный рефакторинг для первой версии.
- Правила внутри `cherrypick_generator`: отклонено — принудительно тянет `build_runner` к пользователям, которым нужен только lint.

## Risks / Trade-offs

- [Risk] AST-проверка по имени метода может давать ложные срабатывания на чужой `dispose()` или `closeSubScope()` → Mitigation: проверять тип приёмника через `DartType` перед репортом диагностики.
- [Risk] `custom_lint` активно развивается, API меняется между минорными версиями → Mitigation: зафиксировать `^0.8.1` (актуальная на момент реализации; `^0.7.0` тянет `analyzer ^7.0.0`, конфликтующий с `analyzer ^9.0.0` в `cherrypick_generator`), добавить пункт в `tasks.md` на проверку совместимости при обновлении.
- [Risk] Аннотационные правила дублируют `AnnotationValidator` в генераторе → Mitigation: осознанное дублирование; при значительном расхождении ввести `cherrypick_analyzer` как отдельный change-request.

## Migration Plan

- Пакет публикуется независимо; не меняет поведение `cherrypick`, `cherrypick_annotations`, `cherrypick_generator`.
- Пользователь добавляет две `dev`-зависимости и одну строку в `analysis_options.yaml`; существующий код не меняется.
- При желании отдельные правила отключаются через `custom_lint: rules:` секцию.

## Open Questions

_Все вопросы закрыты._

- ~~Следует ли `avoid_unawaited_scope_dispose` срабатывать на любой `Disposable.dispose()`?~~ → **Только `Scope.dispose()`**: пользовательские синхронные `Disposable` возвращают `void`, правило не должно на них срабатывать.

## Структура пакета

```
cherrypick_lint/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── cherrypick_lint.dart          # экспорт PluginBase
│   └── src/
│       ├── utils.dart                # общие AST/Element-хелперы
│       ├── rules/
│       │   ├── avoid_unawaited_close_scope.dart
│       │   ├── avoid_unawaited_close_sub_scope.dart
│       │   ├── avoid_unawaited_scope_dispose.dart
│       │   ├── avoid_extends_silent_observer.dart
│       │   ├── module_must_be_abstract.dart
│       │   ├── module_method_missing_binding.dart
│       │   ├── inject_field_must_be_late_final.dart
│       │   ├── named_value_must_not_be_empty.dart
│       │   └── params_requires_provide.dart
│       └── fixes/
│           ├── add_await_fix.dart                     # общий для 3 await-правил
│           ├── make_class_abstract_fix.dart
│           ├── add_late_final_fix.dart
│           └── replace_extends_with_implements_fix.dart
├── test/
│   └── expect_lint_test.dart         # запускает `dart run custom_lint` над example/
└── example/                          # отдельный пакет-фикстура (publish_to: none)
    ├── pubspec.yaml                  # cherrypick + cherrypick_annotations как обычные deps
    ├── analysis_options.yaml         # analyzer.plugins: [custom_lint]
    └── lib/
        ├── await_rules_example.dart
        ├── annotation_rules_example.dart
        └── runtime_trap_rules_example.dart
```

Четвёртый файл фикса (`replace_extends_with_implements_fix.dart`) не был учтён в исходном списке — понадобился для quick fix `avoid_extends_silent_observer`, которая явно требуется в `specs/lint-rules/spec.md`.

## Зависимости

```yaml
# pubspec.yaml (cherrypick_lint)
dependencies:
  analyzer: ^8.0.0
  custom_lint_builder: ^0.8.1

dev_dependencies:
  custom_lint: ^0.8.1
  lints: ^6.0.0
  test: ^1.25.8
```

`cherrypick`/`cherrypick_annotations` НЕ являются зависимостями самого плагина —
`TypeChecker.fromName(name, packageName: ...)` матчит по имени пакета без
физического импорта типа. Они нужны только фикстурам в `example/`, поэтому
объявлены в `example/pubspec.yaml`, а не в `cherrypick_lint/pubspec.yaml`.

`custom_lint_builder ^0.7.0` (как планировалось изначально) требует
`analyzer ^7.0.0`, что несовместимо с `analyzer ^9.0.0`, используемым в
`cherrypick_generator`, будь оба пакета частью единого workspace-резолвинга.
Поскольку `melos` в этом монорепо не использует Dart-нативные pub workspaces
(нет `workspace:` в корневом `pubspec.yaml`), прямого конфликта между
пакетами нет — но сам `cherrypick_lint` не может одновременно объявить
`analyzer: ^9.0.0` и зависеть от `custom_lint_builder`, если та фиксирует
более старый диапазон `analyzer`. `^8.0.0` — версия, которую `custom_lint_builder
0.8.1` (последняя опубликованная на момент реализации) объявляет как свою
собственную зависимость.

## Подключение у пользователя

```yaml
# pubspec.yaml пользовательского проекта
dev_dependencies:
  custom_lint: ^0.8.1
  cherrypick_lint: ^0.1.0
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

## Каталог правил

### Группа 1 — await-правила (severity: warning)

| Код | Триггер | Quick fix |
|-----|---------|-----------|
| `avoid_unawaited_close_sub_scope` | `scope.closeSubScope(...)` без `await` | Add await |
| `avoid_unawaited_close_scope` | `CherryPick.closeScope(...)` без `await` | Add await |
| `avoid_unawaited_scope_dispose` | `scope.dispose()` где приёмник имеет тип `Scope` — без `await` | Add await |

### Группа 2 — аннотационные правила (severity: error)

| Код | Триггер | Quick fix |
|-----|---------|-----------|
| `module_must_be_abstract` | `@module` на не-`abstract` классе | Make class abstract |
| `module_method_missing_binding` | публичный метод в `@module`-классе без `@provide` / `@instance` | — |
| `inject_field_must_be_late_final` | `@inject`-поле без `late final` | Add late final |
| `named_value_must_not_be_empty` | `@named('')` или `@named("")` | — |
| `params_requires_provide` | `@params` на методе без `@provide` | — |

### Группа 3 — рантайм-ловушки (severity: warning)

| Код | Триггер | Quick fix |
|-----|---------|-----------|
| `avoid_extends_silent_observer` | `extends SilentCherryPickObserver` | Replace with implements CherryPickObserver |

## Архитектура плагина

```
PluginBase (custom_lint_builder)
 └── CherryPickLintPlugin
      ├── getLintRules() → List<DartLintRule>
      └── getFixes()     → List<DartFix>

DartLintRule
 └── AvoidUnawaitedCloseSubScope          ← пример await-правила
      └── run(resolver, unit, errors)
           └── _MethodInvocationVisitor   ← обходит AST
                ├── проверяет имя метода  ('closeSubScope')
                ├── проверяет тип приёмника через DartType
                └── проверяет отсутствие AwaitExpression у parent
```

Каждое правило изолировано; ни одно правило не вызывает другое. Visitor проверяет тип приёмника перед репортом диагностики, чтобы исключить ложные срабатывания на одноимённые методы из других библиотек.

## Тестирование

`custom_lint` (0.8.1) не предоставляет `testLint()`/`testFix()` — эта функция
не существует в текущем публичном API пакета. Официальный механизм тестирования
(см. [README `custom_lint`](https://github.com/invertase/dart_custom_lint#testing-your-plugins)):
файлы-фикстуры с комментарием `// expect_lint: <code>` на строке перед
ожидаемым нарушением, проверяемые запуском `dart run custom_lint` над
директорией с фикстурами. Комментарий без соответствующего нарушения на
следующей строке — ошибка (`unfulfilled_expect_lint`); нарушение без
комментария — тоже ошибка (пролезает как обычная диагностика).

```dart
// example/lib/await_rules_example.dart
Future<void> violations() async {
  final root = CherryPick.openRootScope();
  final child = root.openSubScope('demo');

  // expect_lint: avoid_unawaited_close_sub_scope
  child.closeSubScope('grandchild');
}

Future<void> correct() async {
  final root = CherryPick.openRootScope();
  final child = root.openSubScope('demo2');

  await child.closeSubScope('grandchild');               // no lint
  unawaited(child.closeSubScope('grandchild2'));          // no lint
}
```

Для каждого правила — минимум два кейса в этих фикстурах: нарушение
(`expect_lint`) и корректный код (без комментария — отсутствие диагностики и
есть проверка). `test/expect_lint_test.dart` оборачивает `dart run custom_lint
example/` в `dart test`, чтобы это попадало в обычный прогон тестов и CI.

Quick fix проверяются вручную через `dart run custom_lint --fix` — команда
применяет все доступные фиксы к найденным нарушениям (на фикстурах с
`expect_lint` фиксов не видно, так как `expect_lint` подавляет диагностику;
для проверки фикса нужен отдельный файл без `expect_lint`). Встроенного
эквивалента `testFix()` в API нет — только сценарий из
[riverpod_lint](https://github.com/rrousselGit/riverpod/tree/master/packages/riverpod_lint_flutter_test/test/assists),
ручной вызов `package:analyzer` для симуляции правки; для первой версии
плагина это признано избыточным (см. Non-Goals).
