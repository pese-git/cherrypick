// ignore_for_file: invalid_use_of_protected_member

import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:benchmark_di/di_adapters/yx_scope_universal_container.dart';

/// DIAdapter для yx_scope UniversalYxScopeContainer
class YxScopeAdapter extends DIAdapter<UniversalYxScopeContainer> {
  late UniversalYxScopeContainer _scope;

  @override
  void setupDependencies(
      void Function(UniversalYxScopeContainer container) registration) {
    _scope = UniversalYxScopeContainer();
    registration(_scope);
  }

  @override
  T resolve<T extends Object>({String? named}) {
    return _scope.depFor<T>(name: named).get;
  }

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async {
    return resolve<T>(named: named);
  }

  @override
  void teardown() {
    // У yx_scope нет явного dispose на ScopeContainer, но можно добавить очистку Map/Deps если потребуется
    // Ничего не делаем
  }

  @override
  YxScopeAdapter openSubScope(String name) {
    // Для простоты всегда возвращаем новый контейнер, сабскоупы не реализованы явно
    return YxScopeAdapter();
  }

  @override
  Future<void> waitForAsyncReady() async {
    // Все зависимости синхронны
    return;
  }

  @override
  Registration<UniversalYxScopeContainer>
      universalRegistration<S extends Enum>({
    required S scenario,
    required int chainCount,
    required int nestingDepth,
    required UniversalBindingMode bindingMode,
  }) {
    if (scenario is UniversalScenario) {
      return (scope) {
        switch (scenario) {
          case UniversalScenario.asyncChain:
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                final dep = scope.dep<UniversalService>(
                  () => UniversalServiceImpl(
                    value: depName,
                    dependency: level > 1
                        ? scope.depFor<UniversalService>(name: prevDepName).get
                        : null,
                  ),
                  name: depName,
                );
                scope.register<UniversalService>(dep, name: depName);
              }
            }
            break;
          case UniversalScenario.register:
            final dep = scope.dep<UniversalService>(
              () => UniversalServiceImpl(value: 'reg', dependency: null),
            );
            scope.register<UniversalService>(dep);
            break;
          case UniversalScenario.named:
            final dep1 = scope.dep<UniversalService>(
              () => UniversalServiceImpl(value: 'impl1'),
              name: 'impl1',
            );
            final dep2 = scope.dep<UniversalService>(
              () => UniversalServiceImpl(value: 'impl2'),
              name: 'impl2',
            );
            scope.register<UniversalService>(dep1, name: 'impl1');
            scope.register<UniversalService>(dep2, name: 'impl2');
            break;
          case UniversalScenario.chain:
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                final dep = scope.dep<UniversalService>(
                  () => UniversalServiceImpl(
                    value: depName,
                    dependency: level > 1
                        ? scope.depFor<UniversalService>(name: prevDepName).get
                        : null,
                  ),
                  name: depName,
                );
                scope.register<UniversalService>(dep, name: depName);
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
          final lastDep = scope.dep<UniversalService>(
            () => scope.depFor<UniversalService>(name: depName).get,
          );
          scope.register<UniversalService>(lastDep);
        }
      };
    }
    throw UnsupportedError(
        'Scenario $scenario not supported by YxScopeAdapter');
  }
}
