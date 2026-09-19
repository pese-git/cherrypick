// ignore_for_file: invalid_use_of_protected_member

import 'package:yx_scope/yx_scope.dart';

import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:benchmark_di/di_adapters/yx_scope_universal_container.dart';

/// DIAdapter для yx_scope UniversalYxScopeContainer
class YxScopeAdapter extends DIAdapter<UniversalYxScopeContainer> {
  late UniversalYxScopeContainer _scope;

  /// Целевой dep текущего сценария, закешированный при регистрации.
  ///
  /// В нативной модели yx_scope поиска по типу/имени нет: потребитель держит
  /// `Dep` напрямую и вызывает `.get`. Реестр в [UniversalYxScopeContainer] —
  /// артефакт интерфейса [DIAdapter], поэтому целевой резолв идёт через кеш,
  /// а `depFor` остаётся фолбэком для любых других имён.
  Dep<UniversalService>? _targetDep;
  String? _targetName;

  /// Головы всех цепочек сценария chain («chain_nestingDepth»).
  ///
  /// Заполняется при регистрации — вне секундомера, по тому же
  /// задокументированному в REPORT_v2 правилу, что и [_targetDep]: билдеры
  /// регистрируются в `setup()`, а измеряемый путь обязан быть нативным
  /// `Dep.get`. Без полного кеша окно первых резолвов резолвило бы 99 из
  /// chainCount голов через фолбэк-реестр, то есть не тот путь, что у
  /// одиночного резолва цели.
  final Map<String, Dep<UniversalService>> _headDeps = {};

  @override
  void setupDependencies(
      void Function(UniversalYxScopeContainer container) registration) {
    // Контейнер не dispose'ится (teardown просто заменяет его), поэтому
    // протухший кеш не бросил бы ScopeException, а молча вернул бы старое
    // значение. Сброс здесь и в teardown — единственная защита от этого.
    _targetDep = null;
    _targetName = null;
    _headDeps.clear();
    _scope = UniversalYxScopeContainer();
    registration(_scope);
  }

  @override
  T resolve<T extends Object>({String? named}) {
    if (named != null) {
      final head = _headDeps[named];
      if (head != null) {
        return head.get as T;
      }
    }
    final target = _targetDep;
    if (target != null && named == _targetName) {
      return target.get as T;
    }
    return _scope.depFor<T>(name: named).get;
  }

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async {
    return resolve<T>(named: named);
  }

  @override
  Future<void> teardown() async {
    _targetDep = null;
    _targetName = null;
    _headDeps.clear();
    _scope = UniversalYxScopeContainer();
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
      if (scenario == UniversalScenario.asyncChain ||
          bindingMode == UniversalBindingMode.asyncStrategy) {
        throw UnsupportedError(
            'YxScope does not support async dependencies or async binding scenarios.');
      }
      if (scenario == UniversalScenario.override) {
        throw UnsupportedError(
            'yx_scope-адаптер не реализует дочерние scope: openSubScope '
            'возвращает независимый контейнер, сценарий override был бы '
            'плоским резолвом под чужим именем.');
      }
      return (scope) {
        switch (scenario) {
          case UniversalScenario.register:
            final dep = scope.dep<UniversalService>(
              () => UniversalServiceImpl(value: 'reg', dependency: null),
            );
            scope.register<UniversalService>(dep);
            _targetDep = dep;
            _targetName = null;
            break;
          case UniversalScenario.named:
            // Имя строится при регистрации и захватывается константой —
            // симметрично chain-фабрикам: иначе named-деп платил бы
            // аллокацию строки на каждый вызов, а chain-деп нет.
            for (var chain = 1; chain <= chainCount; chain++) {
              final implName = 'impl$chain';
              final dep = scope.dep<UniversalService>(
                () => UniversalServiceImpl(value: implName),
                name: implName,
              );
              scope.register<UniversalService>(dep, name: implName);
              _headDeps[implName] = dep;
            }
            break;
          case UniversalScenario.chain:
            // Билдер каждого уровня захватывает Dep предыдущего уровня
            // напрямую — штатный паттерн yx_scope
            // (`dep(() => Manager(otherDep.get))`), без поиска по реестру
            // внутри замыкания.
            Dep<UniversalService>? prev;
            for (int chain = 1; chain <= chainCount; chain++) {
              prev = null;
              for (int level = 1; level <= nestingDepth; level++) {
                // Локальный final: замыкание не должно видеть сдвиг prev.
                final prevDep = prev;
                final depName = '${chain}_$level';
                final dep = scope.dep<UniversalService>(
                  () => UniversalServiceImpl(
                    value: depName,
                    dependency: level > 1 ? prevDep!.get : null,
                  ),
                  name: depName,
                );
                scope.register<UniversalService>(dep, name: depName);
                prev = dep;
              }
            }
            // Последнее звено доступно и без имени — раньше для этого
            // существовал wrapper-dep поверх depFor.
            final lastDep = prev!;
            scope.register<UniversalService>(lastDep);
            _targetDep = lastDep;
            _targetName = '${chainCount}_$nestingDepth';
            // Головы всех цепочек — для окна первых резолвов, где каждая
            // голова резолвится по имени ровно один раз.
            for (int chain = 1; chain <= chainCount; chain++) {
              final headName = '${chain}_$nestingDepth';
              _headDeps[headName] =
                  scope.depFor<UniversalService>(name: headName);
            }
            break;
          case UniversalScenario.override:
            // handled at benchmark level
            break;
          default:
            break;
        }
      };
    }
    throw UnsupportedError(
        'Scenario $scenario not supported by YxScopeAdapter');
  }
}
