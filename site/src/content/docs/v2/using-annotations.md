---
title: Using Annotations
description: Declarative DI with annotations and code generation — modules, providers, and field injection.
---

CherryPick 2.x supports DI with annotations, so you can eliminate manual wiring.
You annotate modules, providers, and fields; `cherrypick_generator` processes
them and generates the registration and injection code.

Run the generator whenever your DI code changes:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Supported annotations

| Annotation | Where | Purpose |
| ---------- | ----- | ------- |
| `@module()` | class | Marks a DI module (methods become providers) |
| `@provide()` | method | Registers a type via this provider method |
| `@instance()` | method | Registers a direct instance |
| `@singleton()` | method / class | The target is a singleton |
| `@named()` | method / field | Bind or resolve a named implementation |
| `@params()` | parameter | Accepts runtime parameters for providers |
| `@injectable()` | class | Enables field injection; a mixin is generated |
| `@inject()` | field | The field is injected automatically |
| `@scope()` | field | Resolve this field from a named scope |

## Module binding

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule extends Module {
  @singleton()
  @provide()
  ApiClient apiClient() => ApiClient();

  @provide()
  UserService userService(ApiClient api) => UserService(api);

  @singleton()
  @provide()
  @named('mock')
  ApiClient mockApiClient() => ApiClientMock();
}
```

The generator produces a `$AppModule` class that implements `builder`:

```dart
class $AppModule extends AppModule {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toProvide(() => apiClient()).singleton();
    bind<UserService>()
        .toProvide(() => userService(currentScope.resolve<ApiClient>()));
    bind<ApiClient>()
        .toProvide(() => mockApiClient())
        .withName('mock')
        .singleton();
  }
}
```

## Field injection

Annotate a class with `@injectable()` and its fields with `@inject()`. The
generator creates a mixin that resolves and assigns the fields.

```dart
@injectable()
class ProfileBloc with _$ProfileBloc {
  @inject()
  late final AuthService auth;

  @inject()
  @named('admin')
  late final UserService adminUser;

  ProfileBloc() {
    _inject(this); // generated injector
  }
}
```

Generated mixin (illustrative):

```dart
mixin _$ProfileBloc {
  void _inject(ProfileBloc instance) {
    instance.auth = CherryPick.openRootScope().resolve<AuthService>();
    instance.adminUser =
        CherryPick.openRootScope().resolve<UserService>(named: 'admin');
  }
}
```

## Wiring it up

```dart
void main() {
  final scope = CherryPick.openRootScope()
    ..installModules([
      $AppModule(),
    ]);

  final bloc = ProfileBloc(); // fields injected in the constructor
  runApp(MyApp(bloc: bloc));
}
```

## Notes

- Providers may return `Future<T>` (async) or a plain value (sync).
- Combine `@named` and `@scope` on fields/methods to target named implementations
  or named scopes.
- Do not edit the generated `.g.dart` files by hand.
- Invalid annotation usage is reported at build time, not at runtime.
