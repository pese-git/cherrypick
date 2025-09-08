# Release - CherryPick 3.x

> **CherryPick** — a lightweight and modular DI framework for Dart and Flutter that solves dependency injection through strong typing, code generation, and dependency control.

Version **3.x** was recently released with significant improvements.

## Main Changes in 3.x

* **O(1) dependency resolution** — thanks to Map indexing of bindings, performance does not depend on the size of the scope in the DI graph. This provides noticeable speedup in large projects.
* **Protection against circular dependencies** — checking works both within a single scope and across the entire hierarchy. When a cycle is detected, an informative exception with the dependency chain is thrown.
* **Integration with Talker** — all DI events (registration, creation, deletion, errors) are logged and can be displayed in the console or UI.
* **Automatic resource cleanup** — objects implementing `Disposable` are properly released when the scope is closed.
* **Stabilized declarative approach support** — annotations and code generation now work more reliably and are more convenient for use in projects.

## Resource Cleanup Example

```dart
class MyServiceWithSocket implements Disposable {
  @override
  Future<void> dispose() async {
    await socket.close();
    print('Socket closed!');
  }
}

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    // singleton Api
    bind<MyServiceWithSocket>()
      .toProvide(() => MyServiceWithSocket())
      .singleton();
  }
}

scope.installModules([AppModule()]);

await CherryPick.closeRootScope(); // will wait for async dispose to complete
```

## Circular Dependency Checking

One of the new features in CherryPick 3.x is built-in cycle protection.
This helps catch situations early where services start depending on each other recursively.

### How to Enable Checking

For checking within a single scope:

```dart
final scope = CherryPick.openRootScope();
scope.enableCycleDetection();
```

For global checking across the entire hierarchy:

```dart
CherryPick.enableGlobalCycleDetection();
CherryPick.enableGlobalCrossScopeCycleDetection();
final rootScope = CherryPick.openRootScope();
```

### How a Cycle Can Occur

Suppose we have two services that depend on each other:

```dart
class UserService {
  final OrderService orderService;
  UserService(this.orderService);
}

class OrderService {
  final UserService userService;
  OrderService(this.userService);
}
```

If we register them in the same scope:

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<UserService>().toProvide(() => UserService(scope.resolve()));
    bind<OrderService>().toProvide(() => OrderService(scope.resolve()));
  }
}

final scope = CherryPick.openRootScope()
  ..enableCycleDetection()
  ..installModules([AppModule()]);

scope.resolve<UserService>();
```

Then when trying to resolve the dependency, an exception will be thrown:

```bash
❌ Circular dependency detected for UserService
Dependency chain: UserService -> OrderService -> UserService
```

This way, the error is detected immediately, not "somewhere in runtime".

## Integration with Talker

CherryPick 3.x allows logging all DI events through [Talker](https://pub.dev/packages/talker): registration, object creation, deletion, and errors. This is convenient for debugging and diagnosing the dependency graph.

Connection example:

```dart
final talker = Talker();
final observer = TalkerCherryPickObserver(talker);
CherryPick.setGlobalObserver(observer);
```

After this, DI events will be displayed in the console or UI:

```bash
┌───────────────────────────────────────────────────────────────
│ [info]    9:41:33  | [scope opened][CherryPick] scope_1757054493089_7072
└───────────────────────────────────────────────────────────────
┌───────────────────────────────────────────────────────────────
│ [verbose] 9:41:33  | [diagnostic][CherryPick] Scope created: scope_1757054493089_7072 {type: Scope, name: scope_1757054493089_7072, description: scope created}
└───────────────────────────────────────────────────────────────
```

In the log, you can see when scopes are created, which objects are registered and deleted, and catch errors and cycles in real time.


## Declarative Approach with Annotations

In addition to fully programmatic module descriptions, CherryPick supports **declarative DI style through annotations**.  
This allows minimizing manual code and automatically generating modules and mixins for automatic dependency injection.

Example of a declarative module:

```dart
@module()
abstract class AppModule extends Module {
  @provide()
  @singleton()
  Api api() => Api();

  @provide()
  Repo repo(Api api) => Repo(api);
}
````

After code generation, you can automatically inject dependencies into widgets or services:

```dart
@injectable()
class MyScreen extends StatelessWidget with _$MyScreen {
  @inject()
  late final Repo repo;

  MyScreen() {
    _inject(this);
  }
}
```

This way you can choose an approach in development: **programmatic (imperative) with explicit dependency registration** or **declarative through annotations**.


## Who Might Find CherryPick Useful?

* Projects where it's important to guarantee **no cycles in the dependency graph**;
* Teams that want to **minimize manual DI code** and use a declarative style with annotations;
* Applications that require **automatic resource cleanup** (sockets, controllers, streams).

## Useful Links

* 📦 Package: [pub.dev/packages/cherrypick](https://pub.dev/packages/cherrypick)
* 💻 Code: [github.com/pese-git/cherrypick](https://github.com/pese-git/cherrypick)
* 📖 Documentation: [cherrypick-di.netlify.app](https://cherrypick-di.netlify.app/)
