import 'package:cherrypick/cherrypick.dart';

/// Миксин для упрощения работы с CherryPick Scope в бенчмарках.
mixin BenchmarkWithScope {
  Scope? _scope;

  /// Отключить глобальные проверки циклов и создать корневой scope с модулями.
  void setupScope(List<Module> modules,
      {bool disableCycleDetection = true,
      bool disableCrossScopeCycleDetection = true}) {
    if (disableCycleDetection) {
      CherryPick.disableGlobalCycleDetection();
    }
    if (disableCrossScopeCycleDetection) {
      CherryPick.disableGlobalCrossScopeCycleDetection();
    }
    _scope = CherryPick.openRootScope();
    _scope!.installModules(modules);
  }

  /// Закрывает текущий scope.
  void teardownScope() {
    CherryPick.closeRootScope();
    _scope = null;
  }

  /// Получить текущий scope. Не null после setupScope.
  Scope get scope => _scope!;
}
