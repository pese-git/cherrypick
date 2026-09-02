## Структура пакета

```
cherrypick_lint/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── cherrypick_lint.dart          # экспорт PluginBase
│   └── src/
│       ├── rules/
│       │   ├── avoid_unawaited_close_scope.dart
│       │   ├── avoid_unawaited_close_sub_scope.dart
│       │   ├── avoid_unawaited_scope_dispose.dart
│       │   ├── avoid_extends_silent_observer.dart
│       │   ├── avoid_experimental_scope_api.dart
│       │   ├── module_must_be_abstract.dart
│       │   ├── module_method_missing_binding.dart
│       │   ├── inject_field_must_be_late_final.dart
│       │   ├── named_value_must_not_be_empty.dart
│       │   └── params_requires_provide.dart
│       └── fixes/
│           ├── add_await_fix.dart
│           ├── make_class_abstract_fix.dart
│           └── add_late_final_fix.dart
└── test/
    ├── await_rules_test.dart
    ├── annotation_rules_test.dart
    └── runtime_trap_rules_test.dart
```

## Зависимости

```yaml
# pubspec.yaml (cherrypick_lint)
dependencies:
  analyzer: ^9.0.0
  custom_lint_builder: ^0.7.0

dev_dependencies:
  custom_lint: ^0.7.0
  cherrypick: ^4.0.0-dev.4
  cherrypick_annotations: ^4.0.0-dev.0
  test: ^1.25.8
```

## Подключение у пользователя

```yaml
# pubspec.yaml пользовательского проекта
dev_dependencies:
  custom_lint: ^0.7.0
  cherrypick_lint: ^1.0.0
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
| `avoid_unawaited_close_sub_scope` | `scope.closeSubScope(...)` без `await` | Добавить `await` |
| `avoid_unawaited_close_scope` | `CherryPick.closeScope(...)` без `await` | Добавить `await` |
| `avoid_unawaited_scope_dispose` | `scope.dispose()` где приёмник имеет тип `Scope` — без `await` | Добавить `await` |

### Группа 2 — аннотационные правила (severity: error)

| Код | Триггер | Quick fix |
|-----|---------|-----------|
| `module_must_be_abstract` | `@module` на не-`abstract` классе | Сделать класс `abstract` |
| `module_method_missing_binding` | публичный метод в `@module`-классе без `@provide` / `@instance` | — |
| `inject_field_must_be_late_final` | `@inject`-поле без `late final` | Добавить `late final` |
| `named_value_must_not_be_empty` | `@named('')` или `@named("")` | — |
| `params_requires_provide` | `@params` на методе без `@provide` | — |

### Группа 3 — рантайм-ловушки (severity: warning)

| Код | Триггер | Quick fix |
|-----|---------|-----------|
| `avoid_extends_silent_observer` | `extends SilentCherryPickObserver` | Заменить на `implements CherryPickObserver` |
| `avoid_experimental_scope_api` | вызов `CherryPick.openScope` / `CherryPick.closeScope` | Предложить `openSubScope` / `closeSubScope` |

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

Используется `testLint()` / `testFix()` из `custom_lint`:

```dart
// await_rules_test.dart
testLint(
  rule: AvoidUnawaitedCloseSubScope(),
  code: r'''
    import 'package:cherrypick/cherrypick.dart';
    void bad(Scope s) {
      s.closeSubScope('x');        // expect: lint
    }
    void good(Scope s) async {
      await s.closeSubScope('x'); // no lint
    }
  ''',
);
```

Для каждого правила — минимум два кейса: нарушение (lint ожидается) и корректный код (lint не ожидается). Для правил с quick fix — дополнительный `testFix()` с ожидаемым результатом после применения.
