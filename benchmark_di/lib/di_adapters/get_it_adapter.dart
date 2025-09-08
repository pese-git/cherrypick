import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:get_it/get_it.dart';
import 'di_adapter.dart';

/// Универсальный DIAdapter для GetIt c поддержкой scopes и строгой типизацией.
class GetItAdapter extends DIAdapter<GetIt> {
  late GetIt _getIt;
  final String? _scopeName;
  final bool _isSubScope;
  bool _scopePushed = false;

  /// Основной (root) и subScope-конструкторы.
  GetItAdapter({GetIt? instance, String? scopeName, bool isSubScope = false})
      : _scopeName = scopeName,
        _isSubScope = isSubScope {
    if (instance != null) {
      _getIt = instance;
    }
  }

  @override
  void setupDependencies(void Function(GetIt container) registration) {
    if (_isSubScope) {
      // Создаём scope через pushNewScope с init
      _getIt.pushNewScope(
        scopeName: _scopeName,
        init: (getIt) => registration(getIt),
      );
      _scopePushed = true;
    } else {
      _getIt = GetIt.asNewInstance();
      registration(_getIt);
    }
  }

  @override
  T resolve<T extends Object>({String? named}) =>
      _getIt<T>(instanceName: named);

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async =>
      _getIt<T>(instanceName: named);

  @override
  void teardown() {
    if (_isSubScope && _scopePushed) {
      _getIt.popScope();
      _scopePushed = false;
    } else {
      _getIt.reset();
    }
  }

  @override
  GetItAdapter openSubScope(String name) =>
      GetItAdapter(instance: _getIt, scopeName: name, isSubScope: true);

  @override
  Future<void> waitForAsyncReady() async {
    await _getIt.allReady();
  }

  @override
  Registration<GetIt> universalRegistration<S extends Enum>({
    required S scenario,
    required int chainCount,
    required int nestingDepth,
    required UniversalBindingMode bindingMode,
  }) {
    if (scenario is UniversalScenario) {
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
                        ? await getIt.getAsync<UniversalService>(
                            instanceName: prevDepName)
                        : null;
                    return UniversalServiceImpl(
                        value: depName, dependency: prev);
                  },
                  instanceName: depName,
                );
              }
            }
            break;
          case UniversalScenario.register:
            getIt.registerSingleton<UniversalService>(
                UniversalServiceImpl(value: 'reg', dependency: null));
            break;
          case UniversalScenario.named:
            getIt.registerFactory<UniversalService>(
                () => UniversalServiceImpl(value: 'impl1'),
                instanceName: 'impl1');
            getIt.registerFactory<UniversalService>(
                () => UniversalServiceImpl(value: 'impl2'),
                instanceName: 'impl2');
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
                            ? await getIt.getAsync<UniversalService>(
                                instanceName: prevDepName)
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
        if (scenario == UniversalScenario.chain ||
            scenario == UniversalScenario.override) {
          final depName = '${chainCount}_$nestingDepth';
          getIt.registerSingleton<UniversalService>(
            getIt<UniversalService>(instanceName: depName),
          );
        }
      };
    }
    throw UnsupportedError('Scenario $scenario not supported by GetItAdapter');
  }
}
