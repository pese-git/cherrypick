import 'package:cherrypick/cherrypick.dart';
import 'di_adapter.dart';

/// Универсальный DIAdapter для CherryPick с поддержкой subScope без дублирования логики.
class CherrypickDIAdapter extends DIAdapter<Scope> {
  Scope? _scope;
  final bool _isSubScope;

  CherrypickDIAdapter([Scope? scope, this._isSubScope = false]) {
    _scope = scope;
  }

  @override
  void setupDependencies(void Function(Scope container) registration) {
    _scope ??= CherryPick.openRootScope();
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
    if (!_isSubScope) {
      CherryPick.closeRootScope();
      _scope = null;
    }
    // SubScope teardown не требуется
  }

  @override
  CherrypickDIAdapter openSubScope(String name) {
    return CherrypickDIAdapter(_scope!.openSubScope(name), true);
  }

  @override
  Future<void> waitForAsyncReady() async {}
}
