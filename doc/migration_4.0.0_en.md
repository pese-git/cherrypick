# Migration guide: cherrypick 3.x → 4.0.0

Version 4.0.0 finalizes the resolver/provider public API of the `cherrypick`
core package. The changes below are **breaking** for code that referenced the
old provider typedefs directly or relied on `toProvideAsync` being a loose
alias of `toProvide`. Everyday `bind<T>().toProvide(...)` / `.toInstance(...)`
usage is unaffected.

> Only the `cherrypick` core package changed. `cherrypick_flutter`,
> `cherrypick_generator`, `cherrypick_annotations` and `talker_cherrypick_logger`
> keep their existing public surface.

## Summary of breaking changes

| Area | 3.x | 4.0.0 |
| --- | --- | --- |
| Provider factory typedef | `ProviderFactory<T> = FutureOr<T> Function()` | `ProviderFactory<T> = T Function()` (strictly sync) |
| Removed typedefs | `Instance<T>`, `ProviderWithParams<T>` | removed — use `FutureOr<T>` and the new factory typedefs |
| Async providers | `toProvideAsync` was a deprecated alias of `toProvide` | strictly async: requires `Future<T> Function()` / `Future<T> Function(dynamic)` |
| Concrete resolvers | `InstanceResolver`, `ProviderResolver` were exported | no longer exported — only `BindingResolver` + factory typedefs are public |
| `toInstanceAsync` | available | **deprecated** — use `toInstance` (it accepts `FutureOr<T>`) |

## New public typedefs

```dart
typedef ProviderFactory<T>              = T Function();
typedef ProviderFactoryWithParams<T>    = T Function(dynamic);
typedef AsyncProviderFactory<T>         = Future<T> Function();
typedef AsyncProviderFactoryWithParams<T> = Future<T> Function(dynamic);
```

## Step-by-step

### 1. Removed typedefs `Instance<T>` and `ProviderWithParams<T>`

If you referenced these directly (rare), replace them:

```dart
// Before — Instance<T> was an alias of FutureOr<T> (a value, not a function)
Instance<MyService> value = MyService();
ProviderWithParams<User> factory = (params) => User(params);

// After — use FutureOr<T> / the new factory typedefs
FutureOr<MyService> value = MyService();
ProviderFactoryWithParams<User> factory = (params) => User(params);
```

### 2. `ProviderFactory<T>` is now synchronous only

`ProviderFactory<T>` used to allow returning a `Future`. It is now
`T Function()`. For asynchronous factories use `AsyncProviderFactory<T>`
(`Future<T> Function()`) instead.

### 3. `toProvideAsync` / `toProvideAsyncWithParams` are strictly async

These are no longer aliases of `toProvide`; they now require a factory that
returns a `Future`:

```dart
// Still valid — the closure returns a Future
bind<Db>().toProvideAsync(() async => await openDb());

// Was accidentally accepted in 3.x, now a type error — this factory is sync:
bind<Db>().toProvideAsync(() => openDbSync()); // ❌
// Use toProvide for sync factories:
bind<Db>().toProvide(() => openDbSync());      // ✅
```

Resolve async providers with `resolveAsync<T>()` / `tryResolveAsync<T>()`.

### 4. `InstanceResolver` / `ProviderResolver` are no longer exported

Only `BindingResolver<T>` and the factory typedefs are part of the public API.
If you implemented or referenced the concrete resolver classes, migrate to the
`bind<T>()` builder methods (`toInstance`, `toProvide`, `toProvideWithParams`,
`toProvideAsync`, `toProvideAsyncWithParams`).

### 5. `toInstanceAsync` is deprecated

`toInstance` already accepts `FutureOr<T>`, so an already-running `Future` can
be registered with it directly:

```dart
// Before
bind<Environment>().toInstanceAsync(loadEnvironment());

// After
bind<Environment>().toInstance(loadEnvironment()); // resolve with resolveAsync
```

## Behavioral change: async singleton retries after failure

In 3.x, if an async singleton provider threw during its first initialization,
the failed result was cached and every later `resolveAsync` replayed the same
error. In 4.0.0 a failed async singleton initialization is not cached, so a
subsequent `resolveAsync` retries the provider.
