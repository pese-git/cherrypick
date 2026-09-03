## 1. Подготовка пакета

- [x] 1.1 Создать директорию `cherrypick_lint/` в корне монорепо
- [x] 1.2 Написать `pubspec.yaml` (зависимости: `analyzer ^8.0.0`, `custom_lint_builder ^0.8.1` — актуальные версии на момент реализации; `custom_lint_builder ^0.7.0` требовал бы `analyzer ^7.0.0`, что конфликтует с `analyzer ^9.0.0` в `cherrypick_generator`)
- [x] 1.3 Добавить `analysis_options.yaml`
- [x] 1.4 Зарегистрировать пакет в `melos.yaml`
- [x] 1.5 Создать точку входа `lib/cherrypick_lint.dart` с `createPlugin()`

## 2. await-правила

- [x] 2.1 Реализовать `avoid_unawaited_close_sub_scope` + quick fix (add await)
- [x] 2.2 Реализовать `avoid_unawaited_close_scope` + quick fix (add await)
- [x] 2.3 Реализовать `avoid_unawaited_scope_dispose` + quick fix (add await)
- [x] 2.4 Написать тесты — реализовано как `example/lib/await_rules_example.dart`
      с `// expect_lint: <code>` на каждый сценарий (нарушение + корректный +
      `unawaited()`), проверяется через `dart run custom_lint`
      (`test/expect_lint_test.dart` оборачивает это в `dart test`).
      `custom_lint` 0.8.1 не предоставляет `testLint()`/`testFix()` — это
      предположение design.md не подтвердилось при реализации; официальный
      механизм тестирования — фикстуры с `expect_lint`.

## 3. Аннотационные правила

- [x] 3.1 Реализовать `module_must_be_abstract` + quick fix (make abstract)
- [x] 3.2 Реализовать `module_method_missing_binding`
- [x] 3.3 Реализовать `inject_field_must_be_late_final` + quick fix (add late final)
- [x] 3.4 Реализовать `named_value_must_not_be_empty`
- [x] 3.5 Реализовать `params_requires_provide`
- [x] 3.6 Написать тесты — `example/lib/annotation_rules_example.dart`, та же схема

## 4. Рантайм-ловушки

- [x] 4.1 Реализовать `avoid_extends_silent_observer` + quick fix (replace with implements)
- [x] 4.2 Реализовать `avoid_experimental_scope_api` (severity: info)
- [x] 4.3 Написать тесты — `example/lib/runtime_trap_rules_example.dart`, та же схема

## 5. Документация и публикация

- [x] 5.1 Написать `README.md`: установка, список правил, примеры нарушений
- [x] 5.2 Написать `CHANGELOG.md`
- [x] 5.3 Проверить совместимость с текущей версией `custom_lint` перед публикацией —
      подтверждено на `custom_lint`/`custom_lint_builder` 0.8.1 (последняя версия на
      pub.dev на момент реализации), `analyzer` 8.4.1
- [x] 5.4 Добавить пакет в `melos.yaml` для `melos publish`
