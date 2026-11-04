# Migrating from cherrypick 3.x to 4.0.0

Only the `cherrypick` core package has breaking changes. `cherrypick_annotations`,
`cherrypick_generator`, `cherrypick_flutter` and `talker_cherrypick_logger` keep
their API, but bump all of them to `^4.0.0` together. Everyday
`bind<T>().toProvide(...)` / `.toInstance(...)` code is unaffected.

| Area | 3.x | 4.0.0 |
|---|---|---|
| `ProviderFactory<T>` | `FutureOr<T> Function()` | `T Function()` (sync only) |
| `Instance<T>`, `ProviderWithParams<T>` | typedefs | removed |
| `toProvideAsync` / `toProvideAsyncWithParams` | loose aliases of `toProvide` | require a `Future`-returning factory |
| `InstanceResolver`, `ProviderResolver` | exported | not exported; only `BindingResolver<T>` and the factory typedefs |
| `toInstanceAsync` | normal | `@Deprecated` — use `toInstance` |
| failed async singleton | error cached and replayed | not cached; next `resolveAsync` retries |

New public typedefs:

```dart
typedef ProviderFactory<T> = T Function();
typedef ProviderFactoryWithParams<T> = T Function(dynamic);
typedef AsyncProviderFactory<T> = Future<T> Function();
typedef AsyncProviderFactoryWithParams<T> = Future<T> Function(dynamic);
```

## Mechanical fixes

```dart
// Instance<T> was a value alias of FutureOr<T>
Instance<MyService> v = MyService();           // 3.x
FutureOr<MyService> v = MyService();           // 4.x

ProviderWithParams<User> f = (p) => User(p);   // 3.x
ProviderFactoryWithParams<User> f = (p) => User(p); // 4.x

bind<Db>().toProvideAsync(() => openDbSync()); // 3.x accepted, 4.x compile error
bind<Db>().toProvide(() => openDbSync());      // 4.x: sync factory
bind<Db>().toProvideAsync(() async => openDb()); // 4.x: async factory

bind<Env>().toInstanceAsync(loadEnv());        // 3.x
bind<Env>().toInstance(loadEnv());             // 4.x, resolve with resolveAsync<Env>()
```

Code that implemented or referenced `InstanceResolver`/`ProviderResolver`
should switch to the `bind<T>()` builder methods.

## Checklist

1. Bump every `cherrypick*` and `talker_cherrypick_logger` dependency to `^4.0.0`.
2. Run `dart analyze`; fix `toProvideAsync` closures that return a non-`Future`
   and references to removed typedefs.
3. Replace `toInstanceAsync` with `toInstance`.
4. Re-run `dart run build_runner build` so generated modules are rebuilt by
   `cherrypick_generator` 4.x.
5. If code relied on a failed async singleton staying failed, add explicit
   handling: 4.x retries the provider on the next `resolveAsync`.
6. Add `cherrypick_lint: ^4.0.0` to `analysis_options.yaml` `plugins:` (Dart >=3.10).
