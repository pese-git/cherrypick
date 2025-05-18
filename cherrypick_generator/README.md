# cherrypick_generator

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A code generator for dependency injection (DI) modules in Dart, designed to work with [`cherrypick_annotations`](https://pub.dev/packages/cherrypick_annotations). This package generates efficient, boilerplate-free registration code for your annotated module classes—making the provisioning and resolution of dependencies fast, type-safe, and expressive.

---

## Features

- **Generates DI module extension classes** from Dart classes annotated with `@module()`
- **Automatic binding** of methods and dependencies based on `@singleton()`, `@named('...')`, and parameter-level annotations
- **Optimized for readability/maintainability:** code output follows best practices for Dart and DI
- **Integrated with build_runner** for seamless incremental builds

---

## How It Works

1. You annotate your abstract classes with `@module()` and your provider methods inside with `@singleton()` or `@named()`.
2. Run `build_runner` to trigger code generation.
3. The generator creates a class (prefixed with `$`) extending your module, overriding the `builder()` method to register your dependencies with `bind<T>().toProvide(...)`, `.singleton()`, `.withName()`, etc.

**Example:**

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:cherrypick/cherrypick.dart';

part 'app_module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @singleton()
  Dio dio() => Dio();

  @named('apiBaseUrl')
  String baseUrl() => 'https://api.example.com';
}
```

Generates:

```dart
final class $AppModule extends AppModule {
  @override
  void builder(Scope currentScope) {
    bind<Dio>().toProvide(() => dio()).singleton();
    bind<String>().toProvide(() => baseUrl()).withName('apiBaseUrl');
  }
}
```

---

## Getting Started

### 1. Add dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cherrypick_annotations: ^latest

dev_dependencies:
  cherrypick_generator: ^latest
  build_runner: ^latest
```

### 2. Annotate modules

See the example above. Use
- `@module()` on abstract classes
- `@singleton()` on methods for singleton bindings
- `@named('name')` on methods or method parameters to indicate named resolvers

### 3. Build

```shell
dart run build_runner build
```

This generates `.cherrypick.g.dart` files containing the `$YourModule` classes.

---

## Advanced Usage

**Parameter Injection with @named:**

```dart
@module()
abstract class NetworkModule {
  @singleton()
  Dio dio(@named('baseUrl') String url) => Dio(BaseOptions(baseUrl: url));
}
```
Which will be generated as:

```dart
bind<Dio>().toProvide(() => dio(
  currentScope.resolve<String>(named: 'baseUrl')
)).singleton();
```

---

## License

Licensed under the [Apache License 2.0](LICENSE).

---

## Contributing

PRs and issues welcome! Please file bugs or feature requests via GitHub.

---

## Author

Sergey Penkovsky (<sergey.penkovsky@gmail.com>)