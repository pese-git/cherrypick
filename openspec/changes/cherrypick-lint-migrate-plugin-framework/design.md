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
- **Целевые версии — `analysis_server_plugin` 0.3.14 + `analyzer` 12.1.0; запиненный SDK остаётся Dart 3.10.0 (Flutter 3.38.1).** `analyzer` ≥13.1.0 требует SDK `^3.11.0`, а версии `analysis_server_plugin` пинуют `analyzer` точно, поэтому под Dart 3.10.0 `pub` разрешает максимум 0.3.14/`analyzer` 12.1.0 (проверено реальным `pub get` на обоих SDK: под Dart 3.11.5 разрешается 0.3.22/`analyzer` 14.3.0). Альтернатива — поднять `.fvmrc` до Flutter 3.41.7 — отклонена: `cherrypick_lint` 2.0.0 тогда потребовал бы у пользователей Dart ≥3.11, а совместимость с Flutter 3.38 важнее свежести API плагина. Цена решения: пишем против API на два мажора `analyzer` позади актуального, часть примеров из доков на `main` придётся переводить вручную.
- **Severity задаётся параметром `severity:` конструктора `LintCode`** — `DiagnosticSeverity.WARNING`/`ERROR`/`INFO` из `package:analyzer/error/error.dart`; `ErrorSeverity` переименован в `DiagnosticSeverity`. **Дефолт — `INFO`**, то есть ловушка ровно та же, что уже один раз аукнулась в `cherrypick-lint`: не задал явно — получил `info`. Каждое перенесённое правило задаёт `severity` явно.
- **Все 13 правил регистрируются через `registerWarningRule`.** Способ регистрации в этом API управляет только тем, включено ли правило по умолчанию, и никак не связан с severity: `registerWarningRule` + `LintCode(severity: DiagnosticSeverity.INFO)` — валидная комбинация для двух singleton-правил. `registerLintRule` сделал бы правило opt-in и молча отключил бы его существующим пользователям, что противоречит требованию delta-спеки о сохранении поведения.
- **API-соответствие (для реализации каждого правила):**

  | custom_lint (текущее) | analysis_server_plugin (целевое) |
  |---|---|
  | `class X extends DartLintRule` | `class X extends AnalysisRule` |
  | `static const _code = LintCode(name:, problemMessage:, correctionMessage:, errorSeverity:)` | `static const code = LintCode(name, problemMessage, correctionMessage:, severity:)` — позиционные `name`/`problemMessage`, severity через `severity: DiagnosticSeverity.X` (дефолт — `INFO`) |
  | `void run(CustomLintResolver, ErrorReporter, CustomLintContext)` + `context.registry.addXxx((node) {...})` | `void registerNodeProcessors(RuleVisitorRegistry, RuleContext)` создаёт `_Visitor` и регистрирует его через `registry.addXxx(this, visitor)` |
  | `reporter.atNode(node, _code)` | `class _Visitor extends SimpleAstVisitor<void>` с методами `visitXxx(node)`, репорт через `rule.reportAtNode(node)` |
  | `class Fix extends DartFix` + `run(resolver, reporter, context, analysisError, others)` | `class Fix extends ResolvedCorrectionProducer` + `FixKind` + `Future<void> compute(ChangeBuilder builder)` |
  | `builder.addReplacement(...)`/`addDeletion(...)` (через `ChangeReporter`) | `builder.addDartFileEdit((builder) { builder.addDeletion(...)/addReplacement(...); })` — тот же `analyzer_plugin`'овский `ChangeBuilder` под капотом, API почти не меняется |
  | `class _CherryPickLint extends PluginBase { getLintRules() => [...] }` | `class CherryPickLintPlugin extends Plugin { void register(PluginRegistry registry) { registry.registerWarningRule(X()); } }` (или `registerLintRule` для правил, требующих явного включения) |

## Risks / Trade-offs

- [Resolved] Допущение о том, что точный пин `analyzer` — артефакт workspace-резолвинга SDK-монорепо, а сторонние плагины берут диапазон, **не подтвердилось**: каждая опубликованная версия `analysis_server_plugin` пинует `analyzer` точной версией (0.3.13→`12.0.0`, 0.3.15→`13.0.0`, 0.3.19→`14.0.0`, 0.3.22→`14.3.0`). Пример из официального `writing_a_plugin.md` (`analysis_server_plugin: ^0.2.2` + `analyzer: ^8.0.0`) устарел и не разрешается ни с одной опубликованной 0.3.x. → Решение: целимся в конкретную пару версий, совместимую с запиненным SDK (см. Decisions), и сверяемся с версионно-совпадающими доками из `doc/` внутри самого пакета в pub-кэше, а не с `main` в `dart-lang/sdk`.

## Проверенный API (analysis_server_plugin 0.3.14 / analyzer 12.1.0)

Формы ниже сверены с доками, которые пакет везёт с собой (`doc/writing_rules.md`,
`writing_fixes.md`, `testing_rules.md` внутри `analysis_server_plugin-0.3.14` в
pub-кэше), и скомпилированы на этой паре версий.

Правило:

```dart
class MyRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'my_rule',                       // позиционный name
    'Problem message.',              // позиционный problemMessage
    correctionMessage: 'Try ...',
    severity: DiagnosticSeverity.WARNING,   // дефолт INFO — задавать всегда
  );

  MyRule() : super(name: 'my_rule', description: '...');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitMethodInvocation(MethodInvocation node) => rule.reportAtNode(node);
}
```

`LintCode` обязан быть `static const` (единственный инстанс на код) — иначе
analysis server не сматчит код и `// ignore:` у пользователя не сработает.
Визитор — только `SimpleAstVisitor`; каждому его `visitXxx` соответствует
`registry.addXxx(this, visitor)`.

Quick fix:

```dart
class MyFix extends ResolvedCorrectionProducer {
  static const _kind = FixKind('cherrypick.fix.x', DartFixKindPriority.standard, 'Add await');
  MyFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) { /* addInsertion/addDeletion/... */ });
  }
}
```

Точка входа и регистрация (`lib/main.dart`, top-level `plugin`):

```dart
final plugin = CherryPickLintPlugin();

class CherryPickLintPlugin extends Plugin {
  @override
  String get name => 'cherrypick_lint';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(MyRule());
    registry.registerFixForRule(MyRule.code, MyFix.new);   // фикс привязан к коду, передаётся конструктор
  }
}
```

Тесты (`analyzer_testing` 0.2.5 — версия, которая резолвится под Dart 3.10.0):
класс `extends AnalysisRuleTest`, в `setUp` присваивается `rule = MyRule()` **до**
`super.setUp()` (база сама регистрирует правило и включает его в
`analysis_options.yaml` тестового пакета), тела — `assertDiagnostics(src, [lint(offset, length)])`
и `assertNoDiagnostics(src)`, запуск через `test_reflective_loader`
(`defineReflectiveSuite`/`defineReflectiveTests`). Типы `cherrypick`/`cherrypick_annotations`
в тестах подставляются заглушками через `newPackage('cherrypick')..addFile(...)`
(тоже в `setUp` до `super.setUp()`), а не реальной зависимостью.

Проверено end-to-end на запиненном Dart 3.10.0 (скелетный плагин + пакет-потребитель
с `plugins: <name>: path: ...`):

- `dart analyze` показывает диагностику плагина (`warning - ... - no_await_probe`) и **не крашится** — то есть обходной путь для `melos run analyze` действительно снимается;
- `// ignore: <plugin_name>/<rule_name>` подавляет диагностику;
- `diagnostics: <rule_name>: false` в секции плагина отключает правило, зарегистрированное через `registerWarningRule`.

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

- ~~Как именно `analysis_server_plugin`'овский `LintCode`/`AnalysisRule` выставляет severity?~~ → **Параметром `severity:` в `LintCode`**, тип `DiagnosticSeverity`, дефолт `INFO` (см. Decisions). Проверено на `analyzer` 12.1.0: `lib/src/dart/error/lint_codes.dart`.
- ~~`registerWarningRule` vs `registerLintRule` для каждого из 13 правил~~ → **`registerWarningRule` для всех 13** (см. Decisions).
- Нужен ли `cherrypick_lint/example` как отдельный пакет-фикстура после перехода на `analyzer_testing`, или его стоит превратить в чисто демонстрационный пример подключения плагина (без тестовой роли)?
- Стоит ли использовать `MultiAnalysisRule`/`List<LintCode> get diagnosticCodes` для каких-либо из 13 правил (актуально, если при переносе захочется разделить один codegen-класс на несколько сообщений) — на сегодня ни одному правилу это не требуется, каждое репортит один код.
