# cherrypick_annotations

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A lightweight set of Dart annotations designed for dependency injection (DI) frameworks and code generation, inspired by modern approaches like Dagger and Injectable. Works best in tandem with [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator).

---

## Features

- **@module** – Marks a class as a DI module for service/provider registration.
- **@singleton** – Declares that a method or class should be provided as a singleton.
- **@named** – Assigns a string name to a binding for keyed resolution.

These annotations are intended to streamline DI configuration and serve as markers for code generation tools.

---

## Getting Started

### 1. Add dependency

```yaml
dependencies:
  cherrypick_annotations: ^latest
```

Add as a `dev_dependency` for codegen:

```yaml
dev_dependencies:
  build_runner: ^latest
  cherrypick_generator:
```

### 2. Usage

Annotate your DI modules and providers:

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

@module()
abstract class AppModule extends Module {
  @singleton()
  Dio dio() => Dio();

  @named('baseUrl')
  String baseUrl() => 'https://api.example.com';
}
```

When used with `cherrypick_generator`, code similar to the following will be generated:

```dart
final class $AppModule extends AppModule {
  @override
  void builder(Scope currentScope) {
    bind<Dio>().toProvide(() => dio()).singleton();
    bind<String>().toProvide(() => baseUrl()).withName('baseUrl');
  }
}
```

---

## Annotation Reference

### `@module`

```dart
@module()
abstract class AppModule extends Module {}
```
Use on classes to mark them as a DI module.

---

### `@singleton`

```dart
@singleton()
Dio dio() => Dio();
```
Use on methods or classes to provide a singleton instance.

---

### `@named`

```dart
@named('token')
String token() => 'abc';
```
Assigns a name to the binding for keyed injection.

---

## License

Licensed under the [Apache License 2.0](LICENSE).

---

## Contributing

Pull requests and feedback are welcome!

---

## Author

Sergey Penkovsky (<sergey.penkovsky@gmail.com>)
