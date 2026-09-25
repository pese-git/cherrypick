# Benchmark Comparison: cherrypick resolution optimizations

Measures the effect of the Scope resolution work (`d61ff7c`: incremental index,
silent-observer guard, direct-resolve fast path, type-specialized resolvers)
against the commit immediately before it (`f82b96c`).

Both sides are measured with the **current** benchmark apparatus. The previous
revision of this file compared numbers taken with the old apparatus, where
`named` and `registerLazySingleton` were reported as "18× faster" and "16.3×
faster" — those rows compared single outliers in a distribution of zeros, since
timing resolution was coarser than the operation being timed. See
[METHODOLOGY.md](METHODOLOGY.md).

## Methodology

- **Runtime:** AOT (`dart compile exe`). Both binaries built from the same
  benchmark sources; only `cherrypick/lib` differs.
- **cherrypick cycle detection:** off (library default, required by the fast path).
- **Parameters:** chainCount=100, nestingDepth=100, repeat=31, warmup=5,
  firstResolve phase, one process per scenario.
- **Statistic:** median nanoseconds over 31 samples.

## Results (median, ns)

| Scenario | before (f82b96c) | after (d61ff7c…) | speed-up |
|---|---|---|---|
| registerLazySingleton | 1000.0 | 83.0 | 12.0× |
| named | 958.0 | 83.0 | 11.5× |
| override | 3625.0 | 416.0 | 8.7× |
| chainLazySingleton | 17292.0 | 7500.0 | 2.3× |
| chainFactory | 14292.0 | 6833.0 | 2.1× |
| chainAsync | 120958.0 | 28125.0 | 4.3× |

The chain scenarios — where the container constructs 100 objects per resolve —
improve by roughly 2×. The shallow scenarios improve by an order of magnitude,
which is consistent with the change removing per-resolve overhead (observer
callbacks, diagnostic map allocations, runtime `FutureOr` branching) rather than
speeding up construction itself: the fewer objects a resolve builds, the larger
the share that overhead occupied.

## What changed

1. **Type-specialized resolvers.** `ProviderResolver<T>` split into sync/async ×
   params/no-params classes, selected by `is` checks at binding creation instead
   of runtime `FutureOr` branching on every resolve.
2. **Direct-resolve fast path.** `_canUseDirectResolvePath` skips observer
   callbacks and cycle-detection wrappers when the observer is silent and both
   cycle detectors are off. This is why the `cycle detection on` column in
   [REPORT_v2.md](REPORT_v2.md) is 6–20× slower: with detection enabled this path
   is unavailable.
3. **Silent-observer guard.** Diagnostic calls wrapped in `if (!_isSilentObserver)`,
   removing `Map<String, dynamic>` allocations and string interpolation from
   scope creation.
4. **Incremental index update.** `installModules()` adds each module to the
   existing index instead of rebuilding all M×B entries.
5. **`bool _isCached` flag.** Replaces `_cache != null`, which also fixes caching
   of nullable singletons.
6. **Dispose loop cleanup.** `.toList()` instead of cloning map/set collections.

Per-change contributions were not measured — these are the changes present in the
diff, not an attribution of the speed-up between them.
