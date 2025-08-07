import 'package:cherrypick/cherrypick.dart';
import 'universal_service.dart';

/// Enum to represent the DI registration/binding mode.
enum UniversalBindingMode {
  /// Singleton/provider binding.
  singletonStrategy,

  /// Factory-based binding.
  factoryStrategy,

  /// Async-based binding.
  asyncStrategy,
}

/// Enum to represent which scenario is constructed for the benchmark.
enum UniversalScenario {
  /// Single registration.
  register,
  /// Chain of dependencies.
  chain,
  /// Named registrations.
  named,
  /// Child-scope override scenario.
  override,
  /// Asynchronous chain scenario.
  asyncChain,
}

/// Test module that generates a chain of service bindings for benchmarking.
///
/// Configurable by chain count, nesting depth, binding mode, and scenario
/// to support various DI performance tests (singleton, factory, async, etc).
class UniversalChainModule extends Module {
  /// Number of chains to create.
  final int chainCount;
  /// Depth of each chain.
  final int nestingDepth;
  /// How modules are registered (factory/singleton/async).
  final UniversalBindingMode bindingMode;
  /// Which di scenario to generate (chained, named, etc).
  final UniversalScenario scenario;

  /// Constructs a configured test DI module for the benchmarks.
  UniversalChainModule({
    required this.chainCount,
    required this.nestingDepth,
    this.bindingMode = UniversalBindingMode.singletonStrategy,
    this.scenario = UniversalScenario.chain,
  });

  @override
  void builder(Scope currentScope) {
    if (scenario == UniversalScenario.asyncChain) {
      // Generate async chain with singleton async bindings.
      for (var chainIndex = 0; chainIndex < chainCount; chainIndex++) {
        for (var levelIndex = 0; levelIndex < nestingDepth; levelIndex++) {
          final chain = chainIndex + 1;
          final level = levelIndex + 1;
          final prevDepName = '${chain}_${level - 1}';
          final depName = '${chain}_$level';
          bind<UniversalService>()
            .toProvideAsync(() async {
              final prev = level > 1
                  ? await currentScope.resolveAsync<UniversalService>(named: prevDepName)
                  : null;
              return UniversalServiceImpl(
                value: depName,
                dependency: prev,
              );
            })
            .withName(depName)
            .singleton();
        }
      }
      return;
    }

    switch (scenario) {
      case UniversalScenario.register:
        // Simple singleton registration.
        bind<UniversalService>()
            .toProvide(() => UniversalServiceImpl(value: 'reg', dependency: null))
            .singleton();
        break;
      case UniversalScenario.named:
        // Named factory registration for two distinct objects.
        bind<UniversalService>().toProvide(() => UniversalServiceImpl(value: 'impl1')).withName('impl1');
        bind<UniversalService>().toProvide(() => UniversalServiceImpl(value: 'impl2')).withName('impl2');
        break;
      case UniversalScenario.chain:
        // Chain of nested services, with dependency on previous level by name.
        for (var chainIndex = 0; chainIndex < chainCount; chainIndex++) {
          for (var levelIndex = 0; levelIndex < nestingDepth; levelIndex++) {
            final chain = chainIndex + 1;
            final level = levelIndex + 1;
            final prevDepName = '${chain}_${level - 1}';
            final depName = '${chain}_$level';
            switch (bindingMode) {
              case UniversalBindingMode.singletonStrategy:
                bind<UniversalService>()
                    .toProvide(() => UniversalServiceImpl(
                          value: depName,
                          dependency: currentScope.tryResolve<UniversalService>(named: prevDepName),
                        ))
                    .withName(depName)
                    .singleton();
                break;
              case UniversalBindingMode.factoryStrategy:
                bind<UniversalService>()
                    .toProvide(() => UniversalServiceImpl(
                          value: depName,
                          dependency: currentScope.tryResolve<UniversalService>(named: prevDepName),
                        ))
                    .withName(depName);
                break;
              case UniversalBindingMode.asyncStrategy:
                bind<UniversalService>()
                    .toProvideAsync(() async => UniversalServiceImpl(
                          value: depName,
                          dependency: await currentScope.resolveAsync<UniversalService>(named: prevDepName),
                        ))
                    .withName(depName)
                    .singleton();
                break;
            }
          }
        }
        // Регистрация алиаса без имени (на последний элемент цепочки)
        final depName = '${chainCount}_${nestingDepth}';
        bind<UniversalService>()
            .toProvide(() => currentScope.resolve<UniversalService>(named: depName))
            .singleton();
        break;
      case UniversalScenario.override:
        // handled at benchmark level, но алиас нужен прямо в этом scope!
        final depName = '${chainCount}_${nestingDepth}';
        bind<UniversalService>()
            .toProvide(() => currentScope.resolve<UniversalService>(named: depName))
            .singleton();
        break;
      case UniversalScenario.asyncChain:
        // already handled above
        break;
    }
  }
}
