# benchmark_cherrypick

Benchmarks for performance and features of the cherrypick (core) DI container.

All scenarios use the public API capabilities of cherrypick (scope, module, binding, scoping, and async support).

## Scenarios

- **RegisterAndResolve**: basic registration and resolution of a dependency.
- **ChainSingleton (A->B->C, singleton)**: dependency chain, all as singletons.
- **ChainFactory (A->B->C, factory)**: dependency chain with factory bindings (new instance on each request).
- **NamedResolve (by name)**: resolving a named dependency among multiple implementations.
- **AsyncChain (A->B->C, async)**: asynchronous dependency chain.
- **ScopeOverride (child overrides parent)**: overriding a dependency in a child scope over a parent.

## Benchmark results

| Scenario                                           | RunTime (μs)  |
|----------------------------------------------------|---------------|
| RegisterAndResolve                                 | 0.4574        |
| ChainSingleton (A->B->C, singleton)                | 0.3759        |
| ChainFactory (A->B->C, factory)                    | 1.3783        |
| NamedResolve (by name)                             | 0.5193        |
| AsyncChain (A->B->C, async)                        | 0.5985        |
| ScopeOverride (child overrides parent)             | 0.3611        |

## How to run

1. Get dependencies:
   ```shell
   dart pub get
   ```
2. Run the benchmarks:
   ```shell
   dart run bin/main.dart
   ```

A text report with all metrics will be displayed in the console.

---

To add your custom scenario — just create a new Dart file and declare a class extending BenchmarkBase or AsyncBenchmarkBase, then add its invocation to main.dart.
