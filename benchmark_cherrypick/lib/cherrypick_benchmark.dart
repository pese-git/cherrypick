// ignore: depend_on_referenced_packages
import 'package:benchmark_cherrypick/di_adapter.dart';
// ignore: depend_on_referenced_packages
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<FooService>().toProvide(() => FooService());
  }
}

// Dummy service for DI
class FooService {}

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
