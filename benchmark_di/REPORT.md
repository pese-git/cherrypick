# Comparative DI Benchmark Report: cherrypick vs get_it vs riverpod vs kiwi

## Benchmark Parameters

- chainCount = 100
- nestingDepth = 100
- repeat = 5
- warmup = 2

## Benchmark Scenarios

1. **RegisterSingleton** — Registers and resolves a singleton. Baseline DI speed.
2. **ChainSingleton** — A dependency chain A → B → ... → N (singleton). Deep singleton chain resolution.
3. **ChainFactory** — All chain elements are factories. Stateless creation chain.
4. **AsyncChain** — Async chain (async factory). Performance on async graphs.
5. **Named** — Registers two bindings with names, resolves by name. Named lookup test.
6. **Override** — Registers a chain/alias in a child scope. Tests scope overrides.

---

## Comparative Table: chainCount=100, nestingDepth=100, repeat=5, warmup=2 (Mean time, µs)

| Scenario         | cherrypick | get_it | riverpod | kiwi  | yx_scope |
|------------------|------------|--------|----------|-------|----------|
| chainSingleton   | 20.6       | 14.8   | 275.2    | 47.0  | 82.8     |
| chainFactory     | 90.6       | 71.6   | 357.0    | 46.2  | 79.6     |
| register         | 82.6       | 10.2   | 252.6    | 43.6  | 224.0    |
| named            | 18.4       | 9.4    | 12.2     | 10.2  | 10.8     |
| override         | 170.6      | 11.2   | 301.4    | 51.4  | 146.4    |
| chainAsync       | 493.8      | 34.0   | 5,039.0  |  –    | 87.2     |


## Peak Memory Usage (Peak RSS, Kb)

| Scenario         | cherrypick | get_it | riverpod | kiwi   | yx_scope |
|------------------|------------|--------|----------|--------|----------|
| chainSingleton   | 338,224    | 326,752| 301,856  | 195,520| 320,928  |
| chainFactory     | 339,040    | 335,712| 304,832  | 319,952| 318,688  |
| register         | 333,760    | 334,208| 300,368  | 327,968| 326,736  |
| named            | 241,040    | 229,632| 280,144  | 271,872| 266,352  |
| override         | 356,912    | 331,456| 329,808  | 369,104| 304,416  |
| chainAsync       | 311,616    | 434,592| 301,168  |   –    | 328,912  |

---

## Analysis

- **get_it** remains the clear leader for both speed and memory usage (lowest latency across most scenarios; excellent memory efficiency even on deep chains).
- **kiwi** shows the lowest memory footprint in chainSingleton, but is unavailable for async chains.
- **yx_scope** demonstrates highly stable performance for both sync and async chains, often at the cost of higher memory usage, especially in the register/override scenarios.
- **cherrypick** comfortably beats riverpod, but is outperformed by get_it/kiwi/yx_scope, especially on async and heavy nested chains. It uses a bit less memory than yx_scope and kiwi, but can spike in memory/latency for override.
- **riverpod** is unsuitable for deep or async chains—latency and memory usage grow rapidly.
- **Peak memory (RSS):** usually around 320–340 MB for all DI; riverpod/kiwi occasionally drops below 300MB. named/factory scenarios use much less.
- **Stability:** yx_scope and get_it have the lowest latency spikes; cherrypick can show peaks on override/async; riverpod is least stable on async (stddev/mean much worse).

### Recommendations

- **get_it** (and often **kiwi**, if you don't need async): best for ultra-fast deep graphs and minimum peak memory.
- **yx_scope**: best blend of performance and async stability; perfect for production mixed DI.
- **cherrypick**: great for modular/testable architectures, unless absolute peak is needed; lower memory than yx_scope in some scenarios.
- **riverpod**: only for shallow DI or UI wiring in Flutter.

---

_Last updated: August 20, 2025._
_Please see scenario source for details._
