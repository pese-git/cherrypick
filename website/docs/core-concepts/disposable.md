---
sidebar_position: 4
---

# Disposable

CherryPick can automatically clean up any dependency that implements the `Disposable` interface. This makes resource management (for controllers, streams, sockets, files, etc.) easy and reliable—especially when scopes or the app are shut down.

If you bind an object implementing `Disposable` as a singleton or provide it via the DI container, CherryPick will call its `dispose()` method when the scope is closed or cleaned up.

## Key Points
- Supports both synchronous and asynchronous cleanup (dispose may return `void` or `Future`).
- All `Disposable` instances from the current scope and subscopes will be disposed in the correct order.
- An instance is owned by the scope that **declares its binding** — see [Ownership](#ownership-which-scope-disposes-what).
- Prevents resource leaks and enforces robust cleanup.
- No manual wiring needed once your class implements `Disposable`.

## Ownership: which scope disposes what

A `Disposable` is released by the scope that **declares its binding**, not by the
scope you happened to call `resolve()` on.

Because a subscope falls back to its parent for anything it does not declare
itself, resolving a parent dependency through a subscope does **not** transfer
ownership:

```dart
final root = CherryPick.openRootScope()
  ..installModules([AppModule()]);        // Database is declared here
final feature = root.openSubScope('feature');

final db = feature.resolve<Database>();   // resolved through the subscope...
await root.closeSubScope('feature');      // ...but NOT disposed here

db.query('...');                          // still valid — root owns it

await CherryPick.closeRootScope();        // disposed here
```

**Consequence to keep in mind:** if a binding lives in a long-lived scope and is
*not* marked `.singleton()`, every instance it creates for short-lived subscopes
accumulates in that long-lived scope until it closes. Declare a binding in the
scope whose lifetime matches the resource:

```dart
// Leaks until root closes: a new connection per screen, all owned by root.
// root: bind<Connection>().toProvide(() => Connection());

// Released with the screen: the binding lives where the resource belongs.
screenScope.installModules([ConnectionModule()]);
```

## Minimal Sync Example
```dart
class CacheManager implements Disposable {
  void dispose() {
    cache.clear();
    print('CacheManager disposed!');
  }
}

final scope = CherryPick.openRootScope();
scope.installModules([
  Module((bind) => bind<CacheManager>().toProvide(() => CacheManager()).singleton()),
]);

// ...later
await CherryPick.closeRootScope(); // prints: CacheManager disposed!
```

## Async Example
```dart
class MyServiceWithSocket implements Disposable {
  @override
  Future<void> dispose() async {
    await socket.close();
    print('Socket closed!');
  }
}

scope.installModules([
  Module((bind) => bind<MyServiceWithSocket>().toProvide(() => MyServiceWithSocket()).singleton()),
]);

await CherryPick.closeRootScope(); // awaits async disposal
```

**Tip:** Always call `await CherryPick.closeRootScope()` or `await scope.closeSubScope(key)` in your shutdown/teardown logic to ensure all resources are released automatically. Closing a subscope releases what that subscope declares; dependencies inherited from a parent are released when the parent closes.
