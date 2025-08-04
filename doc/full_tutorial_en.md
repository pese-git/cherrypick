# Full Guide to CherryPick DI for Dart and Flutter: Dependency Injection with Annotations and Automatic Code Generation

**CherryPick** is a powerful tool for dependency injection in Dart and Flutter projects. It offers a modern approach with code generation, async providers, named and parameterized bindings, and field injection using annotations.

> Tools:  
> - [`cherrypick`](https://pub.dev/packages/cherrypick) — runtime DI core  
> - [`cherrypick_annotations`](https://pub.dev/packages/cherrypick_annotations) — DI annotations  
> - [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator) — DI code generation  
>

---

## CherryPick advantages vs other DI frameworks

- 📦 Simple declarative API for registering and resolving dependencies
- ⚡️ Full support for both sync and async registrations
- 🧩 DI via annotations with codegen, including advanced field injection
- 🏷️ Named bindings for multiple interface implementations
- 🏭 Parameterized bindings for runtime factories (e.g., by ID)
- 🌲 Flexible scope system for dependency isolation and hierarchy
- 🕹️ Optional resolution (`tryResolve`)
- 🐞 Clear compile-time errors for invalid annotation or DI configuration

---

## How CherryPick works: core concepts

### Dependency registration (bindings)

```dart
bind<MyService>().toProvide(() => MyServiceImpl());
bind<MyRepository>().toProvideAsync(() async => await initRepo());
bind<UserService>().toProvideWithParams((id) => UserService(id));

// Singleton
bind<MyApi>().toProvide(() => MyApi()).singleton();

// Register an already created object
final config = AppConfig.dev();
bind<AppConfig>().toInstance(config);

// Register an already running Future/async value
final setupFuture = loadEnvironment();
bind<Environment>().toInstanceAsync(setupFuture);
```

- **toProvide** — regular sync factory
- **toProvideAsync** — async factory (if you need to await a Future)
- **toProvideWithParams / toProvideAsyncWithParams** — factories with runtime parameters
- **toInstance** — registers an already created object as a dependency
- **toInstanceAsync** — registers an already started Future as an async dependency

### Named bindings

You can register several implementations of an interface under different names:

```dart
bind<ApiClient>().toProvide(() => ApiClientProd()).withName('prod');
bind<ApiClient>().toProvide(() => ApiClientMock()).withName('mock');

// Resolving by name:
final api = scope.resolve<ApiClient>(named: 'mock');
```

### Lifecycle: singleton

- `.singleton()` — single instance per Scope lifetime
- By default, every resolve creates a new object

### Parameterized bindings

Allows you to create dependencies with runtime parameters, e.g., a service for a user with a given ID:

```dart
bind<UserService>().toProvideWithParams((userId) => UserService(userId));

// Resolve:
final userService = scope.resolve<UserService>(params: '123');
```

---

## Scope management: dependency hierarchy

For most business cases, a single root scope is enough, but CherryPick supports nested scopes:

```dart
final rootScope = CherryPick.openRootScope();
final profileScope = rootScope.openSubScope('profile')
  ..installModules([ProfileModule()]);
```

- **Subscope** can override parent dependencies.
- When resolving, first checks its own scope, then up the hierarchy.


## Managing names and scope hierarchy (subscopes) in CherryPick

CherryPick supports nested scopes, each can be "root" or a child. For accessing/managing the hierarchy, CherryPick uses scope names (strings) as well as convenient open/close methods.

### Open subScope by name

CherryPick uses separator-delimited strings to search and build scope trees, for example:

```dart
final subScope = CherryPick.openScope(scopeName: 'profile.settings');
```

- Here, `'profile.settings'` will open 'profile' subscope in root, then 'settings' subscope in 'profile'.
- Default separator is a dot (`.`), can be changed via `separator` argument.

**Example with another separator:**

```dart
final subScope = CherryPick.openScope(
  scopeName: 'project>>dev>>api',
  separator: '>>',
);
```

### Hierarchy & access

Each hierarchy level is a separate scope.  
This is convenient for restricting/localizing dependencies, for example:  
- `main.profile` — dependencies only for user profile  
- `main.profile.details` — even narrower context

### Closing subscopes

To close a specific subScope, use the same path:

```dart
CherryPick.closeScope(scopeName: 'profile.settings');
```

- Closing a top-level scope (`profile`) wipes all children too.

### Methods summary

| Method                    | Description                                             |
|---------------------------|--------------------------------------------------------|
| `openRootScope()`         | Open/get root scope                                    |
| `closeRootScope()`        | Close root scope, remove all dependencies              |
| `openScope(scopeName)`    | Open scope(s) by name & hierarchy (`'a.b.c'`)          |
| `closeScope(scopeName)`   | Close specified scope or subScope                      |

---

**Recommendations:**  
Use meaningful names and dot notation for scope structuring in large apps—this improves readability and dependency management on any level.

---

**Example:**

```dart
// Opens scopes by hierarchy: app -> module -> page
final scope = CherryPick.openScope(scopeName: 'app.module.page');

// Closes 'module' and all nested subscopes
CherryPick.closeScope(scopeName: 'app.module');
```

---

This lets you scale CherryPick DI for any app complexity!

---

## Safe dependency resolution

If not sure a dependency exists, use tryResolve/tryResolveAsync:

```dart
final service = scope.tryResolve<OptionalService>(); // returns null if not exists
```

---

### Fast Dependency Lookup (Performance Improvement)

> **Performance Note:**  
> **Starting from version 3.0.0**, CherryPick uses a Map-based resolver index for dependency lookup. This means calls to `resolve<T>()`, `tryResolve<T>()` and similar methods are now O(1) operations, regardless of the number of modules or bindings within your scope. Previously it would iterate over all modules and bindings, which could reduce performance as your project grew. This optimization is internal and does not affect the public API or usage patterns, but significantly improves resolution speed for larger applications.

---


## Automatic resource management: Disposable and dispose

CherryPick makes it easy to clean up resources for your singleton services and other objects registered in DI.  
If your class implements the `Disposable` interface, always **await** `scope.dispose()` (or `CherryPick.closeRootScope()`) when you want to free all resources in your scope — CherryPick will automatically await `dispose()` for every object that implements `Disposable` and was resolved via DI.  
This ensures safe and graceful resource management (including any async resource cleanup: streams, DB connections, sockets, etc.).

### Example

```dart
class LoggingService implements Disposable {
  @override
  FutureOr<void> dispose() async {
    // Close files, streams, and perform async cleanup here.
    print('LoggingService disposed!');
  }
}

Future<void> main() async {
  final scope = openRootScope();
  scope.installModules([
    _LoggingModule(),
  ]);
  final logger = scope.resolve<LoggingService>();
  // Use logger...
  await scope.dispose(); // prints: LoggingService disposed!
}

class _LoggingModule extends Module {
  @override
  void builder(Scope scope) {
    bind<LoggingService>().toProvide(() => LoggingService()).singleton();
  }
}
```

## Dependency injection with annotations & code generation

CherryPick supports DI with annotations, letting you eliminate manual DI setup.

### Annotation structure

| Annotation     | Purpose                   | Where to use                      |
|---------------|---------------------------|------------------------------------|
| `@module`     | DI module                 | Classes                            |
| `@singleton`  | Singleton                 | Module methods                     |
| `@instance`   | New object                | Module methods                     |
| `@provide`    | Provider                  | Methods (with DI params)           |
| `@named`      | Named binding             | Method argument/Class fields        |
| `@params`     | Parameter passing         | Provider argument                  |
| `@injectable` | Field injection support   | Classes                            |
| `@inject`     | Auto-injection            | Class fields                       |
| `@scope`      | Scope/realm               | Class fields                       |

### Example DI module

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
- Methods annotated with `@provide` become DI factories.
- Add other annotations to specify binding type or name.

Generated code will look like:

```dart
class $AppModule extends AppModule {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toProvide(() => apiClient()).singleton();
    bind<UserService>().toProvide(() => userService(currentScope.resolve<ApiClient>()));
    bind<ApiClient>().toProvide(() => mockApiClient()).withName('mock').singleton();
  }  
}
```

### Example: field injection

```dart
@injectable()
class ProfileBloc with _$ProfileBloc {
  @inject()
  late final AuthService auth;

  @inject()
  @named('admin')
  late final UserService adminUser;
  
  ProfileBloc() {
    _inject(this); // injectFields — generated method
  }
}
```
- Generator creates a mixin (`_$ProfileBloc`) which automatically resolves and injects dependencies into fields.
- The `@named` annotation links a field to a named implementation.

Example generated code:

```dart
mixin $ProfileBloc {
  @override
  void _inject(ProfileBloc instance) {
    instance.auth = CherryPick.openRootScope().resolve<AuthService>();
    instance.adminUser = CherryPick.openRootScope().resolve<UserService>(named: 'admin');
  }  
}
```

### How to connect it

```dart
void main() async {
  final scope = CherryPick.openRootScope();
  scope.installModules([
    $AppModule(),
  ]);
  // DI via field injection
  final bloc = ProfileBloc();
  runApp(MyApp(bloc: bloc));
}
```

---

## Async dependencies

For async providers, use `toProvideAsync`, and resolve them with `resolveAsync`:

```dart
bind<RemoteConfig>().toProvideAsync(() async => await RemoteConfig.load());

// Usage:
final config = await scope.resolveAsync<RemoteConfig>();
```

---

## Validation and diagnostics

- If you use incorrect annotations or DI config, you'll get clear compile-time errors.
- Binding errors are found during code generation, minimizing runtime issues and speeding up development.

---

## Flutter integration: cherrypick_flutter

### What it is

[`cherrypick_flutter`](https://pub.dev/packages/cherrypick_flutter) is the integration package for CherryPick DI in Flutter. It provides a convenient `CherryPickProvider` widget which sits in your widget tree and gives access to the root DI scope (and subscopes) from context.

## Features

- **Global DI Scope Access:**  
  Use `CherryPickProvider` to access rootScope and subscopes anywhere in the widget tree.
- **Context integration:**  
  Use `CherryPickProvider.of(context)` for DI access inside your widgets.

### Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';

void main() {
  runApp(
    CherryPickProvider(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).openRootScope();

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            rootScope.resolve<AppService>().getStatus(),
          ),
        ),
      ),
    );
  }
}
```

- Here, `CherryPickProvider` wraps the app and gives DI scope access via context.
- You can create subscopes, e.g. for screens or modules:  
  `final subScope = CherryPickProvider.of(context).openSubScope(scopeName: "profileFeature");`

---

## Logging

To enable logging of all dependency injection (DI) events and errors in CherryPick, set the global logger before creating your scopes:

```dart
import 'package:cherrypick/cherrypick.dart';

void main() {
  // Set a global logger before any scopes are created
  CherryPick.setGlobalLogger(PrintLogger()); // or your own custom logger
  final scope = CherryPick.openRootScope();
  // All DI events and cycle errors will now be sent to your logger
}
```

- By default, CherryPick uses SilentLogger (no output in production).
- Any dependency resolution, scope events, or cycle detection errors are logged via info/error on your logger.

---
## CherryPick is not just for Flutter!

You can use CherryPick in Dart CLI, server apps, and microservices. All major features work without Flutter.

---

## CherryPick Example Project: Step by Step

1. Add dependencies:
    ```yaml
    dependencies:
      cherrypick: ^1.0.0
      cherrypick_annotations: ^1.0.0

    dev_dependencies:
      build_runner: ^2.0.0
      cherrypick_generator: ^1.0.0
    ```

2. Describe your modules using annotations.

3. To generate DI code:
    ```shell
    dart run build_runner build --delete-conflicting-outputs
    ```

4. Enjoy modern DI with no boilerplate!

---

## Conclusion

**CherryPick** is a modern DI solution for Dart and Flutter, combining a concise API and advanced annotation/codegen features. Scopes, parameterized providers, named bindings, and field-injection make it great for both small and large-scale projects.

**Full annotation list and their purposes:**

| Annotation     | Purpose                   | Where to use                      |
|---------------|---------------------------|------------------------------------|
| `@module`     | DI module                 | Classes                            |
| `@singleton`  | Singleton                 | Module methods                     |
| `@instance`   | New object                | Module methods                     |
| `@provide`    | Provider                  | Methods (with DI params)           |
| `@named`      | Named binding             | Method argument/Class fields        |
| `@params`     | Parameter passing         | Provider argument                  |
| `@injectable` | Field injection support   | Classes                            |
| `@inject`     | Auto-injection            | Class fields                       |
| `@scope`      | Scope/realm               | Class fields                       |


---

## FAQ

### Q: Do I need to use `await` with CherryPick.closeRootScope(), CherryPick.closeScope(), or scope.dispose() if I have no Disposable services?

**A:**  
Yes! Even if none of your services currently implement `Disposable`, always use `await` when closing scopes. If you later add resource cleanup (by implementing `dispose()`), CherryPick will handle it automatically without you needing to change your scope cleanup code. This ensures resource management is future-proof, robust, and covers all application scenarios.

---

## Useful Links

- [cherrypick](https://pub.dev/packages/cherrypick)
- [cherrypick_annotations](https://pub.dev/packages/cherrypick_annotations)
- [cherrypick_generator](https://pub.dev/packages/cherrypick_generator)
- [Sources on GitHub](https://github.com/pese-git/cherrypick)
