## 3.0.0-dev.13

 - **FIX**: fix examples.
 - **DOCS**: update contributors list with GitHub links and add new contributor.
 - **DOCS**(binding,docs): clarify `.singleton()` with `.toInstance()` behavior in docs and API.
 - **DOCS**(binding,docs): explain .singleton() + parametric provider behavior.
 - **DOCS**(binding): clarify  registration limitation in API doc.
 - **DOCS**(di): clarify 'toInstance' binding limitations in builder.

## 3.0.0-dev.12

 - **FIX**(scope): prevent concurrent modification in dispose().
 - **FIX**(binding): fix unterminated string literal and syntax issues in binding.dart.

## 3.0.0-dev.11

 - **FIX**(scope): prevent concurrent modification in dispose().
 - **FIX**(binding): fix unterminated string literal and syntax issues in binding.dart.

## 3.0.0-dev.10

 - **DOCS**(pub): update homepage and documentation URLs in pubspec.yaml to new official site.

## 3.0.0-dev.9

 - **DOCS**(readme): add talker_cherrypick_logger to Additional Modules section.
 - **DOCS**(api): improve all DI core code documentation with English dartdoc and examples.

## 3.0.0-dev.8

 - **REFACTOR**(tests): replace MockLogger with MockObserver in scope tests to align with updated observer API.
 - **FIX**(doc): remove hide symbol.
 - **FEAT**(core): add full DI lifecycle observability via onInstanceDisposed.
 - **DOCS**(logging): update Logging section in README with modern Observer usage and Talker integration examples.
 - **DOCS**(observer): improve documentation, translate all comments to English, add usage examples.
 - **DOCS**(README): add section with overview table for additional modules.
 - **DOCS**(README): refactor structure and improve clarity of advanced features.
 - **DOCS**(README): add 'Hierarchical Subscopes' section and update structure for advanced features clarity.

## 3.0.0-dev.7

> Note: This release has breaking changes.

 - **FIX**(comment): fix warnings.
 - **FIX**(license): correct urls.
 - **FEAT**: add Disposable interface source and usage example.
 - **DOCS**(readme): add comprehensive section on annotations and DI code generation.
 - **DOCS**(readme): add detailed section and examples for automatic Disposable resource cleanup\n\n- Added a dedicated section with English description and code samples on using Disposable for automatic resource management.\n- Updated Features to include automatic resource cleanup for Disposable dependencies.\n\nHelps developers understand and implement robust DI resource management practices.
 - **DOCS**(faq): add best practice FAQ about using await with scope disposal.
 - **DOCS**(faq): add best practice FAQ about using await with scope disposal.
 - **BREAKING** **REFACTOR**(core): make closeRootScope async and await dispose.
 - **BREAKING** **DOCS**(disposable): add detailed English documentation and usage examples for Disposable interface; chore: update binding_resolver and add explanatory comment in scope_test for deprecated usage.\n\n- Expanded Disposable interface docs, added sync & async example classes, and CherryPick integration sample.\n- Clarified how to implement and use Disposable in DI context.\n- Updated binding_resolver for internal improvements.\n- Added ignore for deprecated member use in scope_test for clarity and future upgrades.\n\nBREAKING CHANGE: Documentation style enhancement and clearer API usage for Disposable implementations.

## 3.0.0-dev.6

> Note: This release has breaking changes.

 - **FIX**: improve global cycle detector logic.
 - **DOCS**(readme): add comprehensive DI state and action logging to features.
 - **DOCS**(helper): add complete DartDoc with real usage examples for CherryPick class.
 - **DOCS**(log_format): add detailed English documentation for formatLogMessage function.
 - **BREAKING** **FEAT**(core): refactor root scope API, improve logger injection, helpers, and tests.
 - **BREAKING** **FEAT**(logger): add extensible logging API, usage examples, and bilingual documentation.

## 3.0.0-dev.5

 - **REFACTOR**(scope): simplify _findBindingResolver<T> with one-liner and optional chaining.
 - **PERF**(scope): speed up dependency lookup with Map-based binding resolver index.
 - **DOCS**(perf): clarify Map-based resolver optimization applies since v3.0.0 in all docs.
 - **DOCS**: update EN/RU quick start and tutorial with Fast Map-based lookup section; clarify performance benefit in README.

## 3.0.0-dev.4

 - **REFACTOR**(scope): simplify _findBindingResolver<T> with one-liner and optional chaining.
 - **PERF**(scope): speed up dependency lookup with Map-based binding resolver index.
 - **DOCS**(perf): clarify Map-based resolver optimization applies since v3.0.0 in all docs.
 - **DOCS**: update EN/RU quick start and tutorial with Fast Map-based lookup section; clarify performance benefit in README.

## 3.0.0-dev.3

 - **REFACTOR**(scope): simplify _findBindingResolver<T> with one-liner and optional chaining.
 - **PERF**(scope): speed up dependency lookup with Map-based binding resolver index.
 - **DOCS**(perf): clarify Map-based resolver optimization applies since v3.0.0 in all docs.
 - **DOCS**: update EN/RU quick start and tutorial with Fast Map-based lookup section; clarify performance benefit in README.

## 3.0.0-dev.2

> Note: This release has breaking changes.

 - **FEAT**(binding): add deprecated proxy async methods for backward compatibility and highlight transition to modern API.
 - **DOCS**: add quick guide for circular dependency detection to README.
 - **DOCS**: add quick guide for circular dependency detection to README.
 - **BREAKING** **FEAT**: implement comprehensive circular dependency detection system.
 - **BREAKING** **FEAT**: implement comprehensive circular dependency detection system.

## 3.0.0-dev.1

 - **DOCS**: add quick guide for circular dependency detection to README.

## 3.0.0-dev.0

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: implement comprehensive circular dependency detection system.

## 2.2.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 2.2.0-dev.1

 - **FIX**: fix warnings.

## 2.2.0-dev.0

 - **FEAT**: Add async dependency resolution and enhance example.
 - **FEAT**: implement toInstanceAync binding.

## 2.1.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 2.1.0-dev.1

 - **FIX**: fix warnings.
 - **FIX**: fix warnings.
 - **FIX**: support passing params when resolving dependency recursively in parent scope.
 - **FEAT**: Add async dependency resolution and enhance example.
 - **FEAT**: Add async dependency resolution and enhance example.

## 2.0.2
- **FIX**: support passing params when resolving dependency recursively in parent scope.

## 2.1.0-dev.0

 - **FEAT**: Add async dependency resolution and enhance example.

## 2.0.1
- **FIX**: fix warning.

## 2.0.0
- **FEAT**: support for Dart 3.0.

## 1.1.0
- **FEAT**: verified Dart 3.0 support.

## 1.0.4
- **FIX**: Fixed exception "ConcurrentModificationError".

## 1.0.3
- **FEAT**: Added provider with params.

## 1.0.2
- **DOCS**: Updated docs and fixed syntax error.

## 1.0.1
- **FIX**: Fixed syntax error.

## 1.0.0
- **REFACTOR**: Refactored code and added experimental API.

## 0.1.2+1
- **FIX**: Fixed initialization error.

## 0.1.2
- **FIX**: Fixed warnings in code.

## 0.1.1+2
- **MAINT**: Updated libraries and fixed warnings.

## 0.1.1+1
- **MAINT**: Updated pubspec and readme.md.

## 0.1.1
- **MAINT**: Updated pubspec.

## 0.1.0
- **INIT**: Initial release.