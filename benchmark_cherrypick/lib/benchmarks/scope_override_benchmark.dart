import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:benchmark_cherrypick/di_adapters/di_adapter.dart';
import 'package:benchmark_cherrypick/scenarios/parent_module.dart';
import 'package:benchmark_cherrypick/scenarios/child_override_module.dart';
import 'package:benchmark_cherrypick/scenarios/shared.dart';
import 'package:benchmark_cherrypick/scenarios/child_impl.dart';

class ScopeOverrideBenchmark extends BenchmarkBase {
  final DIAdapter di;
  late DIAdapter childDi;

  ScopeOverrideBenchmark(this.di) : super('ScopeOverride (child overrides parent)');

  @override
  void setup() {
    di.setupModules([ParentModule()]);
    childDi = di.openSubScope('child');
    childDi.setupModules([ChildOverrideModule()]);
  }

  @override
  void teardown() => di.teardown();

  @override
  void run() {
    final resolved = childDi.resolve<Shared>();
    assert(resolved is ChildImpl);
  }
}
