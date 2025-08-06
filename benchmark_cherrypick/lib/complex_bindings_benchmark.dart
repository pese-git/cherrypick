// ignore: depend_on_referenced_packages
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cherrypick/cherrypick.dart';

// === DI graph: A -> B -> C (singleton) ===
abstract class Service {
  final dynamic value;
  final Service? dependency;

  Service({
    required this.value,
    this.dependency,
  });
}

class ServiceImpl extends Service {
  ServiceImpl({
    required super.value,
    super.dependency,
  });
}

class ChainSingletonModule extends Module {
  // количество независимых цепочек
  final int chainCount;

  // глубина вложенности
  final int nestingDepth;

  ChainSingletonModule({
    required this.chainCount,
    required this.nestingDepth,
  });

  @override
  void builder(Scope currentScope) {
    for (var chainIndex = 0; chainIndex < chainCount; chainIndex++) {
      for (var levelIndex = 0; levelIndex < nestingDepth; levelIndex++) {
        final chain = chainIndex + 1;
        final level = levelIndex + 1;

        final prevDepName = '${chain.toString()}_${(level - 1).toString()}';
        final depName = '${chain.toString()}_${level.toString()}';

        bind<Service>()
            .toProvide(
              () => ServiceImpl(
            value: depName,
            dependency: currentScope.tryResolve<Service>(
              named: prevDepName,
            ),
          ),
        )
            .withName(depName)
            .singleton();
      }
    }
  }
}

class ChainSingletonBenchmark extends BenchmarkBase {
  final int chainCount;
  final int nestingDepth;

  ChainSingletonBenchmark({
    this.chainCount = 1,
    this.nestingDepth = 3,
  }) : super(
    'ChainSingleton (A->B->C, singleton). '
        'C/D = $chainCount/$nestingDepth. ',
  );
  late Scope scope;

  @override
  void setup() {
    scope = CherryPick.openRootScope();
    scope.installModules([
      ChainSingletonModule(
        chainCount: chainCount,
        nestingDepth: nestingDepth,
      ),
    ]);
  }

  @override
  void teardown() => CherryPick.closeRootScope();

  @override
  void run() {
    final serviceName = '${chainCount.toString()}_${nestingDepth.toString()}';
    scope.resolve<Service>(named: serviceName);
  }
}

// === DI graph: A -> B -> C (factory/no singleton) ===
class ChainFactoryModule extends Module {
  // количество независимых цепочек
  final int chainCount;

  // глубина вложенности
  final int nestingDepth;

  ChainFactoryModule({
    required this.chainCount,
    required this.nestingDepth,
  });

  @override
  void builder(Scope currentScope) {
    for (var chainIndex = 0; chainIndex < chainCount; chainIndex++) {
      for (var levelIndex = 0; levelIndex < nestingDepth; levelIndex++) {
        final chain = chainIndex + 1;
        final level = levelIndex + 1;

        final prevDepName = '${chain.toString()}_${(level - 1).toString()}';
        final depName = '${chain.toString()}_${level.toString()}';

        bind<Service>()
            .toProvide(
              () => ServiceImpl(
            value: depName,
            dependency: currentScope.tryResolve<Service>(
              named: prevDepName,
            ),
          ),
        )
            .withName(depName);
      }
    }
  }
}

class ChainFactoryBenchmark extends BenchmarkBase {
  // количество независимых цепочек
  final int chainCount;

  // глубина вложенности
  final int nestingDepth;

  ChainFactoryBenchmark({
    this.chainCount = 1,
    this.nestingDepth = 3,
  }) : super(
    'ChainFactory (A->B->C, factory). '
        'C/D = $chainCount/$nestingDepth. ',
  );

  late Scope scope;

  @override
  void setup() {
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();

    scope = CherryPick.openRootScope();
    scope.installModules([
      ChainFactoryModule(
        chainCount: chainCount,
        nestingDepth: nestingDepth,
      ),
    ]);
  }

  @override
  void teardown() => CherryPick.closeRootScope();

  @override
  void run() {
    final serviceName = '${chainCount.toString()}_${nestingDepth.toString()}';
    scope.resolve<Service>(named: serviceName);
  }
}

// === Named bindings: Multiple implementations ===
class Impl1 {}

class Impl2 {}

class NamedModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Object>().toProvide(() => Impl1()).withName('impl1');
    bind<Object>().toProvide(() => Impl2()).withName('impl2');
  }
}

class NamedResolveBenchmark extends BenchmarkBase {
  NamedResolveBenchmark() : super('NamedResolve (by name)');
  late Scope scope;

  @override
  void setup() {
    scope = CherryPick.openRootScope();
    scope.installModules([NamedModule()]);
  }

  @override
  void teardown() => CherryPick.closeRootScope();

  @override
  void run() {
    // Switch name for comparison
    scope.resolve<Object>(named: 'impl2');
  }
}

