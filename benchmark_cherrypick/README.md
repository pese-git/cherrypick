# benchmark_cherrypick

_Benchmark suite for cherrypick DI container and its features._

## Overview

This package provides comprehensive benchmarks for the [cherrypick](https://github.com/) dependency injection core and comparable DI scenarios. It includes a CLI tool for running a matrix of synthetic scenarios—covering depth and breadth, named resolutions, scope overrides, async chains, memory usage and more.

**Key Features:**
- Declarative matrix runs (chain count, nesting depth, scenario, repeats)
- CLI tool with flexible configuration
- Multiple report formats: pretty table, CSV, JSON, Markdown
- Memory and runtime statistics (mean, median, stddev, min, max, memory diffs)
- Built-in and extensible scenarios (singletons, factories, named, async, overrides)
- Easy to extend with your own modules/adapters

---

## Benchmark Scenarios

- **RegisterSingleton**: Registers and resolves a singleton dependency
- **ChainSingleton**: Resolves a deep chain of singleton dependencies (A→B→C...)
- **ChainFactory**: Resolves a deep chain using factory bindings (new instance each time)
- **AsyncChain**: Resolves an async dependency chain (async providers)
- **Named**: Resolves a named dependency from several implementations
- **Override**: Resolves a dependency overridden in a child scope

---

## How to Run

1. **Get dependencies:**
   ```shell
   dart pub get
   ```
2. **Run all benchmarks (default single configuration, 2 warmups, 2 repeats):**
   ```shell
   dart run bin/main.dart
   ```

3. **Show available CLI options:**
   ```shell
   dart run bin/main.dart --help
   ```

### CLI Parameters

- `--benchmark, -b` — Benchmark scenario:  
  `registerSingleton`, `chainSingleton`, `chainFactory`, `asyncChain`, `named`, `override`, `all` (default: all)
- `--chainCount, -c` — Comma-separated chain counts, e.g. `10,100`
- `--nestingDepth, -d` — Comma-separated chain depths, e.g. `5,10`
- `--repeat, -r` — Number of measurement runs per scenario (default: 2)
- `--warmup, -w` — Warmup runs before measuring (default: 1)
- `--format, -f` — Output format: `pretty`, `csv`, `json`, `markdown` (default: pretty)
- `--help, -h` — Show usage

### Examples

- **Matrix run:**
  ```shell
  dart run bin/main.dart --benchmark=chainSingleton --chainCount=10,100 --nestingDepth=5,10 --repeat=5 --warmup=2 --format=markdown
  ```

- **Run just the named scenario:**
  ```shell
  dart run bin/main.dart --benchmark=named --repeat=3
  ```

### Example Output (Markdown)

```
| Benchmark         | Chain Count | Depth | Mean (us) | ... | PeakRSS(KB) |
|------------------|-------------|-------|-----------| ... |-------------|
| ChainSingleton   | 10          | 5     | 2450000   | ... | 200064      |
```

---

## Report Formats

- **pretty** — Tab-delimited table (human-friendly)
- **csv** — Machine-friendly, for spreadsheets/scripts
- **json** — For automation, data pipelines
- **markdown** — Markdown table for docs/wikis/issues

---

## How to Add Your Own Benchmark

1. Implement a class extending `BenchmarkBase` (sync case) or `AsyncBenchmarkBase`.
2. Configure scenario modules/services using the DI adapter interface.
3. Add scenario selection logic if needed (see bin/main.dart).
4. Optionally extend reporters or adapters for new DI libraries.

Example minimal benchmark:
```dart
class MyBenchmark extends BenchmarkBase {
  MyBenchmark() : super('My custom');
  @override void setup() { /* setup test DI modules */ }
  @override void run()   { /* resolve or invoke dependency chain */ }
  @override void teardown() { /* cleanup if needed */ }
}
```

To plug in a new DI library, implement DIAdapter and register it in CLI.

---

## Metrics Collected

All benchmarks record:
- **Time** (microseconds): mean, median, stddev, min, max, timings
- **Memory**:
  - memory_diff_kb — change in RSS (KB)
  - delta_peak_kb  — change in peak RSS (KB)
  - peak_rss_kb    — absolute peak RSS (KB)

---

## License

MIT
