# benchmark_cherrypick

Benchmarks for the performance and features of the cherrypick (core) DI container.

All scenarios use only the public API (scope, module, binding, scoping, and async).

## Scenarios

- **RegisterAndResolve**: Basic registration and resolution of a dependency.
- **ChainSingleton (A->B->C, singleton)**: Deep dependency chain, all as singletons.
- **ChainFactory (A->B->C, factory)**: Dependency chain with factory bindings (new instance per request).
- **NamedResolve (by name)**: Resolving a named dependency among several implementations.
- **AsyncChain (A->B->C, async)**: Asynchronous dependency chain.
- **ScopeOverride (child overrides parent)**: Overriding a dependency in a child scope over a parent.

## Features

- **Unified benchmark structure**: All test scenarios use a unified base mixin for setup/teardown.
- **Flexible CLI parameterization**:  
  Run benchmarks with custom parameters for chain length, depth, scenarios and formats.
- **Matrix/mass run support**:  
  Easily run benchmarks for all combinations of chainLength and depth in one run.
- **Machine and human readable output**:  
  Supports pretty-table, CSV, and JSON for downstream analytics or data storage.
- **Scenario selection**:  
  Run all or only specific benchmarks via CLI.

## How to run

1. Get dependencies:
   ```shell
   dart pub get
   ```
2. Run all benchmarks (with default parameters):
   ```shell
   dart run bin/main.dart
   ```

### Run with custom parameters

- Mass run in matrix mode (CSV output):
  ```shell
  dart run bin/main.dart --benchmark=chain_singleton --chainCount=10,100 --nestingDepth=5,10 --format=csv
  ```

- Run only the named resolve scenario:
  ```shell
  dart run bin/main.dart --benchmark=named
  ```

- See available CLI flags:
  ```shell
  dart run bin/main.dart --help
  ```

#### Available CLI options

- `--benchmark` (or `-b`) — Scenario to run:  
  `register`, `chain_singleton`, `chain_factory`, `named`, `override`, `async_chain`, `all` (default)
- `--chainCount` (or `-c`) — Comma-separated chain lengths. E.g. `10,100`
- `--nestingDepth` (or `-d`) — Comma-separated chain depths. E.g. `5,10`
- `--format` (or `-f`) — Result output format: `pretty` (table), `csv`, `json`
- `--help` (or `-h`) — Print help

#### Example output (`--format=csv`)
```
benchmark,chainCount,nestingDepth,elapsed_us
ChainSingleton,10,5,2450000
ChainSingleton,10,10,2624000
ChainSingleton,100,5,2506300
ChainSingleton,100,10,2856900
```

---

## Add your own benchmark

1. Create a Dart file with a class inheriting from `BenchmarkBase` or `AsyncBenchmarkBase`.
2. Use the `BenchmarkWithScope` mixin for automatic Scope management if needed.
3. Add your benchmark to bin/main.dart for selection via CLI.

---

## Example for contributors

```dart
class MyBenchmark extends BenchmarkBase with BenchmarkWithScope {
  MyBenchmark() : super('My custom');
  @override void setup() => setupScope([MyModule()]);
  @override void run() { scope.resolve<MyType>(); }
  @override void teardown() => teardownScope();
}
```

---

## License

MIT
