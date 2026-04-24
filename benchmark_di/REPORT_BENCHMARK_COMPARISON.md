# Benchmark Comparison: cherrypick Performance Improvements

## Parameters

- chainCount = 100
- nestingDepth = 100
- repeat = 5
- warmup = 2

---

## Results: firstResolve (Mean, µs)

### Lazy Singleton Scenarios (fair cross-DI comparison)

| Scenario              | BR-improvements | develop | Improvement (vs develop) |
|-----------------------|-----------------|---------|--------------------------|
| ChainLazySingleton    | 46.80           | 114.20  | **2.4× faster**          |
| ChainFactory          | 54.00           | 105.60  | **2.0× faster**          |
| AsyncChain            | 247.80          | 959.20  | **3.9× faster**          |
| Named                 | 0.20            | 3.60    | **18× faster**           |
| Override              | 9.80            | 110.40  | **11.3× faster**         |
| RegisterLazySingleton | 1.20            | 19.60   | **16.3× faster**         |

### Eager Singleton Scenarios (pure lookup speed)

| Scenario              | BR-improvements | develop | Note |
|-----------------------|-----------------|---------|------|
| ChainSingleton        | 4.80            | 114.20  | Not comparable — see note below |
| RegisterSingleton     | 12.80           | 19.60   | **1.5× faster** |

> **Important:** `develop` did not distinguish between eager and lazy singletons. Its "singleton" was always lazy (instance created on first resolve). The develop `ChainSingleton` value (114.2 µs) measures the same thing as BR-improvements `ChainLazySingleton` (46.8 µs). The `ChainSingleton` eager column in BR-improvements (4.8 µs) measures pure lookup after `.toInstance()` eager registration — a fundamentally different operation. Fair comparison: 114.2 → 46.8 = 2.4× faster.

\* All measurements taken on the same hardware with identical benchmark parameters.

---

## Steady-State Comparison

Steady-state measurements are not directly comparable because `develop` lacked a
steady-state measurement phase (its values are first-resolve only). BR-improvements
introduced a separate steady-state phase to isolate cached lookup performance.

---

## Summary

The `BR-improvements` branch shows performance improvements on first resolve vs the `develop` baseline:

- **ChainLazySingleton**: 2.4× faster (46.8 µs vs 114.2 µs)
- **ChainFactory**: 2.0× faster (54.0 µs vs 105.6 µs)
- **AsyncChain**: 3.9× faster (247.8 µs vs 959.2 µs)
- **Named**: 18× faster (0.2 µs vs 3.6 µs)
- **Override**: 11.3× faster (9.8 µs vs 110.4 µs)
- **RegisterLazySingleton**: 16.3× faster (1.2 µs vs 19.6 µs)

Steady-state is not directly comparable because `develop` lacked a steady-state measurement phase.

### What exactly was changed and why it got faster

> **Note:** The following describes architectural changes and their expected impact. 
> Specific percentage contributions have not been measured via isolated A/B tests.

---

#### 1. Split monolithic resolvers into type-specialized classes
**What changed:** The single `ProviderResolver<T>` class (which handled sync/async/param/ no-param in one place with runtime type checks) was split into four dedicated classes:
- `SyncProviderResolver<T>` / `SyncProviderWithParamsResolver<T>`
- `AsyncProviderResolver<T>` / `AsyncProviderWithParamsResolver<T>`

`ProviderResolver.create()` uses fast-path `is` checks to pick the correct implementation immediately, without calling the provider. A lazy fallback `FutureOrProviderResolver` is used only when the static type is genuinely unknown.

Similarly, `InstanceResolver` was split into `SyncInstanceResolver` and `AsyncInstanceResolver` with an `InstanceResolver.create()` factory.

**Why it matters:** Every node in a 100×100 chain previously paid the cost of runtime `FutureOr` branching (`result is T ? sync : async`) on every resolve. Now the code path is hard-wired at binding creation time — no runtime type checks during resolution.

**Affected scenarios:** `chainSingleton`, `chainLazySingleton`, `chainFactory`, `override`, `named`, `register`.

---

#### 2. Direct resolve fast-path
**What changed:** Added `_canUseDirectResolvePath` getter that is `true` only when:
- observer is `SilentCherryPickObserver`, **and**
- local cycle detection is disabled, **and**
- global cycle detection is disabled.

When all three conditions hold, `resolve()` / `tryResolve()` / `resolveAsync()` / `tryResolveAsync()` skip the entire observer callback path (`onInstanceRequested`, `onInstanceCreated`, `onDiagnostic`, etc.) and cycle-detection wrappers entirely. They call `_tryResolveInternal` directly.

**Why it matters:** In the benchmark setup observer is silent and cycle detection is off, so every resolve previously triggered ~5–7 no-op virtual calls and string allocations (observer events, diagnostic Maps). That overhead is now completely bypassed.

**Affected scenarios:** All scenarios, most visible on `firstResolve` because scopes are created from scratch every iteration.

---

#### 3. Silent observer guard
**What changed:** All diagnostic calls (`observer.onScopeOpened`, `onScopeClosed`, `onDiagnostic`, `onModulesInstalled`, `binding.logAllDeferred()`) are now wrapped in `if (!_isSilentObserver)`. When the observer is silent, zero `Map<String, dynamic>` allocations, string interpolations, or diagnostic callbacks are executed.

**Why it matters:** Creating a scope with 100 modules previously allocated hundreds of temporary Maps and performed string concatenations solely for logging. That work is now entirely skipped.

**Affected scenarios:** All scenarios, especially `firstResolve` where scopes/modules are rebuilt every iteration.

---

#### 4. Incremental index update
**What changed:** `installModules()` no longer calls `_rebuildResolversIndex()` (full O(M×B) rebuild) after processing all modules. Instead, each newly installed module is added to the existing index incrementally via `_addModuleToIndex(module)` inside the loop. `_rebuildResolversIndex()` is now only called from `dropModules()`.

**Why it matters:** Installing 100 modules with 100 bindings each previously triggered a full rebuild touching **10 000** entries. Now only the 100 new entries are inserted.

**Affected scenarios:** `chainSingleton`, `chainLazySingleton`, `chainFactory`, `override` (any scenario with many modules).

---

#### 5. `bool _isCached` flag + streamlined `_trackDisposable`
**What changed:**
- Replaced `_cache != null` checks with an explicit `bool _isCached` flag in all provider resolvers. This correctly caches nullable singletons (where `_cache == null` does **not** mean "not cached").
- `_trackDisposable` removed the `!_disposables.contains(obj)` guard; it now simply calls `_disposables.add(obj)`.
- `_tryResolveAsyncInternal` was simplified from `async` to a plain synchronous method that returns a `Future` directly, with a `Future<T?>.value(null)` fallback.

**Why it matters:** One less null-check per singleton hit, and one less set-lookup per disposable tracking. The async path no longer pays for an extra `async` frame.

**Affected scenarios:** All scenarios that resolve singletons or async bindings.

---

#### 6. Dispose loop cleanup
**What changed:** In `dispose()`:
- `Map<String, Scope>.from(_scopeMap)` → `_scopeMap.values.toList()`
- `Set<Disposable>.from(_disposables)` → `_disposables.toList()`

**Why it matters:** Avoids cloning the map/set collections during teardown; `.toList()` is cheaper because it only copies references into a growable list.

**Affected scenarios:** All scenarios that create and tear down scopes.

---

### Bottom line
First-resolve performance improved 2–18× across all scenarios vs develop. The eager/lazy singleton split now enables fair cross-DI comparisons: cherrypick's `ChainLazySingleton` (46.8 µs) is 2.4× faster than develop's equivalent (114.2 µs).
