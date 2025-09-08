---
sidebar_position: 4
---

# Disposable

CherryPick can automatically clean up any dependency that implements the `Disposable` interface. This makes resource management (for controllers, streams, sockets, files, etc.) easy and reliable—especially when scopes or the app are shut down.

If you bind an object implementing `Disposable` as a singleton or provide it via the DI container, CherryPick will call its `dispose()` method when the scope is closed or cleaned up.

## Key Points
- Supports both synchronous and asynchronous cleanup (dispose may return `void` or `Future`).
- All `Disposable` instances from the current scope and subscopes will be disposed in the correct order.
- Prevents resource leaks and enforces robust cleanup.
- No manual wiring needed once your class implements `Disposable`.

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

**Tip:** Always call `await CherryPick.closeRootScope()` or `await scope.closeSubScope(key)` in your shutdown/teardown logic to ensure all resources are released automatically.
