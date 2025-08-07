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
}
