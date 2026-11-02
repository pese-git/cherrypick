import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:riverpod/riverpod.dart' as rp;
import 'di_adapter.dart';

/// Унифицированный DIAdapter для Riverpod с поддержкой scopes и строгой типизацией.
class RiverpodAdapter extends DIAdapter<Map<String, rp.ProviderBase<Object?>>> {
  rp.ProviderContainer? _container;
  final Map<String, rp.ProviderBase<Object?>> _namedProviders;

  /// Типизированный индекс для безымянного резолва: контейнер ищет провайдер
  /// по объекту, мост «тип → провайдер» нужен только интерфейсу адаптера
  /// `resolve<T>()`. Один O(1) lookup, без сборки строк на вызов.
  final Map<Type, rp.ProviderBase<Object?>> _typedProviders;
  final rp.ProviderContainer? _parent;

  RiverpodAdapter({
    rp.ProviderContainer? container,
    Map<String, rp.ProviderBase<Object?>>? providers,
    Map<Type, rp.ProviderBase<Object?>>? typedProviders,
    rp.ProviderContainer? parent,
    bool isSubScope = false,
  })  : _container = container,
        _namedProviders = providers ?? <String, rp.ProviderBase<Object?>>{},
        _typedProviders = typedProviders ?? <Type, rp.ProviderBase<Object?>>{},
        _parent = parent;

  @override
  void setupDependencies(
      void Function(Map<String, rp.ProviderBase<Object?>> container)
          registration) {
    _container ??= _parent == null
        ? rp.ProviderContainer()
        : rp.ProviderContainer(parent: _parent);
    registration(_namedProviders);
  }

  @override
  T resolve<T extends Object>({String? named}) {
    if (named == null) {
      final provider = _typedProviders[T];
      if (provider == null) {
        throw Exception('Provider not found for $T');
      }
      return _container!.read(provider) as T;
    }
    final provider = _namedProviders[named];
    if (provider == null) {
      throw Exception('Provider not found for $named');
    }
    return _container!.read(provider) as T;
  }

  @override
  Object? nativeBindingFor({String? named}) {
    // Хендл нативного биндинга riverpod — сам провайдер. Поиск по карте
    // выполняется здесь, в setup(), вне секундомера; измеряемый путь —
    // только container.read(provider).
    if (named == null) {
      return _typedProviders[UniversalService];
    }
    return _namedProviders[named];
  }

  @override
  T resolveNative<T extends Object>(Object binding, {String? named}) {
    return _container!.read(binding as rp.ProviderBase<Object?>) as T;
  }

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async {
    final rp.ProviderBase<Object?> provider;
    if (named == null) {
      final p = _typedProviders[T];
      if (p == null) {
        throw Exception('Provider not found for $T');
      }
      provider = p;
    } else {
      final p = _namedProviders[named];
      if (p == null) {
        throw Exception('Provider not found for $named');
      }
      provider = p;
    }
    // Если это FutureProvider — используем .future
    if (provider is rp.FutureProvider) {
      return await _container!.read((provider as dynamic).future) as T;
    }
    return resolve<T>(named: named);
  }

  @override
  Future<void> teardown() async {
    _container?.dispose();
    _container = null;
    _namedProviders.clear();
    _typedProviders.clear();
  }

  @override
  RiverpodAdapter openSubScope(String name) {
    final newContainer = rp.ProviderContainer(parent: _container);
    return RiverpodAdapter(
      container: newContainer,
      providers: Map.of(_namedProviders),
      typedProviders: Map.of(_typedProviders),
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
  Registration<Map<String, rp.ProviderBase<Object?>>>
      universalRegistration<S extends Enum>({
    required S scenario,
    required int chainCount,
    required int nestingDepth,
    required UniversalBindingMode bindingMode,
  }) {
    if (scenario is UniversalScenario) {
      return (providers) {
        switch (scenario) {
          case UniversalScenario.register:
            final provider = rp.Provider<UniversalService>(
                (ref) => UniversalServiceImpl(value: 'reg', dependency: null));
            providers['UniversalService'] = provider;
            _typedProviders[UniversalService] = provider;
            break;
          case UniversalScenario.named:
            // Имя строится при регистрации и захватывается константой —
            // симметрично chain-провайдерам.
            for (var chain = 1; chain <= chainCount; chain++) {
              final implName = 'impl$chain';
              providers[implName] = rp.Provider<UniversalService>(
                  (ref) => UniversalServiceImpl(value: implName));
            }
            break;
          case UniversalScenario.chain:
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                providers[depName] =
                    rp.Provider<UniversalService>((ref) => UniversalServiceImpl(
                          value: depName,
                          dependency: level > 1
                              ? ref.watch(providers[prevDepName]
                                  as rp.ProviderBase<UniversalService>)
                              : null,
                        ));
              }
            }
            final depName = '${chainCount}_$nestingDepth';
            final headProvider = rp.Provider<UniversalService>((ref) =>
                ref.watch(
                    providers[depName] as rp.ProviderBase<UniversalService>));
            providers['UniversalService'] = headProvider;
            _typedProviders[UniversalService] = headProvider;
            break;
          case UniversalScenario.override:
            // Ребёнок переопределяет только алиас; цепочка остаётся у родителя.
            final depName = '${chainCount}_$nestingDepth';
            final overrideProvider = rp.Provider<UniversalService>((ref) =>
                ref.watch(
                    providers[depName] as rp.ProviderBase<UniversalService>));
            providers['UniversalService'] = overrideProvider;
            _typedProviders[UniversalService] = overrideProvider;
            break;
          case UniversalScenario.asyncChain:
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                providers[depName] =
                    rp.FutureProvider<UniversalService>((ref) async {
                  return UniversalServiceImpl(
                    value: depName,
                    dependency: level > 1
                        ? await ref.watch((providers[prevDepName]
                                as rp.FutureProvider<UniversalService>)
                            .future) as UniversalService?
                        : null,
                  );
                });
              }
            }
            final depName = '${chainCount}_$nestingDepth';
            final headProvider =
                rp.FutureProvider<UniversalService>((ref) async {
              return await ref.watch(
                  (providers[depName] as rp.FutureProvider<UniversalService>)
                      .future);
            });
            providers['UniversalService'] = headProvider;
            _typedProviders[UniversalService] = headProvider;
            break;
        }
      };
    }
    throw UnsupportedError(
        'Scenario $scenario not supported by RiverpodAdapter');
  }
}
