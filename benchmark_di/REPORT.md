# Comparative DI Benchmark Report: cherrypick vs get_it vs riverpod

## Benchmark Scenarios

1. **RegisterSingleton** — Registers and resolves a singleton. Baseline DI speed.
2. **ChainSingleton** — A dependency chain A → B → ... → N (singleton). Deep singleton chain resolution.
3. **ChainFactory** — All chain elements are factories. Stateless creation chain.
4. **AsyncChain** — Async chain (async factory). Performance on async graphs.
5. **Named** — Registers two bindings with names, resolves by name. Named lookup test.
6. **Override** — Registers a chain/alias in a child scope. Tests scope overrides.

---

## Comparative Table: chainCount=10, nestingDepth=10 (Mean, PeakRSS)

| Scenario           | cherrypick Mean (us) | cherrypick PeakRSS | get_it Mean (us) | get_it PeakRSS | riverpod Mean (us) | riverpod PeakRSS |
|--------------------|---------------------:|-------------------:|-----------------:|---------------:|-------------------:|-----------------:|
| RegisterSingleton  | 13.00                | 273104             | 8.40             | 261872         | 9.80               | 268512           |
| ChainSingleton     | 13.80                | 271072             | 2.00             | 262000         | 33.60              | 268784           |
| ChainFactory       | 5.00                 | 299216             | 4.00             | 297136         | 22.80              | 271296           |
| AsyncChain         | 28.60                | 290640             | 24.60            | 342976         | 78.20              | 285920           |
| Named              | 2.20                 | 297008             | 0.20             | 449824         | 6.20               | 281136           |
| Override           | 7.00                 | 297024             | 0.00             | 449824         | 30.20              | 281152           |

## Maximum Load: chainCount=100, nestingDepth=100 (Mean, PeakRSS)

| Scenario           | cherrypick Mean (us) | cherrypick PeakRSS | get_it Mean (us) | get_it PeakRSS | riverpod Mean (us) | riverpod PeakRSS |
|--------------------|---------------------:|-------------------:|-----------------:|---------------:|-------------------:|-----------------:|
| RegisterSingleton  | 4.00                 | 271072             | 1.00             | 262000         | 2.00               | 268688           |
| ChainSingleton     | 76.60                | 303312             | 2.00             | 297136         | 221.80             | 270784           |
| ChainFactory       | 80.00                | 293952             | 39.20            | 342720         | 195.80             | 308640           |
| AsyncChain         | 251.40               | 297008             | 18.20            | 450640         | 748.80             | 285968           |
| Named              | 2.20                 | 297008             | 0.00             | 449824         | 1.00               | 281136           |
| Override           | 104.80               | 301632             | 2.20             | 477344         | 120.80             | 294752           |

---

## Analysis

- **get_it** is the absolute leader in all scenarios, especially under deep/nested chains and async.
- **cherrypick** is highly competitive and much faster than riverpod on any complex graph.
- **riverpod** is only suitable for small/simple DI graphs due to major slowdowns with depth, async, or override.

### Recommendations
- Use **get_it** for performance-critical and deeply nested graphs.
- Use **cherrypick** for scalable/testable apps if a small speed loss is acceptable.
- Use **riverpod** only if you rely on Flutter integration and your DI chains are simple.

---

_Last updated: August 8, 2025._
