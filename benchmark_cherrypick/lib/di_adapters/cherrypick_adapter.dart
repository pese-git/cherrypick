import 'package:cherrypick/cherrypick.dart';
import 'di_adapter.dart';

/// DIAdapter implementation for the CherryPick DI library.
///
/// Wraps a CherryPick [Scope] and provides methods
/// to setup modules, resolve dependencies, teardown,
/// and open nested sub-scopes for benchmarking.
class CherrypickDIAdapter implements DIAdapter {
  Scope? _scope;

  @override
  void setupModules(List<Module> modules) {
    _scope = CherryPick.openRootScope();
    _scope!.installModules(modules);
  }

  @override
  T resolve<T>({String? named}) {
    return named == null
      ? _scope!.resolve<T>()
      : _scope!.resolve<T>(named: named);
  }

  @override
  Future<T> resolveAsync<T>({String? named}) async {
    return named == null
      ? await _scope!.resolveAsync<T>()
      : await _scope!.resolveAsync<T>(named: named);
  }

  @override
  void teardown() {
    CherryPick.closeRootScope();
    _scope = null;
  }

  @override
  CherrypickDIAdapter openSubScope(String name) {
    final sub = _scope!.openSubScope(name);
    return _CherrypickSubScopeAdapter(sub);
  }
}

/// Internal adapter for a CherryPick sub-scope.
/// Used for simulating child/override DI scopes in benchmarks.
class _CherrypickSubScopeAdapter extends CherrypickDIAdapter {
  final Scope _subScope;
  _CherrypickSubScopeAdapter(this._subScope);
  @override
  void setupModules(List<Module> modules) {
    _subScope.installModules(modules);
  }

  @override
  T resolve<T>({String? named}) {
    return named == null
      ? _subScope.resolve<T>()
      : _subScope.resolve<T>(named: named);
  }

  @override
  Future<T> resolveAsync<T>({String? named}) async {
    return named == null
      ? await _subScope.resolveAsync<T>()
      : await _subScope.resolveAsync<T>(named: named);
  }

  @override
  void teardown() {
    // subScope teardown убирать отдельно не требуется
  }

  @override
  CherrypickDIAdapter openSubScope(String name) {
    return _CherrypickSubScopeAdapter(_subScope.openSubScope(name));
  }
}
