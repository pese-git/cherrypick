# Cherrypick Generator

**Cherrypick Generator** is a Dart code generation library for automatic boilerplate creation in dependency injection (DI) modules. It processes classes annotated with `@module()` (from [cherrypick_annotations](https://pub.dev/packages/cherrypick_annotations)) and generates code for registering dependencies, handling singletons, named bindings, runtime parameters, and more.

---

## Features

- **Automatic Binding Generation:**  
  Generates `bind<Type>()` registration code for every method in a DI module marked with `@module()`.

- **Support for DI Annotations:**  
  Understands and processes meta-annotations such as `@singleton`, `@named`, `@instance`, `@provide`, and `@params`.

- **Runtime & Compile-Time Parameters:**  
  Handles both injected (compile-time) and runtime parameters for provider/binding methods.

- **Synchronous & Asynchronous Support:**  
  Correctly distinguishes between synchronous and asynchronous bindings (including `Future<T>` return types).

- **Named Bindings:**  
  Allows registration of named services via the `@named()` annotation.

- **Singletons:**  
  Registers singletons via the `@singleton` annotation.

---

## How It Works

1. **Annotations**  
   Annotate your module classes and methods using `@module()`, `@instance`, `@provide`, `@singleton`, and `@named` as needed.

2. **Code Scanning**  
   During the build process (with `build_runner`), the generator scans your annotated classes.

3. **Code Generation**  
   For each `@module()` class, a new class (with a `$` prefix) is generated.  
   This class overrides the `builder(Scope)` method to register all bindings.

4. **Binding Logic**  
   Each binding method's signature and annotations are analyzed. Registration code is generated according to:
   - Return type (sync/async)
   - Annotations (`@singleton`, `@named`, etc.)
   - Parameter list (DI dependencies, `@named`, or `@params` for runtime values)

---

## Example

Given the following annotated Dart code:

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
class MyModule {
  @singleton
  @instance
  SomeService provideService(ApiClient client);

  @provide
  @named('special')
  Future<Handler> createHandler(@params Map<String, dynamic> params);
}
```

The generator will output (simplified):

```dart
final class $MyModule extends MyModule {
  @override
  void builder(Scope currentScope) {
    bind<SomeService>()
      .toInstance(provideService(currentScope.resolve<ApiClient>()))
      .singleton();

    bind<Handler>()
      .toProvideAsyncWithParams((args) => createHandler(args))
      .withName('special');
  }
}
```

---

## Generated Code Overview

- **Constructor Registration:**  
  All non-abstract methods are considered as providers and processed for DI registration.

- **Parameter Handling:**  
  Each method parameter is analyzed:
    - Standard DI dependency: resolved via `currentScope.resolve<Type>()`.
    - Named dependency: resolved via `currentScope.resolve<Type>(named: 'name')`.
    - Runtime parameter (`@params`): passed through as-is (e.g., `args`).

- **Binding Types:**  
  Supports both `.toInstance()` and `.toProvide()` (including async variants).

- **Singleton/Named:**  
  Appends `.singleton()` and/or `.withName('name')` as appropriate.

---

## Usage

1. **Add dependencies**  
   In your `pubspec.yaml`:
   ```yaml
   dependencies:
     cherrypick_annotations: ^x.y.z

   dev_dependencies:
     build_runner: ^2.1.0
     cherrypick_generator: ^x.y.z
   ```

2. **Apply annotations**  
   Annotate your DI modules and provider methods as shown above.

3. **Run the generator**  
   ```
   dart run build_runner build
   # or with Flutter:
   flutter pub run build_runner build
   ```

4. **Import and use the generated code**  
   The generated files (suffix `.cherrypick.g.dart`) contain your `$YourModule` classes ready for use with your DI framework.

---

## Advanced

- **Customizing Parameter Names:**  
  Use the `@named('value')` annotation on methods and parameters for named bindings.

- **Runtime Arguments:**  
  Use `@params` to designate parameters as runtime arguments that are supplied at injection time.

- **Async Factories:**  
  Methods returning `Future<T>` generate the appropriate `.toProvideAsync()` or `.toInstanceAsync()` bindings.

---

## Developer Notes

- The generator relies on Dart's analyzer, source_gen, and build packages.
- Each class and method is parsed for annotations; missing required annotations (like `@instance` or `@provide`) will result in a generation error.
- The generated code is designed to extend your original module classes while injecting all binding logic.

---

## License

```
Licensed under the Apache License, Version 2.0
```

---

## Contribution

Pull requests and issues are welcome! Please open git issues or submit improvements as needed.

---