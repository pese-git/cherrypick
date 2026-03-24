## Purpose
Карта трассировки требований OpenSpec к исходному коду и документации CherryPick.

## Evidence Matrix

### DI Runtime (`di-runtime`)
- Public API exports:
  - `cherrypick/lib/cherrypick.dart`
- Scope lifecycle, resolution, fallback, modules, disposables:
  - `cherrypick/lib/src/scope.dart`
  - `cherrypick/lib/src/helper.dart`
  - `cherrypick/lib/src/module.dart`
  - `cherrypick/lib/src/disposable.dart`
- Binding modes and resolver semantics:
  - `cherrypick/lib/src/binding.dart`
  - `cherrypick/lib/src/binding_resolver.dart`
- Cycle detection:
  - `cherrypick/lib/src/cycle_detector.dart`
  - `cherrypick/lib/src/global_cycle_detector.dart`
- Observer contract:
  - `cherrypick/lib/src/observer.dart`
- Behavioral tests:
  - `cherrypick/test/src/scope_test.dart`
  - `cherrypick/test/src/binding_test.dart`
  - `cherrypick/test/src/cross_scope_cycle_test.dart`
  - `cherrypick/test/src/global_cycle_detection_test.dart`

### Annotations & Codegen (`annotations-and-codegen`)
- Annotation surface:
  - `cherrypick_annotations/lib/cherrypick_annotations.dart`
  - `cherrypick_annotations/lib/src/*.dart`
- Module generator and bind generation:
  - `cherrypick_generator/lib/module_generator.dart`
  - `cherrypick_generator/lib/src/generated_class.dart`
  - `cherrypick_generator/lib/src/bind_spec.dart`
  - `cherrypick_generator/lib/src/bind_parameters_spec.dart`
- Injectable field generator:
  - `cherrypick_generator/lib/inject_generator.dart`
- Validation and errors:
  - `cherrypick_generator/lib/src/annotation_validator.dart`
  - `cherrypick_generator/lib/src/type_parser.dart`
  - `cherrypick_generator/lib/src/exceptions.dart`
- Generator tests:
  - `cherrypick_generator/test/module_generator_test.dart`
  - `cherrypick_generator/test/inject_generator_test.dart`

### Flutter Integration (`flutter-integration`)
- Provider API and widget semantics:
  - `cherrypick_flutter/lib/src/cherrypick_provider.dart`
  - `cherrypick_flutter/lib/cherrypick_flutter.dart`
- Documentation:
  - `cherrypick_flutter/README.md`

### Talker Logging Adapter (`talker-logging-adapter`)
- Adapter implementation and export:
  - `talker_cherrypick_logger/lib/src/talker_cherrypick_observer.dart`
  - `talker_cherrypick_logger/lib/talker_cherrypick_logger.dart`
- Adapter tests:
  - `talker_cherrypick_logger/test/talker_cherrypick_logger_test.dart`
- Documentation:
  - `talker_cherrypick_logger/README.md`
