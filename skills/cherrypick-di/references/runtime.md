# CherryPick runtime (`package:cherrypick/cherrypick.dart`, 4.x)

## Scopes

```dart
final root = CherryPick.openRootScope();            // process-wide singleton root
final feature = root.openSubScope('feature');       // created once, then reused
final same = CherryPick.openScope(scopeName: 'feature');      // identical(feature, same)
final nested = CherryPick.openScope(scopeName: 'feature.cart'); // path, '.' by default
```

- `openSubScope(name)` and `CherryPick.openScope(...)` **create the scope if it
  does not exist** and return the existing one otherwise.
- A scope resolves from its own modules first, then walks up the parent chain.
  Parents never see children's bindings.
- `installModules([...])` runs each module's `builder(scope)` immediately and
  returns the scope (cascade-friendly). Installing throws `StateError` if a
  module has a `bind<T>()` with no target.
- `dropModules()` removes bindings but **does not** dispose anything.

Closing:

```dart
await root.closeSubScope('feature');                    // disposes, then forgets the child
await CherryPick.closeScope(scopeName: 'feature.cart'); // same, by path
await CherryPick.closeRootScope();                      // disposes the whole tree, next openRootScope() is fresh
await scope.dispose();                                  // disposes in place (no removal from parent)
```

After closing, opening the same name gives a new, empty scope.

## Bindings (`Module.builder`)

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Config>().toInstance(Config.fromEnv());                  // eager value
    bind<Api>().toProvide(() => Api(currentScope.resolve<Config>())).singleton(); // lazy, one per scope
    bind<Repo>().toProvide(() => Repo(currentScope.resolve<Api>()));               // new per resolve
    bind<User>().toProvideWithParams((p) => User(p as String));                   // resolve(params: 'id')
    bind<Db>().toProvideAsync(() async => Db.open()).singleton();                 // resolveAsync only
    bind<Report>().toProvideAsyncWithParams((p) async => Report.load(p as int));
    bind<Api>().withName('mock').toProvide(() => MockApi());                      // resolve(named: 'mock')
    bind<Env>().toInstance(loadEnv()); // a Future is fine here: resolve with resolveAsync<Env>()
  }
}
```

Facts confirmed by running 4.0.0:

| Binding | Behaviour |
|---|---|
| `toInstance(v)` | `v` is evaluated when the module is installed. `.singleton()` on it does nothing. |
| `toProvide(f)` | `f` runs on every `resolve`. |
| `toProvide(f).singleton()` | `f` runs on first resolve, then cached in the declaring scope. |
| `toProvideWithParams(f).singleton()` | “master singleton”: the first call's params win; `resolve(params: 1)` then `resolve(params: 2)` both return the instance built with `1`. |
| `toProvideAsync(f)` | `f` must be `Future<T> Function()`; a sync closure is a compile error in 4.x. |
| async singleton that throws | the failure is **not** cached; the next `resolveAsync` retries the factory. |
| `resolve<T>()` on an async binding | throws `StateError: Provider returns Future<T>. Use resolveAsync() instead.` |
| missing binding | `resolve` throws `StateError`; `tryResolve` returns `null`. |

Resolve API on `Scope`:

```dart
T resolve<T>({String? named, dynamic params});
T? tryResolve<T>({String? named, dynamic params});
Future<T> resolveAsync<T>({String? named, dynamic params});
Future<T?> tryResolveAsync<T>({String? named, dynamic params});
```

`params` is `dynamic` — pass a record, a map or a small value class and cast in
the factory.

## Disposal and ownership

- Any resolved value that implements `Disposable` (`FutureOr<void> dispose()`)
  is tracked by the scope **whose binding created it**, and disposed when that
  scope is disposed.
- Order inside `dispose()`: child scopes first (recursively), then the scope's
  own tracked disposables in creation order, then modules and bindings are cleared.
- Resolving a parent's binding through a child does not move ownership: the
  instance lives until the parent is disposed.
- A non-singleton `Disposable` binding in a long-lived scope tracks one instance
  per resolve until that scope closes. Put such bindings in a scope whose
  lifetime matches the resource, or make them `.singleton()`.

## Cycle detection

Off by default. Without it a dependency cycle ends in `StackOverflowError`.

```dart
// Before opening scopes, typically under kDebugMode or in tests:
CherryPick.enableGlobalCycleDetection();              // within one scope
CherryPick.enableGlobalCrossScopeCycleDetection();    // across parent/child scopes

// Or per scope:
final scope = CherryPick.openSafeRootScope();         // root with detection on
scope.enableCycleDetection();
```

A detected cycle throws `CircularDependencyException` whose message contains
the chain, e.g. `Dependency chain: A -> B -> A`. Detection costs time on every
resolve; keep it to debug builds and tests unless the user wants otherwise.

## Observers

```dart
CherryPick.setGlobalObserver(PrintCherryPickObserver()); // before openRootScope()
```

- Default is `SilentCherryPickObserver` (no-op, and it enables a fast path).
- Custom observers must `implements CherryPickObserver` and implement all 14
  callbacks (`onBindingRegistered`, `onInstanceRequested`, `onInstanceCreated`,
  `onInstanceDisposed`, `onModulesInstalled`, `onModulesRemoved`,
  `onScopeOpened`, `onScopeClosed`, `onCycleDetected`, `onCacheHit`,
  `onCacheMiss`, `onDiagnostic`, `onWarning`, `onError`).
  **Do not** `extends SilentCherryPickObserver`: scopes detect it with `is` and
  skip every callback.
- For Talker use `TalkerCherryPickObserver(talker)` from `talker_cherrypick_logger`.

## Testing

```dart
setUp(() {
  CherryPick.openRootScope().installModules([FakeApiModule(), RepoModule()]);
});

tearDown(() async {
  await CherryPick.closeRootScope(); // fresh root for the next test
});
```

- Overriding: within one scope the module installed **later** wins for the same
  type and name; a child scope's binding shadows the parent's. So either install
  the fake module after the real one, or install it into a child scope.
- Enable cycle detection in test setup to turn stack overflows into readable
  exceptions.
