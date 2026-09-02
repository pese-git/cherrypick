## 1. Подготовка пакета

- [ ] 1.1 Создать директорию `cherrypick_lint/` в корне монорепо
- [ ] 1.2 Написать `pubspec.yaml` (зависимости: `analyzer ^9.0.0`, `custom_lint_builder ^0.7.0`)
- [ ] 1.3 Добавить `analysis_options.yaml`
- [ ] 1.4 Зарегистрировать пакет в `melos.yaml`
- [ ] 1.5 Создать точку входа `lib/cherrypick_lint.dart` с `createPlugin()`

## 2. await-правила

- [ ] 2.1 Реализовать `avoid_unawaited_close_sub_scope` + quick fix (add await)
- [ ] 2.2 Реализовать `avoid_unawaited_close_scope` + quick fix (add await)
- [ ] 2.3 Реализовать `avoid_unawaited_scope_dispose` + quick fix (add await)
- [ ] 2.4 Написать тесты: `test/await_rules_test.dart` (нарушение + корректный + unawaited())

## 3. Аннотационные правила

- [ ] 3.1 Реализовать `module_must_be_abstract` + quick fix (make abstract)
- [ ] 3.2 Реализовать `module_method_missing_binding`
- [ ] 3.3 Реализовать `inject_field_must_be_late_final` + quick fix (add late final)
- [ ] 3.4 Реализовать `named_value_must_not_be_empty`
- [ ] 3.5 Реализовать `params_requires_provide`
- [ ] 3.6 Написать тесты: `test/annotation_rules_test.dart`

## 4. Рантайм-ловушки

- [ ] 4.1 Реализовать `avoid_extends_silent_observer` + quick fix (replace with implements)
- [ ] 4.2 Реализовать `avoid_experimental_scope_api` (severity: info)
- [ ] 4.3 Написать тесты: `test/runtime_trap_rules_test.dart`

## 5. Документация и публикация

- [ ] 5.1 Написать `README.md`: установка, список правил, примеры нарушений
- [ ] 5.2 Написать `CHANGELOG.md`
- [ ] 5.3 Проверить совместимость с текущей версией `custom_lint` перед публикацией
- [ ] 5.4 Добавить пакет в `melos.yaml` для `melos publish`
