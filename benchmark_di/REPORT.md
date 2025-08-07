# DI Benchmark Results: cherrypick vs get_it

## Benchmark parameters

| Parameter         | Value                  |
|------------------|-----------------------|
| --benchmark      | all                   |
| --chainCount (-c)| 10, 100               |
| --nestingDepth (-d)| 10, 100             |
| --repeat (-r)    | 2                     |
| --warmup (-w)    | 1 (default)           |
| --format (-f)    | markdown              |
| --di             | cherrypick, get_it    |

---

## Benchmark scenarios

**(1) RegisterSingleton**
Registers and resolves a singleton. Baseline DI speed.

**(2) ChainSingleton**
A dependency chain A → B → ... → N (singleton). Measures how fast DI resolves deep singleton chains by name.

**(3) ChainFactory**
Same as ChainSingleton, but every chain element is a factory. Shows DI speed for stateless 'creation chain'.

**(4) AsyncChain**
Async chain (async factory). Measures DI performance for async graphs.

**(5) Named**
Registers two bindings with names ("impl1", "impl2"), resolves by name. Tests named lookup.

**(6) Override**
Registers a chain/alias in a child scope and resolves UniversalService without a name in that scope. Simulates override and modular/test architecture.

---

## Comparative Table (Mean, ΔRSS), chainCount=10, nestingDepth=10

| Scenario           | cherrypick Mean (us) | cherrypick ΔRSS | get_it Mean (us) | get_it ΔRSS |
|--------------------|---------------------:|----------------:|-----------------:|------------:|
| RegisterSingleton  | 21.0                 | 320             | 24.5             | 80          |
| ChainSingleton     | 112.5                | -3008           | 2.0              | 304         |
| ChainFactory       | 8.0                  | 0               | 4.0              | 0           |
| AsyncChain         | 36.5                 | 0               | 13.5             | 0           |
| Named              | 1.5                  | 0               | 0.5              | 0           |
| Override           | 27.5                 | 0               | 0.0              | 0           |

## Maximum load: chainCount=100, nestingDepth=100

| Scenario           | cherrypick Mean (us) | cherrypick ΔRSS | get_it Mean (us) | get_it ΔRSS |
|--------------------|---------------------:|----------------:|-----------------:|------------:|
| RegisterSingleton  | 1.0                  | 32              | 1.0              | 0           |
| ChainSingleton     | 3884.0               | 0               | 1.5              | 34848       |
| ChainFactory       | 4088.0               | 0               | 50.0             | 12528       |
| AsyncChain         | 4287.0               | 0               | 17.0             | 63120       |
| Named              | 1.0                  | 0               | 0.0              | 0           |
| Override           | 4767.5               | 0               | 1.5              | 14976       |

---

## Scenario explanations

- **RegisterSingleton:** Registers and resolves a singleton dependency, baseline test for cold/hot startup speed.
- **ChainSingleton:** Deep chain of singleton dependencies. Cherrypick is much slower as depth increases; get_it is nearly unaffected.
- **ChainFactory:** Creation chain with new instances per resolve. get_it generally faster on large chains due to ultra-simple factory registration.
- **AsyncChain:** Async factory chain. get_it processes async resolutions much faster; cherrypick is much slower as depth increases due to async handling.
- **Named:** Both DI containers resolve named bindings nearly instantly, even on large graphs.
- **Override:** Child scope override. get_it (thanks to stack-based scopes) resolves immediately; cherrypick supports modular testing with controlled memory use.

## Summary

- **get_it** demonstrates impressive speed and low overhead across all scenarios and loads, but lacks diagnostics, advanced scopes, and cycle detection.
- **cherrypick** is ideal for complex, multi-layered, production or testable architectures where scope, overrides, and diagnostics are critical. Predictably slower on deep/wide graphs, but scales well and provides extra safety.

**Recommendation:**
- Use cherrypick for enterprise, multi-feature/testable DI needs.
- Use get_it for fast games, scripts, tiny Apps, and hot demos.
