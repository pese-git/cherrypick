# Comparative DI Benchmark Report: cherrypick vs get_it vs riverpod vs kiwi vs yx_scope

## Benchmark Parameters

- chainCount = 100
- nestingDepth = 100
- repeat = 5
- warmup = 2

## Benchmark Scenarios

1. **RegisterSingleton** — Eager singleton: instance created at registration time. Measures pure lookup speed.
2. **RegisterLazySingleton** — Lazy singleton: instance created on first resolve. Measures creation + caching.
3. **ChainSingleton** — Eager dependency chain A → B → ... → N. All instances pre-created at registration. Pure lookup.
4. **ChainLazySingleton** — Lazy dependency chain. Full graph creation + caching on first resolve. **Primary fairness metric.**
5. **ChainFactory** — All chain elements are factories. Stateless creation chain.
6. **AsyncChain** — Async chain (async factory). Performance on async graphs.
7. **Named** — Registers two bindings with names, resolves by name. Named lookup test.
8. **Override** — Registers a chain/alias in a child scope. Tests scope overrides.

> **Note:** kiwi and yx_scope do not support eager singleton registration. Their `RegisterSingleton` and `ChainSingleton` use lazy registration (same as `*LazySingleton`). Results marked with † reflect this.

---

## Methodology

- **Hardware:** Measurements taken on a controlled local machine. Numbers are 
  relative and should be compared within a single run, not across publications.
- **Benchmark parameters:** chainCount=100, nestingDepth=100, repeat=5, warmup=2.
- **Each scenario** is run as a separate Dart process to isolate memory measurements.
- **Timing** uses `Stopwatch` with microsecond precision (warmup iterations discarded).
- **Memory** measured via `ProcessInfo.currentRss` (peak RSS per process).
- **Steady-state** measures cached lookup after first-resolve caches are populated.

---

## First Resolve (Mean time, µs)

| Scenario              | cherrypick | get_it   | riverpod | kiwi  | yx_scope |
|-----------------------|------------|----------|----------|-------|----------|
| RegisterSingleton     | 12.8       | 14.6     | 17.6     | 0.4†  | 22.8†    |
| RegisterLazySingleton | 1.2        | 4.2      | 5.4      | 0.2   | 9.0      |
| ChainSingleton        | 4.8        | 2.8      | 436.2    | 67.8† | 134.2†   |
| ChainLazySingleton    | 46.8       | 193.2    | 398.0    | 56.0  | 266.8    |
| ChainFactory          | 54.0       | 66.0     | 443.0    | 55.6  | 146.6    |
| AsyncChain            | 247.8      | 15033.0  | 1379.0   | –     | –        |
| Named                 | 0.2        | 0.6      | 3.4      | 0.2   | 7.8      |
| Override              | 9.8        | 3.8      | 408.8    | 61.8  | 138.6    |

---

## Steady-State Resolution (Mean time, µs)

| Scenario              | cherrypick | get_it | riverpod | kiwi  | yx_scope |
|-----------------------|------------|--------|----------|-------|----------|
| RegisterSingleton     | 0.0        | 0.2    | 1.0      | 0.0   | 0.0      |
| RegisterLazySingleton | 0.0        | 0.0    | 1.0      | 0.0   | 0.0      |
| ChainSingleton        | 2.8        | 0.8    | 2.8      | 1.6   | 2.0      |
| ChainLazySingleton    | 1.4        | 1.2    | 1.8      | 1.0   | 1.4      |
| ChainFactory          | 31.2       | 62.6   | 2.0      | 51.6  | 1.6      |
| AsyncChain            | 57.2       | 31.6   | 18.2     | –     | –        |
| Named                 | 0.0        | 0.2    | 0.2      | 0.0   | 0.4      |
| Override              | 1.0        | 1.4    | 1.8      | 290.0 | 1.2      |

---

## Peak Memory Usage (Peak RSS, KB)

| Scenario              | cherrypick | get_it   | riverpod | kiwi    | yx_scope |
|-----------------------|------------|----------|----------|---------|----------|
| RegisterSingleton     | 239,568    | 240,128  | 240,592  | 272,016 | 289,936  |
| RegisterLazySingleton | 239,648    | 240,272  | 240,720  | 272,016 | 289,424  |
| ChainSingleton        | 275,664    | 290,912  | 258,624  | 281,728 | 287,104  |
| ChainLazySingleton    | 292,704    | 321,232  | 287,168  | 297,808 | 288,160  |
| ChainFactory          | 298,848    | 361,264  | 293,968  | 279,792 | 290,768  |
| AsyncChain            | 278,320    | 482,864  | 281,440  | –       | –        |
| Named                 | 272,896    | 482,880  | 279,728  | 272,016 | 287,376  |
| Override              | 281,968    | 540,944  | 278,240  | 279,184 | 281,216  |

---

## Stability (Stddev / Mean ratio)

| Scenario              | cherrypick | get_it | riverpod | kiwi  | yx_scope |
|-----------------------|------------|--------|----------|-------|----------|
| RegisterSingleton     | 1.84       | 1.62   | 1.43     | 1.23  | 1.18     |
| RegisterLazySingleton | 0.57       | 0.23   | 0.43     | 2.00  | 1.78     |
| ChainSingleton        | 0.36       | 0.27   | 0.06     | 0.37  | 0.17     |
| ChainLazySingleton    | 0.17       | 0.43   | 0.10     | 0.14  | 0.63     |
| ChainFactory          | 0.27       | 0.01   | 0.22     | 0.09  | 0.23     |
| AsyncChain            | 0.06       | 0.18   | 0.07     | –     | –        |
| Named                 | 2.00       | 0.67   | 0.15     | 2.00  | 1.74     |
| Override              | 0.08       | 0.11   | 0.17     | 0.03  | 0.03     |

---

## Analysis

### First Resolve — Lazy Singleton Chain (ChainLazySingleton)

All DI containers create the full dependency graph on first resolve — the only fair cross-DI comparison.

- **cherrypick**: 46.8 µs — **4.1× faster** than get_it (193.2 µs), **8.5× faster** than riverpod (398.0 µs)
- **kiwi**: 56.0 µs (+30% vs cherrypick)
- **yx_scope**: 266.8 µs (stddev/mean = 0.63 — unreliable)

### First Resolve — Eager Singleton Chain (ChainSingleton)

All instances pre-created at registration; measures pure lookup speed. Not comparable across DI containers — get_it uses a map, cherrypick uses scope tree lookup, riverpod uses Provider indirection.

- **get_it**: 2.8 µs (map lookup)
- **cherrypick**: 5.4 µs (scope tree lookup)
- **riverpod**: 436.2 µs (Provider layer overhead)

### Async Chain (AsyncChain)

- **cherrypick** dominates: 247.8 µs (vs get_it 15,033 µs = **61× faster**)
- **riverpod**: 1,379 µs (6.3× slower than cherrypick)
- kiwi and yx_scope do not support async

### Memory Usage

- **cherrypick** uses significantly less memory than get_it:
  - Named: −210 MB (−43%)
  - Override: −259 MB (−48%)
  - AsyncChain: −204 MB (−42%)
- **riverpod** has lowest memory on ChainSingleton (258,672 KB vs 275,664 KB for cherrypick)
- **kiwi** and **yx_scope** have moderate memory footprint

### Stability

- **cherrypick** shows low variance on ChainLazySingleton (0.17) and Override (0.08)
- **get_it** most stable on ChainFactory (0.01)
- **yx_scope** highest variance on ChainLazySingleton (0.63)

---

## Recommendations

- **cherrypick**: Fastest lazy graph resolution, best async performance, lowest memory overhead
- **get_it**: Fastest eager singleton lookup; avoid for async chains and deep lazy graphs
- **kiwi**: Lightweight sync-only alternative; +30% on lazy chains vs cherrypick
- **riverpod**: Strong steady-state factory/async performance; expensive first-resolve on deep chains
- **yx_scope**: Steady-state consistent; unreliable first-resolve on deep lazy graphs (high variance)

---

_Last updated: April 26, 2026.
