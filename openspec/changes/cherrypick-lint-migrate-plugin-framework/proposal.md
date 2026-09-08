## Why

`cherrypick_lint` построен на `custom_lint`/`custom_lint_builder` — эта библиотека больше не разрабатывается: её README прямо предупреждает `[!WARNING] This package is no longer under active development`, автор ([rrousselGit](https://github.com/rrousselGit)) [пишет в issue #379](https://github.com/invertase/dart_custom_lint/issues/379), что у него больше нет прав на публикацию, и советует переходить на официальное решение — [`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin) (пакет из репозитория Dart SDK, `publisher: tools.dart.dev`). Это объясняет и уже известную проблему: `custom_lint_builder` 0.8.1 интермиттентно крашит analysis server под Dart 3.10.0 (Flutter 3.38.1) — похоже, именно потому что SDK этой версии перешёл на новую архитектуру плагинов, на которой построен `analysis_server_plugin`, и старый мост `analyzer_plugin`, на котором держится `custom_lint`, для него не приоритет.

`analysis_server_plugin` устраняет и сам источник этой проблемы: правила интегрируются прямо в `dart analyze`/`flutter analyze` и в IDE, без отдельного процесса `dart run custom_lint` — то есть отпадает нужда в обходном пути, которым сейчас исключён `cherrypick_lint` из `melos run analyze`.

## What Changes

- Переписать все 13 правил и 5 quick fix'ов `cherrypick_lint` на API `analysis_server_plugin`: `AnalysisRule`/`SimpleAstVisitor` вместо `DartLintRule`/`context.registry.addXxx`, `ResolvedCorrectionProducer`/`FixKind` вместо `DartFix`/`ChangeReporter`, `Plugin`/`PluginRegistry.registerWarningRule(...)` вместо `PluginBase.getLintRules()`.
- **BREAKING** для пользователей пакета: сменить точку входа плагина (`lib/main.dart` с top-level `plugin`-переменной вместо `lib/cherrypick_lint.dart` с `createPlugin()`), и способ подключения — плагин объявляется в новом top-level разделе `plugins:` файла `analysis_options.yaml`, а не под `analyzer: plugins:` вместе с зависимостью `custom_lint`. Плагин больше не обязателен как `dev_dependency` пользовательского проекта — analysis server резолвит его сам.
- Переписать тесты на `package:analyzer_testing` (`AnalysisRuleTest`, `assertDiagnostics`/`assertNoDiagnostics` с inline-исходниками) вместо `// expect_lint: <code>`-фикстур, гоняемых через `dart run custom_lint` в отдельном процессе.
- Убрать обходной путь вокруг краша `custom_lint_builder`: `cherrypick_lint`/`cherrypick_lint_example` возвращаются в обычный `melos run analyze`, шаг `lint:custom_lint` в CI и `melos.yaml` удаляется.
- Обновить всю документацию, зависящую от текущего механизма установки: `README.md`, `doc/lint_{en,ru}.md`, `linting.md` на обеих площадках (`site/`, `website/`, en+ru) — новый способ подключения плагина, отсутствие шага `dart run custom_lint`.

## Capabilities

### New Capabilities

### Modified Capabilities

- `lint-rules`: требование «Структура и регистрация плагина» меняется — `Plugin`/`PluginRegistry` вместо `PluginBase`/`getLintRules()`, установка через top-level `plugins:` в `analysis_options.yaml` вместо `dev_dependency` + `analyzer.plugins`, включение/отключение правил через `plugins: cherrypick_lint: diagnostics:` вместо `custom_lint: rules:`. Что именно флагует каждое из 13 правил, с каким severity и quick fix'ом — не меняется (см. `specs/lint-rules/spec.md` в `openspec/changes/cherrypick-lint`).

## Impact

- `cherrypick_lint/pubspec.yaml`: убрать `custom_lint`/`custom_lint_builder`, добавить `analysis_server_plugin` + актуальный `analyzer`.
- `cherrypick_lint/lib/cherrypick_lint.dart` → `cherrypick_lint/lib/main.dart`; все файлы в `lib/src/rules/` и `lib/src/fixes/` переписываются на новый API.
- `cherrypick_lint/test/`: новый набор unit-тестов через `analyzer_testing`, `test/expect_lint_test.dart` и фикстуры в `example/lib/*_example.dart` — на удаление (если не понадобятся для примера использования).
- `melos.yaml`, `.github/workflows/pipeline.yml`: убрать `lint:custom_lint`, вернуть `cherrypick_lint`/`cherrypick_lint_example` в обычный `analyze`.
- Документация по установке во всех местах, где она сейчас упоминает `custom_lint`/`analyzer: plugins:` (`README.md`, `doc/lint_{en,ru}.md`, `site/`, `website/`).
- Для пользователей пакета — breaking change способа подключения (см. выше); требует отдельного мажорного релиза `cherrypick_lint`.
