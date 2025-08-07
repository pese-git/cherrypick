import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:cherrypick/cherrypick.dart';
import 'di_adapter.dart';


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
        final depName = '${chainCount}_$nestingDepth';
        bind<UniversalService>()
            .toProvide(() => currentScope.resolve<UniversalService>(named: depName))
            .singleton();
        break;
      case UniversalScenario.override:
        // handled at benchmark level, но алиас нужен прямо в этом scope!
        final depName = '${chainCount}_$nestingDepth';
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


class CherrypickDIAdapter extends DIAdapter<Scope> {
  Scope? _scope;
  final bool _isSubScope;

  CherrypickDIAdapter([Scope? scope, this._isSubScope = false]) {
    _scope = scope;
  }

  @override
  void setupDependencies(void Function(Scope container) registration) {
    _scope ??= CherryPick.openRootScope();
    registration(_scope!);
  }

  @override
  Registration<Scope> universalRegistration<S extends Enum>({
    required S scenario,
    required int chainCount,
    required int nestingDepth,
    required UniversalBindingMode bindingMode,
  }) {
    if (scenario is UniversalScenario) {
      return (scope) {
        scope.installModules([
          UniversalChainModule(
            chainCount: chainCount,
            nestingDepth: nestingDepth,
            bindingMode: bindingMode,
            scenario: scenario,
          ),
        ]);
      };
    }
    throw UnsupportedError('Scenario $scenario not supported by CherrypickDIAdapter');
  }

  @override
  T resolve<T extends Object>({String? named}) =>
      named == null ? _scope!.resolve<T>() : _scope!.resolve<T>(named: named);

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async =>
      named == null ? await _scope!.resolveAsync<T>() : await _scope!.resolveAsync<T>(named: named);

  @override
  void teardown() {
    if (!_isSubScope) {
      CherryPick.closeRootScope();
      _scope = null;
    }
    // SubScope teardown не требуется
  }

  @override
  CherrypickDIAdapter openSubScope(String name) {
    return CherrypickDIAdapter(_scope!.openSubScope(name), true);
  }

  @override
  Future<void> waitForAsyncReady() async {}
}
