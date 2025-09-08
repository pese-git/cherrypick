[![Melos + FVM CI](https://github.com/pese-git/cherrypick/actions/workflows/pipeline.yml/badge.svg)](https://github.com/pese-git/cherrypick/actions/workflows/pipeline.yml)

---

# Cherrypick Generator

**Cherrypick Generator** is a Dart code generation library for automating dependency injection (DI) boilerplate. It processes classes and fields annotated with [cherrypick_annotations](https://pub.dev/packages/cherrypick_annotations) and generates registration code for services, modules, and field injection for classes marked as `@injectable`. It supports advanced DI features such as scopes, named bindings, parameters, and asynchronous dependencies.

---

## Features

- **Automatic Field Injection:**  
  Detects classes annotated with `@injectable()`, and generates mixins to inject all fields annotated with `@inject()`, supporting scope and named qualifiers.

- **Module and Service Registration:**  
  For classes annotated with `@module()`, generates service registration code for methods using annotations such as `@provide`, `@instance`, `@singleton`, `@named`, and `@params`.

- **Scope & Named Qualifier Support:**  
  Supports advanced DI features:  
  &nbsp;&nbsp;• Field-level scoping with `@scope('scopename')`  
  &nbsp;&nbsp;• Named dependencies via `@named('value')`

- **Synchronous & Asynchronous Support:**  
  Handles both synchronous and asynchronous services (including `Future<T>`) for both field injection and module registration.

- **Parameters and Runtime Arguments:**  
  Recognizes and wires both injected dependencies and runtime parameters using `@params`.

- **Error Handling:**  
  Validates annotations at generation time. Provides helpful errors for incorrect usage (e.g., using `@injectable` on non-class elements).

---

## How It Works

### 1. Annotate your code

Use annotations from [cherrypick_annotations](https://pub.dev/packages/cherrypick_annotations):

- `@injectable()` — on classes to enable field injection  
- `@inject()` — on fields to specify they should be injected  
- `@scope()`, `@named()` — on fields or parameters for advanced wiring  
- `@module()` — on classes to mark as DI modules  
- `@provide`, `@instance`, `@singleton`, `@params` — on methods and parameters for module-based DI

### 2. Run the generator

Use `build_runner` to process your code and generate `.module.cherrypick.g.dart` and `.inject.cherrypick.g.dart` files.

### 3. Use the output in your application

- For modules: Register DI providers using the generated `$YourModule` class.
- For services: Enable field injection on classes using the generated mixin.

---

## Field Injection Example

Given the following:

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class MyWidget with _$MyWidget {
  @inject()
  late final AuthService auth;

  @inject()
  @scope('profile')
  late final ProfileManager manager;

  @inject()
  @named('special')
  late final ApiClient specialApi;
}
```

**The generator will output (simplified):**
```dart
mixin _$MyWidget {
  void _inject(MyWidget instance) {
    instance.auth = CherryPick.openRootScope().resolve<AuthService>();
    instance.manager = CherryPick.openScope(scopeName: 'profile').resolve<ProfileManager>();
    instance.specialApi = CherryPick.openRootScope().resolve<ApiClient>(named: 'special');
  }
}
```
You can then mix this into your widget to enable automatic DI at runtime.

---

## Module Registration Example

Given:

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
class MyModule {
  @singleton
  @instance
  AuthService provideAuth(Api api);

  @provide
  @named('logging')
  Future<Logger> provideLogger(@params Map<String, dynamic> args);
}
```

**The generator will output (simplified):**
```dart
final class $MyModule extends MyModule {
  @override
  void builder(Scope currentScope) {
    bind<AuthService>()
      .toInstance(provideAuth(currentScope.resolve<Api>()))
      .singleton();

    bind<Logger>()
      .toProvideAsyncWithParams((args) => provideLogger(args))
      .withName('logging');
  }
}
```

---

## Key Points

- **Rich Annotation Support:** 
  Mix and match field, parameter, and method annotations for maximum flexibility.
- **Scope and Named Resolution:**
  Use `@scope('...')` and `@named('...')` to precisely control where and how dependencies are wired.
- **Async/Synchronous:**  
  The generator distinguishes between sync (`resolve<T>`) and async (`resolveAsync<T>`) dependencies.
- **Automatic Mixins:**  
  For classes with `@injectable()`, a mixin is generated that injects all relevant fields (using constructor or setter).
- **Comprehensive Error Checking:**  
  Misapplied annotations (e.g., `@injectable()` on non-class) produce clear build-time errors.

---

## Usage

1. **Add dependencies**

   ```yaml
   dependencies:
     cherrypick_annotations: ^latest

   dev_dependencies:
     cherrypick_generator: ^latest
     build_runner: ^2.1.0
   ```

2. **Annotate your classes and modules as above**

3. **Run the generator**

   ```shell
   dart run build_runner build
   # or, if using Flutter:
   flutter pub run build_runner build
   ```

4. **Use generated code**

   - Import the generated `.inject.cherrypick.g.dart` or `.cherrypick.g.dart` files where needed

---

## Advanced Usage

- **Combining Modules and Field Injection:**  
  It's possible to mix both style of DI — modules for binding, and field injection for consuming services.
- **Parameter and Named Injection:**  
  Use `@named` on both provider and parameter for named registration and lookup; use `@params` to pass runtime arguments.
- **Async Factories:**  
  Methods returning Future<T> generate async bindings and async field resolution logic.

---

## Developer Notes

- The generator relies on the Dart analyzer, `source_gen`, and `build` packages.
- All classes and methods are parsed for annotations.
- Improper annotation usage will result in generator errors.

---

## License

```
Licensed under the Apache License, Version 2.0
```

---

## Contribution

Pull requests and issues are welcome! Please open GitHub issues or submit improvements.

---

