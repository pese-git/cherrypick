# cherrypick_annotations

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A lightweight set of Dart annotations for dependency injection (DI) frameworks and code generation, inspired by modern approaches like Dagger and Injectable. Optimized for use with [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator).

---

## Features

- **@module** – Marks a class as a DI module for service/provider registration.
- **@singleton** – Declares that a method or class should be provided as a singleton.
- **@instance** – Marks a method or class so that a new instance is provided on each request.
- **@provide** – Marks a method whose return value should be registered as a provider, supporting DI into its parameters.
- **@named** – Assigns a string name to a binding for keyed resolution and injection.
- **@params** – Indicates that a parameter should be injected with runtime-supplied arguments.
- **@injectable** – Marks a class as eligible for automatic field injection. Fields annotated with `@inject` will be injected by the code generator.
- **@inject** – Marks a field to be automatically injected by the code generator.
- **@scope** – Declares the DI scope from which a dependency should be resolved for a field.

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
  cherrypick_generator: ^latest
  build_runner: ^latest
```

---

### 2. Annotate your DI modules, providers, and injectable classes

#### **Module and Provider Example**

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule {
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

With `cherrypick_generator`, code like the following will be generated:

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

#### **Field Injection Example**

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class ProfileView with _$ProfileView{
  @inject()
  late final AuthService auth;

  @inject()
  @scope('profile')
  late final ProfileManager manager;

  @inject()
  @named('admin')
  late final UserService adminUserService;
}
```

The code generator produces a mixin (simplified):

```dart
mixin _$ProfileView {
  void _inject(ProfileView instance) {
    instance.auth = CherryPick.openRootScope().resolve<AuthService>();
    instance.manager = CherryPick.openScope(scopeName: 'profile').resolve<ProfileManager>();
    instance.adminUserService = CherryPick.openRootScope().resolve<UserService>(named: 'admin');
  }
}
```

---

## Annotation Reference

### `@injectable`

```dart
@injectable()
class MyWidget { ... }
```
Marks a class as injectable for CherryPick DI. The code generator will generate a mixin to perform automatic injection of fields marked with `@inject()`.

---

### `@inject`

```dart
@inject()
late final SomeService service;
```
Applied to a field to request automatic injection of the dependency using the CherryPick DI framework.

---

### `@scope`

```dart
@inject()
@scope('profile')
late final ProfileManager manager;
```
Specifies the scope from which the dependency should be resolved for an injected field.

---

### `@module`

```dart
@module()
abstract class AppModule {}
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
Can be used on both provider methods and fields.

---

### `@params`

```dart
@provide()
String greet(@params() dynamic params) => 'Hello $params';
```
Indicates that this parameter should receive runtime-supplied arguments during dependency resolution.

---

## License

Licensed under the [Apache License 2.0](LICENSE).

---

## Contributing

Pull requests and feedback are welcome!

---

## Author

Sergey Penkovsky (<sergey.penkovsky@gmail.com>)