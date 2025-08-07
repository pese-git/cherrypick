import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:riverpod/riverpod.dart' as rp;
import 'di_adapter.dart';

/// Унифицированный DIAdapter для Riverpod с поддержкой scopes и строгой типизацией.
class RiverpodAdapter extends DIAdapter<Map<String, rp.ProviderBase<Object?>>> {
  rp.ProviderContainer? _container;
  final Map<String, rp.ProviderBase<Object?>> _namedProviders;
  final rp.ProviderContainer? _parent;
  final bool _isSubScope;

  RiverpodAdapter({
    rp.ProviderContainer? container,
    Map<String, rp.ProviderBase<Object?>>? providers,
    rp.ProviderContainer? parent,
    bool isSubScope = false,
  })  : _container = container,
        _namedProviders = providers ?? <String, rp.ProviderBase<Object?>>{},
        _parent = parent,
        _isSubScope = isSubScope;

  @override
  void setupDependencies(void Function(Map<String, rp.ProviderBase<Object?>> container) registration) {
    _container ??= _parent == null
        ? rp.ProviderContainer()
        : rp.ProviderContainer(parent: _parent);
    registration(_namedProviders);
  }

  @override
  T resolve<T extends Object>({String? named}) {
    final key = named ?? T.toString();
    final provider = _namedProviders[key];
    if (provider == null) {
      throw Exception('Provider not found for $key');
    }
    return _container!.read(provider) as T;
  }

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async {
    final key = named ?? T.toString();
    final provider = _namedProviders[key];
    if (provider == null) {
      throw Exception('Provider not found for $key');
    }
    // Если это FutureProvider — используем .future
    if (provider.runtimeType.toString().contains('FutureProvider')) {
      return await _container!.read((provider as dynamic).future) as T;
    }
    return resolve<T>(named: named);
  }

  @override
  void teardown() {
    _container?.dispose();
    _container = null;
    _namedProviders.clear();
  }

  @override
  RiverpodAdapter openSubScope(String name) {
    final newContainer = rp.ProviderContainer(parent: _container);
    return RiverpodAdapter(
      container: newContainer,
      providers: Map.of(_namedProviders),
      parent: _container,
      isSubScope: true,
    );
  }

  @override
  Future<void> waitForAsyncReady() async {
    // Riverpod синхронный по умолчанию.
    return;
  }

  @override
  Registration<Map<String, rp.ProviderBase<Object?>>> universalRegistration<S extends Enum>({
    required S scenario,
    required int chainCount,
    required int nestingDepth,
    required UniversalBindingMode bindingMode,
  }) {
    if (scenario is UniversalScenario) {
      return (providers) {
        switch (scenario) {
          case UniversalScenario.register:
            providers['UniversalService'] = rp.Provider<UniversalService>((ref) => UniversalServiceImpl(value: 'reg', dependency: null));
            break;
          case UniversalScenario.named:
            providers['impl1'] = rp.Provider<UniversalService>((ref) => UniversalServiceImpl(value: 'impl1'));
            providers['impl2'] = rp.Provider<UniversalService>((ref) => UniversalServiceImpl(value: 'impl2'));
            break;
          case UniversalScenario.chain:
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                providers[depName] = rp.Provider<UniversalService>((ref) => UniversalServiceImpl(
                  value: depName,
                  dependency: level > 1 ? ref.watch(providers[prevDepName] as rp.ProviderBase<UniversalService>) : null,
                ));
              }
            }
            final depName = '${chainCount}_$nestingDepth';
            providers['UniversalService'] = rp.Provider<UniversalService>((ref) => ref.watch(providers[depName] as rp.ProviderBase<UniversalService>));
            break;
          case UniversalScenario.override:
            // handled at benchmark level
            break;
          case UniversalScenario.asyncChain:
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                providers[depName] = rp.FutureProvider<UniversalService>((ref) async {
                  return UniversalServiceImpl(
                    value: depName,
                    dependency: level > 1
                        ? await ref.watch((providers[prevDepName] as rp.FutureProvider<UniversalService>).future) as UniversalService?
                        : null,
                  );
                });
              }
            }
            final depName = '${chainCount}_$nestingDepth';
            providers['UniversalService'] = rp.FutureProvider<UniversalService>((ref) async {
              return await ref.watch((providers[depName] as rp.FutureProvider<UniversalService>).future);
            });
            break;
        }
      };
    }
    throw UnsupportedError('Scenario $scenario not supported by RiverpodAdapter');
  }
}
