import 'package:benchmark_di/scenarios/universal_service.dart';

import '../di_adapters/di_adapter.dart';
import '../di_adapters/cherrypick_adapter.dart';
import '../di_adapters/get_it_adapter.dart';
import 'universal_chain_module.dart';
import 'package:riverpod/riverpod.dart' as rp;

/// Унифицированный generic-колбэк для регистрации зависимостей,
/// подходящий под выбранный DI-адаптер.
typedef Registration<TContainer> = void Function(TContainer);

Registration<TContainer> getUniversalRegistration<TContainer>(
  DIAdapter<TContainer> adapter, {
  required int chainCount,
  required int nestingDepth,
  required UniversalBindingMode bindingMode,
  required UniversalScenario scenario,
}) {
  if (adapter is CherrypickDIAdapter) {
    return (scope) {
      scope.installModules([
        UniversalChainModule(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: bindingMode,
          scenario: scenario,
        ),
      ]);
    } as Registration<TContainer>;
  } 
  if (adapter is GetItAdapter) {
    return (getIt) {
      switch (scenario) {
        case UniversalScenario.asyncChain:
          for (int chain = 1; chain <= chainCount; chain++) {
            for (int level = 1; level <= nestingDepth; level++) {
              final prevDepName = '${chain}_${level - 1}';
              final depName = '${chain}_$level';
              getIt.registerSingletonAsync<UniversalService>(
                () async {
                  final prev = level > 1
                      ? await getIt.getAsync<UniversalService>(instanceName: prevDepName)
                      : null;
                  return UniversalServiceImpl(value: depName, dependency: prev as UniversalService?);
                },
                instanceName: depName,
              );
            }
          }
          break;
        case UniversalScenario.register:
          getIt.registerSingleton<UniversalService>(UniversalServiceImpl(value: 'reg', dependency: null));
          break;
        case UniversalScenario.named:
          getIt.registerFactory<UniversalService>(() => UniversalServiceImpl(value: 'impl1'), instanceName: 'impl1');
          getIt.registerFactory<UniversalService>(() => UniversalServiceImpl(value: 'impl2'), instanceName: 'impl2');
          break;
        case UniversalScenario.chain:
          for (int chain = 1; chain <= chainCount; chain++) {
            for (int level = 1; level <= nestingDepth; level++) {
              final prevDepName = '${chain}_${level - 1}';
              final depName = '${chain}_$level';
              switch (bindingMode) {
                case UniversalBindingMode.singletonStrategy:
                  getIt.registerSingleton<UniversalService>(
                    UniversalServiceImpl(
                      value: depName,
                      dependency: level > 1
                          ? getIt<UniversalService>(instanceName: prevDepName)
                          : null,
                    ),
                    instanceName: depName,
                  );
                  break;
                case UniversalBindingMode.factoryStrategy:
                  getIt.registerFactory<UniversalService>(
                    () => UniversalServiceImpl(
                      value: depName,
                      dependency: level > 1
                          ? getIt<UniversalService>(instanceName: prevDepName)
                          : null,
                    ),
                    instanceName: depName,
                  );
                  break;
                case UniversalBindingMode.asyncStrategy:
                  getIt.registerSingletonAsync<UniversalService>(
                    () async => UniversalServiceImpl(
                      value: depName,
                      dependency: level > 1
                          ? await getIt.getAsync<UniversalService>(instanceName: prevDepName)
                          : null,
                    ),
                    instanceName: depName,
                  );
                  break;
              }
            }
          }
          break;
        case UniversalScenario.override:
          // handled at benchmark level
          break;
      }
      // UniversalService alias (без имени) для chain/override-сценариев
      if (scenario == UniversalScenario.chain || scenario == UniversalScenario.override) {
        final depName = '${chainCount}_$nestingDepth';
        getIt.registerSingleton<UniversalService>(
          getIt<UniversalService>(instanceName: depName),
        );
      }
    } as Registration<TContainer>;
  }

  if (adapter is DIAdapter<Map<String, rp.ProviderBase<Object?>>> && adapter.runtimeType.toString().contains('RiverpodAdapter')) {
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
                      ? await ref.watch(providers[prevDepName]!.future) as UniversalService?
                      : null,
                );
              });
            }
          }
          final depName = '${chainCount}_$nestingDepth';
          providers['UniversalService'] = rp.FutureProvider<UniversalService>((ref) async {
            return await ref.watch(providers[depName]!.future) as UniversalService;
          });
          break;
      }
    } as Registration<TContainer>;
  }

  throw UnsupportedError('Unknown DIAdapter type: [38;5;3m${adapter.runtimeType}[0m');
}
