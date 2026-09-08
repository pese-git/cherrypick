## 1. Разведка и скелет

- [x] 1.1 Проверить актуальную версию `analysis_server_plugin` и её реальный (а не SDK-workspace) диапазон `analyzer` на момент реализации — обновить design.md, если рекомендация изменилась
      Итог: все версии пинуют `analyzer` точно; под запиненным Dart 3.10.0 максимум —
      0.3.14/`analyzer` 12.1.0 (под Dart 3.11.5 было бы 0.3.22/14.3.0). Решено остаться
      на Dart 3.10.0, см. Decisions в design.md.
- [x] 1.2 Поднять минимальный скелет плагина (`lib/main.dart`, `Plugin`, один самый простой перенесённый rule — например `avoid_unawaited_scope_dispose`) и проверить в реальном IDE + `dart analyze` на Dart 3.10.0 (Flutter 3.38.1), что краш `custom_lint_builder` не воспроизводится
      Итог: `dart analyze` на Dart 3.10.0 показывает диагностику плагина и не крашится —
      проверено и на отдельном пакете-потребителе, и на `example/`, где правило сработало
      ровно там, где старые фикстуры ждали `// expect_lint: avoid_unawaited_scope_dispose`.
      Проверку в IDE нужно сделать глазами (перезапустив Dart Analysis Server) — из CLI
      она недоступна.
- [x] 1.3 Определить, как выставляется severity, эквивалентная нынешнему `errorSeverity: ErrorSeverity.WARNING/ERROR`, в `LintCode`/`AnalysisRule` этой версии `analysis_server_plugin`
      Итог: параметр `severity:` конструктора `LintCode`, тип `DiagnosticSeverity`,
      дефолт `INFO` — задавать явно в каждом правиле.
- [x] 1.4 Решить `registerWarningRule` vs `registerLintRule` для каждого из 13 правил
      Итог: `registerWarningRule` для всех 13 — сохраняет текущее «включено по умолчанию»;
      severity живёт в `LintCode` и от способа регистрации не зависит.

## 2. await-правила

- [x] 2.1 Перенести `avoid_unawaited_close_sub_scope` (+ quick fix) на `AnalysisRule`/`ResolvedCorrectionProducer`
- [x] 2.2 Перенести `avoid_unawaited_close_scope` (+ quick fix)
- [x] 2.3 Перенести `avoid_unawaited_scope_dispose` (+ quick fix) — сделано в 1.2
- [x] 2.4 Тесты через `analyzer_testing` (`AnalysisRuleTest`, `assertDiagnostics`/`assertNoDiagnostics`) на все сценарии, уже покрытые в `specs/lint-rules/spec.md` (await/return/store-then-await/unawaited)
      18 кейсов на три правила. Quick fix'ы тестами не покрываются: в
      `analyzer_testing` 0.2.5 нет API для проверки фиксов, а `dart fix` фиксы
      плагинов не применяет (`Nothing to fix!`) — проверка только глазами в IDE,
      как и было с `custom_lint`.

## 3. Аннотационные правила

- [x] 3.1 Перенести `module_must_be_abstract` (+ quick fix)
- [x] 3.2 Перенести `module_method_missing_binding`
- [x] 3.3 Перенести `inject_field_must_be_late_final` (+ quick fix)
- [x] 3.4 Перенести `named_value_must_not_be_empty`
- [x] 3.5 Перенести `params_requires_provide`
- [x] 3.6 Тесты через `analyzer_testing` на все сценарии

## 4. Рантайм-ловушки

- [x] 4.1 Перенести `avoid_extends_silent_observer` (+ quick fix)
- [x] 4.2 Перенести `avoid_redundant_singleton_on_instance` (+ quick fix)
- [x] 4.3 Перенести `avoid_singleton_on_provide_with_params`
- [x] 4.4 Перенести `avoid_resolve_in_to_instance`
- [x] 4.5 Перенести `avoid_precomputed_value_in_provide`
- [x] 4.6 Тесты через `analyzer_testing` на все сценарии
      Всего 55 кейсов на 13 правил. Паритет с прежней реализацией проверен на
      `example/`: все 17 маркеров `// expect_lint` воспроизводятся, лишних
      диагностик нет (18-я — второе срабатывание того же правила на строке с
      двумя вызовами, которую `expect_lint` помечал однократно).

## 5. Инфраструктура и CI

- [x] 5.1 Обновить `cherrypick_lint/pubspec.yaml`: убрать `custom_lint`/`custom_lint_builder`, добавить `analysis_server_plugin` + актуальный `analyzer`
      `analysis_server_plugin` 0.3.22, `analyzer` 14.3.0, `analyzer_plugin` 0.14.16,
      `environment: sdk: ">=3.11.0 <4.0.0"`. Пин `.fvmrc` поднят до Flutter 3.41.7
      (Dart 3.11.5) — иначе актуальные версии не резолвятся, см. Decisions в design.md.
- [x] 5.2 Убрать `lib/cherrypick_lint.dart` как entrypoint (или оставить как реэкспорт для тестов — решить при реализации), добавить `lib/main.dart`
      Решено оставить `lib/cherrypick_lint.dart` как публичный реэкспорт правил и
      фиксов (не точка входа) — точкой входа стал `lib/main.dart` с top-level
      `plugin`.
- [x] 5.3 Удалить `test/expect_lint_test.dart` и обходной путь через `dart run custom_lint`
- [x] 5.4 Решить судьбу `cherrypick_lint/example` — тестовый харнесс или чисто демонстрационный пример
      Решено: чисто демонстрационный. Роль харнесса ушла в unit-тесты, а фикстуры с
      нарушениями мешали бы вернуть пакет в `melos run analyze` (задача 5.5) — теперь
      это одна корректная сборка DI, на которой `dart analyze` обязан молчать, плюс
      `analysis_options.yaml` как живой пример подключения.
- [x] 5.5 Вернуть `cherrypick_lint`/`cherrypick_lint_example` в обычный `melos run analyze`, убрать `lint:custom_lint` из `melos.yaml`
- [x] 5.6 Убрать шаг «Check cherrypick_lint rules» (`lint:custom_lint`) из `.github/workflows/pipeline.yml`

## 6. Документация и релиз

- [ ] 6.1 Обновить `cherrypick_lint/README.md`: способ установки (`plugins:` в `analysis_options.yaml`, не `dev_dependency`), раздел «Disabling a rule» (`plugins: cherrypick_lint: diagnostics:` вместо `custom_lint: rules:`), убрать раздел про краш `dart analyze`/обходной путь
- [ ] 6.2 Обновить `cherrypick_lint/CHANGELOG.md` — мажорный релиз, явный раздел "Migration from 0.x"
- [ ] 6.3 Обновить `doc/lint_{en,ru}.md` и `linting.md` на обеих площадках (`site/`, `website/`, en+ru) — новый способ подключения
- [ ] 6.4 Собрать обе документационные площадки (`site/`, `website/`) локально, убедиться, что ничего не сломано
- [ ] 6.5 Проверить совместимость с актуальной версией `analysis_server_plugin`/`analyzer` перед публикацией, зафиксировать в `CHANGELOG.md`
