import 'package:benchmark_runner/benchmark_runner.dart';
import 'package:benchmark_cherrypick/cherrypick_benchmark.dart';
import 'package:benchmark_cherrypick/complex_bindings_benchmark.dart';
import 'package:benchmark_cherrypick/async_chain_benchmark.dart';
import 'package:benchmark_cherrypick/scope_override_benchmark.dart';

void main(List<String> args) async {
  // Синхронные бенчмарки
  RegisterAndResolveBenchmark().report();
  ChainSingletonBenchmark().report();
  ChainFactoryBenchmark().report();
  NamedResolveBenchmark().report();

  // Асинхронный бенчмарк
  await AsyncChainBenchmark().report();

  ScopeOverrideBenchmark().report();
}
