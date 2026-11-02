## MODIFIED Requirements

---

### Requirement: Структура и регистрация плагина

`cherrypick_lint` MUST реализовывать `Plugin` из `analysis_server_plugin` и регистрировать каждое правило через `register(PluginRegistry registry)` (`registerWarningRule` для правил, активных по умолчанию — `warning`/`error`, или `registerLintRule` для правил, требующих явного включения).

Триггеры, severity и quick fix каждого из 13 правил не меняются относительно `specs/lint-rules/spec.md` из `openspec/changes/cherrypick-lint` — меняется только фреймворк, на котором они реализованы и подключаются.

#### Scenario: Плагин подключается без build_runner и без dev_dependency
- **WHEN** пользователь добавляет `cherrypick_lint` в top-level секцию `plugins:` файла `analysis_options.yaml` (не под `analyzer:`, и не как `dev_dependency` в `pubspec.yaml`)
- **THEN** правила активируются в IDE и в `dart analyze`/`flutter analyze` без запуска `build_runner`

#### Scenario: Правило, активное по умолчанию (warning/error)
- **WHEN** правило зарегистрировано через `registerWarningRule(...)`
- **THEN** оно репортит диагностику сразу после подключения плагина, без дополнительной настройки

#### Scenario: Правило, требующее явного включения (lint)
- **WHEN** правило зарегистрировано через `registerLintRule(...)`
- **THEN** оно репортит диагностику только если явно включено в `analysis_options.yaml` под `plugins: cherrypick_lint: diagnostics: <rule_name>: true`

#### Scenario: Отключение правила, активного по умолчанию
- **WHEN** пользователь указывает `plugins: cherrypick_lint: diagnostics: <rule_name>: false`
- **THEN** правило не репортит диагностику, даже если зарегистрировано через `registerWarningRule(...)`

#### Scenario: Подавление диагностики построчно
- **WHEN** пользователь добавляет комментарий `// ignore: cherrypick_lint/<rule_name>` (или `// ignore_for_file: cherrypick_lint/<rule_name>`)
- **THEN** диагностика этого правила не репортится в отмеченной строке/файле
