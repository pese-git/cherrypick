import 'package:cherrypick/cherrypick.dart';
import 'di_adapter.dart';

/// DIAdapter implementation for the CherryPick DI library using registration callbacks.
class CherrypickDIAdapter implements DIAdapter {
  Scope? _scope;
  
  @override
  void setupDependencies(void Function(dynamic container) registration) {
    _scope = CherryPick.openRootScope();
    registration(_scope!);
  }

  @override
  T resolve<T extends Object>({String? named}) =>
      named == null ? _scope!.resolve<T>() : _scope!.resolve<T>(named: named);

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async =>
      named == null ? await _scope!.resolveAsync<T>() : await _scope!.resolveAsync<T>(named: named);

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

  @override
  Future<void> waitForAsyncReady() async {}
}

/// Internal adapter for a CherryPick sub-scope (callbacks based).
class _CherrypickSubScopeAdapter extends CherrypickDIAdapter {
  final Scope _subScope;
  _CherrypickSubScopeAdapter(this._subScope);

  @override
  void setupDependencies(void Function(dynamic container) registration) {
    registration(_subScope);
  }

  @override
  T resolve<T extends Object>({String? named}) =>
      named == null ? _subScope.resolve<T>() : _subScope.resolve<T>(named: named);

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async =>
      named == null ? await _subScope.resolveAsync<T>() : await _subScope.resolveAsync<T>(named: named);

  @override
  void teardown() {
    // subScope teardown не требуется
  }

  @override
  CherrypickDIAdapter openSubScope(String name) {
    return _CherrypickSubScopeAdapter(_subScope.openSubScope(name));
  }
}
