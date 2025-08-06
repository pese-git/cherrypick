# benchmark_cherrypick

Benchmarks for the performance and features of the cherrypick (core) DI container.

## Scenarios

- **RegisterAndResolve**: Basic registration and resolution of a dependency.
- **ChainSingleton** (A->B->C, singleton): Deep dependency chain, all as singletons.
- **ChainFactory** (A->B->C, factory): Dependency chain with factory bindings (new instance per request).
- **NamedResolve** (by name): Resolving a named dependency among several implementations.
- **AsyncChain** (A->B->C, async): Asynchronous dependency chain.
- **ScopeOverride** (child overrides parent): Overriding a dependency in a child scope over a parent.

## Features

- **Unified benchmark structure**
- **Flexible CLI parameterization (chain length, depth, repeats, warmup, scenario selection, format)**
- **Automatic matrix/mass run for sets of parameters**
- **Statistics: mean, median, stddev, min, max for each scenario**
- **Memory metrics: memory_diff_kb (total diff), delta_peak_kb (max growth), peak_rss_kb (absolute peak)**
- **Pretty-table, CSV, and JSON output**
- **Warmup runs before timing for better result stability**

## How to run

1. Get dependencies:
   ```shell
   dart pub get
   ```
2. Run all benchmarks (defaults: single parameter set, repeat=5, warmup=2):
   ```shell
   dart run bin/main.dart
   ```

### Custom parameters

- Matrix run (CSV, 7 repeats, 3 warmups):
  ```shell
  dart run bin/main.dart --benchmark=chain_singleton --chainCount=10,100 --nestingDepth=5,10 --repeat=7 --warmup=3 --format=csv
  ```

- Run only the named resolve scenario:
  ```shell
  dart run bin/main.dart --benchmark=named --repeat=3 --warmup=1
  ```

- See available CLI flags:
  ```shell
  dart run bin/main.dart --help
  ```

#### CLI options

- `--benchmark` (`-b`) — Scenario:  
  `register`, `chain_singleton`, `chain_factory`, `named`, `override`, `async_chain`, `all` (default: all)
- `--chainCount` (`-c`) — Comma-separated chain lengths. E.g. `10,100`
- `--nestingDepth` (`-d`) — Comma-separated chain depths. E.g. `5,10`
- `--repeat` (`-r`) — How many times to measure each scenario (`default: 5`)
- `--warmup` (`-w`) — How many warmup runs before actual timing (`default: 2`)
- `--format` (`-f`) — Output: `pretty`, `csv`, `json` (default: pretty)
- `--help` (`-h`) — Print help

#### Example output (`--format=csv`)
```
benchmark,chainCount,nestingDepth,mean_us,median_us,stddev_us,min_us,max_us,trials,timings_us,memory_diff_kb,delta_peak_kb,peak_rss_kb
ChainSingleton,10,5,2450000,2440000,78000,2290000,2580000,5,"2440000;2460000;2450000;2580000;2290000",-64,0,200064
```

---

## Add your own benchmark

1. Create a Dart file with a class inheriting from `BenchmarkBase` or `AsyncBenchmarkBase`.
2. Use the `BenchmarkWithScope` mixin for automatic Scope management if needed.
3. Add your benchmark to bin/main.dart for selection via CLI.

---

## Contributor example

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
