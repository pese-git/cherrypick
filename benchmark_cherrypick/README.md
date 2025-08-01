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
| RegisterAndResolve                                 | 0.3407        |
| ChainSingleton (A->B->C, singleton)                | 0.3777        |
| ChainFactory (A->B->C, factory)                    | 0.9688        |
| NamedResolve (by name)                             | 0.3878        |
| AsyncChain (A->B->C, async)                        | 1.8006        |
| ScopeOverride (child overrides parent)             | 0.3477        |

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
