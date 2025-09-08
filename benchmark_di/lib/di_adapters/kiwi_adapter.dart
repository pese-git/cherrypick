import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:kiwi/kiwi.dart';
import 'di_adapter.dart';

/// DIAdapter-для KiwiContainer с поддержкой universal benchmark сценариев.
class KiwiAdapter extends DIAdapter<KiwiContainer> {
  late KiwiContainer _container;
  // ignore: unused_field
  final bool _isSubScope;

  KiwiAdapter({KiwiContainer? container, bool isSubScope = false})
      : _isSubScope = isSubScope {
    _container = container ?? KiwiContainer();
  }

  @override
  void setupDependencies(void Function(KiwiContainer container) registration) {
    registration(_container);
  }

  @override
  Registration<KiwiContainer> universalRegistration<S extends Enum>({
    required S scenario,
    required int chainCount,
    required int nestingDepth,
    required UniversalBindingMode bindingMode,
  }) {
    if (scenario is UniversalScenario) {
      if (scenario == UniversalScenario.asyncChain ||
          bindingMode == UniversalBindingMode.asyncStrategy) {
        throw UnsupportedError(
            'Kiwi does not support async dependencies or async binding scenarios.');
      }
      return (container) {
        switch (scenario) {
          case UniversalScenario.asyncChain:
            break;
          case UniversalScenario.register:
            container.registerSingleton<UniversalService>(
              (c) => UniversalServiceImpl(value: 'reg', dependency: null),
            );
            break;
          case UniversalScenario.named:
            container.registerFactory<UniversalService>(
                (c) => UniversalServiceImpl(value: 'impl1'),
                name: 'impl1');
            container.registerFactory<UniversalService>(
                (c) => UniversalServiceImpl(value: 'impl2'),
                name: 'impl2');
            break;
          case UniversalScenario.chain:
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                switch (bindingMode) {
                  case UniversalBindingMode.singletonStrategy:
                    container.registerSingleton<UniversalService>(
                        (c) => UniversalServiceImpl(
                            value: depName,
                            dependency: level > 1
                                ? c.resolve<UniversalService>(prevDepName)
                                : null),
                        name: depName);
                    break;
                  case UniversalBindingMode.factoryStrategy:
                    container.registerFactory<UniversalService>(
                        (c) => UniversalServiceImpl(
                            value: depName,
                            dependency: level > 1
                                ? c.resolve<UniversalService>(prevDepName)
                                : null),
                        name: depName);
                    break;
                  case UniversalBindingMode.asyncStrategy:
                    // Не поддерживается
                    break;
                }
              }
            }
            final depName = '${chainCount}_$nestingDepth';
            container.registerSingleton<UniversalService>(
                (c) => c.resolve<UniversalService>(depName));
            break;
          case UniversalScenario.override:
            final depName = '${chainCount}_$nestingDepth';
            container.registerSingleton<UniversalService>(
                (c) => c.resolve<UniversalService>(depName));
            break;
        }
      };
    }
    throw UnsupportedError('Scenario $scenario not supported by KiwiAdapter');
  }

  @override
  T resolve<T extends Object>({String? named}) {
    // Для asyncChain нужен resolve<Future<T>>
    if (T.toString().startsWith('Future<')) {
      return _container.resolve<T>(named);
    } else {
      return _container.resolve<T>(named);
    }
  }

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async {
    if (T.toString().startsWith('Future<')) {
      // resolve<Future<T>>, unwrap result
      return Future.value(_container.resolve<T>(named));
    } else {
      // Для совместимости с chain/override
      return Future.value(_container.resolve<T>(named));
    }
  }

  @override
  void teardown() {
    _container.clear();
  }

  @override
  KiwiAdapter openSubScope(String name) {
    // Возвращаем новый scoped контейнер (отдельный). Наследование не реализовано.
    return KiwiAdapter(container: KiwiContainer.scoped(), isSubScope: true);
  }

  @override
  Future<void> waitForAsyncReady() async {}
}
