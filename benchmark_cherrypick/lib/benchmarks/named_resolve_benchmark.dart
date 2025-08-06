import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/named_module.dart';

class NamedResolveBenchmark extends BenchmarkBase {
  final DIAdapter di;

  NamedResolveBenchmark(this.di) : super('NamedResolve (by name)');

  @override
  void setup() {
    di.setupModules([NamedModule()]);
  }

  @override
  void teardown() => di.teardown();

  @override
  void run() {
    di.resolve<Object>(named: 'impl2');
  }
}
