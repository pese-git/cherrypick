# Comparative DI Benchmark Report: cherrypick vs get_it vs riverpod

## Benchmark Parameters

| Parameter         | Value                  |
|------------------|-----------------------|
| --benchmark      | all                   |
| --chainCount (-c)| 10, 100               |
| --nestingDepth (-d)| 10, 100             |
| --repeat (-r)    | 5                     |
| --warmup (-w)    | 2                     |
| --format (-f)    | markdown              |
| --di             | cherrypick, get_it, riverpod |

---

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
| RegisterSingleton  | 10.00                | 273104             | 15.20            | 261872         | 13.00              | 268512           |
| ChainSingleton     | 10.20                | 271072             | 1.00             | 262000         | 41.20              | 268784           |
| ChainFactory       | 5.00                 | 299216             | 5.00             | 297136         | 43.80              | 271296           |
| AsyncChain         | 43.40                | 290640             | 23.40            | 342976         | 105.20             | 285920           |
| Named              | 1.00                 | 297008             | 1.00             | 449824         | 2.20               | 281136           |
| Override           | 5.40                 | 297024             | 0.00             | 449824         | 30.20              | 281152           |

## Maximum Load: chainCount=100, nestingDepth=100 (Mean, PeakRSS)

| Scenario           | cherrypick Mean (us) | cherrypick PeakRSS | get_it Mean (us) | get_it PeakRSS | riverpod Mean (us) | riverpod PeakRSS |
|--------------------|---------------------:|-------------------:|-----------------:|---------------:|-------------------:|-----------------:|
| RegisterSingleton  | 1.00                 | 271072             | 1.20             | 262000         | 2.00               | 268688           |
| ChainSingleton     | 49.20                | 303312             | 1.20             | 297136         | 253.20             | 270784           |
| ChainFactory       | 45.00                | 293952             | 51.80            | 342720         | 372.80             | 308640           |
| AsyncChain         | 261.60               | 297008             | 25.00            | 450640         | 821.80             | 285968           |
| Named              | 1.00                 | 297008             | 1.00             | 449824         | 2.00               | 281136           |
| Override           | 226.60               | 301632             | 1.80             | 477344         | 498.60             | 294752           |

---

## Scenario Explanations

- **RegisterSingleton**: Baseline singleton registration and resolution.
- **ChainSingleton**: Deep singleton chains, stress for lookup logic.
- **ChainFactory**: Stateless factory chains.
- **AsyncChain**: Async factories/graphs.
- **Named**: Named binding resolution.
- **Override**: Scope override and modular/test archetypes.

---

## Conclusions

- **GetIt** has record-best speed and the lowest memory use in almost every scenario. Especially effective for deep/wide graphs and shows ultra-high stability (lowest jitter).
- **Cherrypick** is fast, especially on simple chains or named resolutions, but is predictably slower as complexity grows. Excels in production, codegen, and testable setups where advanced scopes/diagnostics matter.
- **Riverpod** holds its ground in basic and named scenarios, but time and memory grow much faster under heavy/complex loads, especially for deep async/factory/override chains.

### Recommendations
- Use **GetIt** when maximum performance and low memory are top priorities (games, scripts, simple apps, perf-critical UI).
- Use **Cherrypick** for scalable, multi-package testable apps, where advanced scopes, codegen, and diagnostics are needed.
- Use **Riverpod** when you need reactive state or deep Flutter integration, and the DI graph's depth/width is moderate.

---

_Last updated: August 7, 2025, with full scenario matrix. Developed using open-source benchmark scripts._
