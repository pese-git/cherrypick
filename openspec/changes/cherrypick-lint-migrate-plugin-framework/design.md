## Context

`cherrypick_lint` (см. `openspec/changes/cherrypick-lint`) реализован на `custom_lint`/`custom_lint_builder` 0.8.1 — последней опубликованной версии; проект де-факто без сопровождения:

- README `dart_custom_lint`: `[!WARNING] This package is no longer under active development. ... The official analysis_server_plugin is now the recommended approach for building custom lints.`
- [Issue #379](https://github.com/invertase/dart_custom_lint/issues/379) («please depend on analyzer^9.0.0 or higher instead of ^8.4.0» — тот самый конфликт версий, что и у нас с `cherrypick_generator`): автор `rrousselGit` отвечает, что прав на публикацию у него больше нет, и прямо советует мигрировать на `analysis_server_plugin`.
- Репозиторий `invertase/dart_custom_lint` архивирован на GitHub.

Это совпадает по времени с уже известной проблемой сессии: `custom_lint_builder` 0.8.1 интермиттентно крашит `analyzer_plugin`-мост analysis server'а под Dart 3.10.0 (Flutter 3.38.1) — том самом SDK, с которого `analysis_server_plugin` официально стартует (`Analyzer plugins are supported starting in Dart 3.10 (Flutter 3.38)`, см. `using_plugins.md`). Похоже, SDK сменил приоритет на новую архитектуру плагинов, а старый мост, на котором держится `custom_lint`, для неё не в фокусе.

`analysis_server_plugin`: пакет `tools.dart.dev`, часть репозитория `dart-lang/sdk`, активно публикуется (0.3.22 на момент анализа, вышел через несколько дней после последнего релиза этой ветки). Ключевое отличие от `custom_lint` — правила подключаются analysis server'ом напрямую (правила выполняются в отдельном isolate самого analysis server'а), без отдельного CLI-процесса: диагностики видны и в `dart analyze`/`flutter analyze`, и в IDE одинаково.

## Goals / Non-Goals

**Goals:**

- Перенести все существующие 13 правил и 5 quick fix'ов `cherrypick_lint` на `analysis_server_plugin` без изменения того, что каждое правило флагует, с каким severity и с каким (или без) quick fix — поведение, зафиксированное в `specs/lint-rules/spec.md`, MUST остаться прежним.
- Убрать обходной путь вокруг краша `custom_lint_builder` (исключение из `melos run analyze`, отдельный шаг `lint:custom_lint` в CI) — правила снова должны быть видны через штатный `dart analyze`.
- Перейти на официальный, поддерживаемый Dart-командой тестовый API (`analyzer_testing`) вместо `// expect_lint:`-фикстур, гоняемых сабпроцессом.

**Non-Goals:**

- Добавление новых правил в рамках этой миграции — только перенос существующих 13.
- Сохранение обратной совместимости установки для существующих пользователей `cherrypick_lint` — способ подключения плагина меняется принципиально (см. Migration Plan), это осознанный breaking change отдельного мажорного релиза.
- Выравнивание версии `analyzer` с `cherrypick_generator` (`^9.0.0`) — `analysis_server_plugin` не требует какой-то одной жёстко зафиксированной версии `analyzer` от авторов плагинов (см. Risks), но точное совпадение версий двух пакетов не является целью этой миграции.

## Decisions

- **Полная миграция, а не постепенная/дуальная поддержка обоих фреймворков.** Поддерживать одновременно `custom_lint`- и `analysis_server_plugin`-версии каждого правила увеличило бы объём кода вдвое ради платформы, которая официально не развивается — альтернатив с приемлемой стоимостью нет.
- **Точка входа — `lib/main.dart` с top-level `plugin`-переменной**, как того требует `analysis_server_plugin` (см. `writing_a_plugin.md`), вместо текущего `lib/cherrypick_lint.dart` с фабрикой `createPlugin()`. Существующий `lib/cherrypick_lint.dart` можно оставить как реэкспорт правил/утилит для тестов, но точкой входа плагина становится `lib/main.dart`.
- **Тесты — `package:analyzer_testing`'s `AnalysisRuleTest` + `assertDiagnostics`/`assertNoDiagnostics`** с inline-исходниками вместо `// expect_lint:`-комментариев в `example/lib/*.dart`, гоняемых через `dart run custom_lint` в отдельном процессе. Это устраняет целый класс проблем этой сессии — блуждающие процессы `custom_lint_client.dart`, портящие фикстуры между запусками, необходимость `pkill` перед каждым дебагом.
  - `example/` пакет с фикстурами, вероятно, стоит оставить как демонстрационный пример подключения плагина конечным пользователем (не как тестовый харнесс) — решить при реализации.
- **API-соответствие (для реализации каждого правила):**

  | custom_lint (текущее) | analysis_server_plugin (целевое) |
  |---|---|
  | `class X extends DartLintRule` | `class X extends AnalysisRule` |
  | `static const _code = LintCode(name:, problemMessage:, correctionMessage:, errorSeverity:)` | `static const code = LintCode(name, problemMessage, correctionMessage:)` — своя структура severity (см. Open Questions) |
  | `void run(CustomLintResolver, ErrorReporter, CustomLintContext)` + `context.registry.addXxx((node) {...})` | `void registerNodeProcessors(RuleVisitorRegistry, RuleContext)` создаёт `_Visitor` и регистрирует его через `registry.addXxx(this, visitor)` |
  | `reporter.atNode(node, _code)` | `class _Visitor extends SimpleAstVisitor<void>` с методами `visitXxx(node)`, репорт через `rule.reportAtNode(node)` |
  | `class Fix extends DartFix` + `run(resolver, reporter, context, analysisError, others)` | `class Fix extends ResolvedCorrectionProducer` + `FixKind` + `Future<void> compute(ChangeBuilder builder)` |
  | `builder.addReplacement(...)`/`addDeletion(...)` (через `ChangeReporter`) | `builder.addDartFileEdit((builder) { builder.addDeletion(...)/addReplacement(...); })` — тот же `analyzer_plugin`'овский `ChangeBuilder` под капотом, API почти не меняется |
  | `class _CherryPickLint extends PluginBase { getLintRules() => [...] }` | `class CherryPickLintPlugin extends Plugin { void register(PluginRegistry registry) { registry.registerWarningRule(X()); } }` (или `registerLintRule` для правил, требующих явного включения) |

## Risks / Trade-offs

- [Risk] `analysis_server_plugin`, судя по внутреннему workspace-пубспеку самого `dart-lang/sdk`, использует точный пин `analyzer: 14.3.0` (не диапазон) — но это резолвинг самого SDK-монорепо (`resolution: workspace`), не требование к сторонним авторам плагинов. Официальный гайд `writing_a_plugin.md` явно показывает пример стороннего плагина с `analyzer: ^8.0.0`. → Mitigation: зафиксировать собственный, достаточно широкий диапазон `analyzer` в `cherrypick_lint/pubspec.yaml` при реализации, ориентируясь на актуальную рекомендацию `writing_a_plugin.md` на тот момент, а не на пин из SDK-репозитория.
- [Risk] Новый способ подключения (`plugins:` в `analysis_options.yaml`, без обязательной `dev_dependency`) — breaking change для существующих пользователей `cherrypick_lint` 0.1.0. → Mitigation: отдельный мажорный релиз (`2.0.0`), явный раздел "Migration from 0.x" в `README.md`/`CHANGELOG.md`.
- [Risk] `analysis_server_plugin` — молодой пакет (Dart 3.10+, вышел недавно); его API может ещё меняться между минорными версиями сильнее, чем у стабилизировавшегося `custom_lint`. → Mitigation: зафиксировать версию по актуальной на момент реализации, добавить в `tasks.md` пункт на проверку совместимости, как это уже сделано для `cherrypick-lint`.
- [Risk] Формат `LintCode`/severity в `analyzer_plugin`'овском API может отличаться от `custom_lint_builder`'овского настолько, что придётся пересмотреть, как выставлялся `errorSeverity` (см. недавний фикс в `cherrypick-lint` — 4 правила молча репортились как `info` из-за отсутствия явного `errorSeverity`). → Mitigation: явно перепроверить severity каждого перенесённого правила через реальный прогон `dart analyze`, а не полагаться на дефолты, как это уже один раз аукнулось.
- [Risk] `registerWarningRule` включает правило по умолчанию, `registerLintRule` — требует явного включения в `analysis_options.yaml` пользователя. Нужно решить, какое соответствие использовать для каждой из 13 правил (вероятно: `warning`/`error`-правила → `registerWarningRule`, `info`-правила без quick fix → возможно `registerLintRule`, требуя явного opt-in). → Mitigation: решить как отдельную задачу в `tasks.md`, свериться с уже задокументированной severity-таблицей в `cherrypick_lint/README.md`.

## Migration Plan

1. Поднять минимальный `analysis_server_plugin`-скелет (`lib/main.dart`, один самый простой перенесённый rule) и проверить его в реальном IDE/`dart analyze` на Dart 3.10.0 (Flutter 3.38.1) — подтвердить, что краш `custom_lint_builder` действительно не воспроизводится на новом фреймворке, прежде чем переносить остальные 12 правил.
2. Переносить правила группами, как они организованы сейчас (await-rules → annotation-rules → runtime-trap-rules), с тестами через `analyzer_testing` на каждую группу, аналогично `cherrypick-lint`'s tasks.md.
3. Перенести все 5 quick fix'ов.
4. Обновить `melos.yaml`/CI — вернуть `cherrypick_lint`/`cherrypick_lint_example` в `melos run analyze`, убрать `lint:custom_lint`.
5. Обновить документацию (`README.md`, `CHANGELOG.md`, `doc/lint_{en,ru}.md`, обе площадки `linting.md`) — новый способ подключения, отсутствие отдельного `dart run custom_lint`.
6. Публикация как мажорный релиз (`cherrypick_lint` 2.0.0) с явным разделом миграции в `CHANGELOG.md`.
7. Удалить старые `custom_lint`-зависимости и файлы (`lib/cherrypick_lint.dart` как entrypoint, `test/expect_lint_test.dart`, при необходимости — `// expect_lint:`-фикстуры, если `example/` не используется как демонстрация).

Отката на `custom_lint` после публикации 2.0.0 не предусмотрено — если миграция окажется преждевременной (например, `analysis_server_plugin` API изменится несовместимо), проще остаться на последней 1.x-версии, чем откатывать релиз.

## Open Questions

- Как именно `analysis_server_plugin`'овский `LintCode`/`AnalysisRule` выставляет severity, эквивалентную нынешнему `errorSeverity: ErrorSeverity.WARNING/ERROR` в `custom_lint`? Нужно свериться с актуальной версией `analyzer`/`analysis_server_plugin` при реализации — этот design.md перечисляет только базовую форму `LintCode(name, problemMessage, correctionMessage:)` из документации без явного severity-параметра.
- `registerWarningRule` vs `registerLintRule` для каждого из 13 правил — см. Risks выше.
- Нужен ли `cherrypick_lint/example` как отдельный пакет-фикстура после перехода на `analyzer_testing`, или его стоит превратить в чисто демонстрационный пример подключения плагина (без тестовой роли)?
- Стоит ли использовать `MultiAnalysisRule`/`List<LintCode> get diagnosticCodes` для каких-либо из 13 правил (актуально, если при переносе захочется разделить один codegen-класс на несколько сообщений) — на сегодня ни одному правилу это не требуется, каждое репортит один код.
