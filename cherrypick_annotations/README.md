# cherrypick_annotations

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A lightweight set of Dart annotations designed for dependency injection (DI) frameworks and code generation, inspired by modern approaches like Dagger and Injectable. Works best in tandem with [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator).

---

## Features

- **@module** – Marks a class as a DI module for service/provider registration.
- **@singleton** – Declares that a method or class should be provided as a singleton.
- **@instance** – Marks a method or class so that a new instance is provided on each request (not a singleton).
- **@provide** – Marks a method whose return value should be registered as a provider, supporting dependency injection into parameters.
- **@named** – Assigns a string name to a binding for keyed resolution.
- **@params** – Indicates that a parameter should be injected with runtime-supplied arguments.

These annotations streamline DI configuration and serve as markers for code generation tools such as [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator).

---

## Getting Started

### 1. Add dependency

```yaml
dependencies:
  cherrypick_annotations: ^latest
```

Add as a `dev_dependency` for code generation:

```yaml
dev_dependencies:
  build_runner: ^latest
  cherrypick_generator:
```

### 2. Annotate your DI modules and providers

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

@module()
abstract class AppModule extends Module {
  @singleton()
  Dio dio() => Dio();

  @named('baseUrl')
  String baseUrl() => 'https://api.example.com';

  @instance()
  Foo foo() => Foo();

  @provide()
  Bar bar(Foo foo) => Bar(foo);

  @provide()
  String greet(@params() dynamic params) => 'Hello $params';
}
```

When used with `cherrypick_generator`, code similar to the following will be generated:

```dart
final class $AppModule extends AppModule {
  @override
  void builder(Scope currentScope) {
    bind<Dio>().toProvide(() => dio()).singleton();
    bind<String>().toProvide(() => baseUrl()).withName('baseUrl');
    bind<Foo>().toInstance(foo());
    bind<Bar>().toProvide(() => bar(currentScope.resolve<Foo>()));
    bind<String>().toProvideWithParams((args) => greet(args));
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
Use on classes to mark them as a DI module. This is the root for registering your dependency providers.

---

### `@singleton`

```dart
@singleton()
Dio dio() => Dio();
```
Use on methods or classes to provide a singleton instance (the same instance is reused).

---

### `@instance`

```dart
@instance()
Foo foo() => Foo();
```
Use on methods or classes to provide a new instance on each request (not a singleton).

---

### `@provide`

```dart
@provide()
Bar bar(Foo foo) => Bar(foo);
```
Use on methods to indicate they provide a dependency to the DI module. Dependencies listed as parameters (e.g., `foo`) are resolved and injected.

---

### `@named`

```dart
@named('token')
String token() => 'abc';
```
Assigns a name to a binding for keyed injection or resolution.

---

### `@params`

```dart
@provide()
String greet(@params() dynamic params) => 'Hello $params';
```
Use on method parameters to indicate that this parameter should receive runtime-supplied arguments during dependency resolution (for example, via `.toProvide*((params) => greate(params))` in generated code).

---

## License

Licensed under the [Apache License 2.0](LICENSE).

---

## Contributing

Pull requests and feedback are welcome!

---

## Author

Sergey Penkovsky (<sergey.penkovsky@gmail.com>)