import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/app_module.dart';
import 'package:benchmark_cherrypick/scenarios/foo_service.dart';

class RegisterAndResolveBenchmark extends BenchmarkBase {
  final DIAdapter di;

  RegisterAndResolveBenchmark(this.di) : super('RegisterAndResolve');

  @override
  void setup() {
    di.setupModules([AppModule()]);
  }

  @override
  void run() {
    di.resolve<FooService>();
  }

  @override
  void teardown() => di.teardown();
}
