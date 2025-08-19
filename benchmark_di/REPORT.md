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

| Scenario         | cherrypick | get_it | riverpod | kiwi |
|------------------|------------|--------|----------|------|
| chainSingleton   | 47.6       | 13.0   | 389.6    | 46.8 |
| chainFactory     | 93.6       | 68.4   | 678.4    | 40.8 |
| register         | 67.4       | 10.2   | 242.2    | 56.2 |
| named            | 14.2       | 10.6   | 10.4     | 8.2  |
| override         | 42.2       | 11.2   | 302.8    | 44.6 |
| chainAsync       | 519.4      | 38.0   | 886.6    | –    |

---

## Analysis

- **get_it** and **kiwi** are the fastest in most sync scenarios; cherrypick is solid, riverpod is much slower for deep chains.
- **Async scenarios**: Only cherrypick, get_it and riverpod are supported; get_it is much faster. Kiwi does not support async.
- **Named** lookups are fast in all DI.
- **Riverpod** loses on deeply nested/async chains.
- **Memory/peak usage** varies, but mean_us is the main comparison (see raw results for memory).

### Recommendations
- Use **get_it** or **kiwi** for maximum sync performance and simplicity.
- Use **cherrypick** for robust, scalable and testable setups — with a small latency cost.
- Use **riverpod** only for Flutter apps where integration is paramount and chains are simple.

---

_Last updated: August 19, 2025._
_Please see scenario source for details._
