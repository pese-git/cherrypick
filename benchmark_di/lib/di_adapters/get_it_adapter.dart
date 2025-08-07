import 'package:get_it/get_it.dart';
import 'di_adapter.dart';

class GetItAdapter implements DIAdapter {
  late GetIt _getIt;

  @override
  void setupDependencies(void Function(dynamic container) registration) {
    _getIt = GetIt.asNewInstance();
    registration(_getIt);
  }

  @override
  T resolve<T extends Object>({String? named}) => _getIt<T>(instanceName: named);

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async => _getIt<T>(instanceName: named);

  @override
  void teardown() => _getIt.reset();

  @override
  DIAdapter openSubScope(String name) {
    // Открываем новый scope и возвращаем адаптер, который в setupDependencies будет использовать init.
    return _GetItScopeAdapter(_getIt, name);
  }

  @override
  Future<void> waitForAsyncReady() async {
    await _getIt.allReady();
  }
}

class _GetItScopeAdapter implements DIAdapter {
  final GetIt _getIt;
  final String _scopeName;
  bool _scopePushed = false;
  void Function(dynamic container)? _pendingRegistration;

  _GetItScopeAdapter(this._getIt, this._scopeName);

  @override
  void setupDependencies(void Function(dynamic container) registration) {
    _pendingRegistration = registration;
    // Создаём scope через pushNewScope с init для правильной регистрации
    _getIt.pushNewScope(
      scopeName: _scopeName,
      init: (getIt) => _pendingRegistration?.call(getIt),
    );
    _scopePushed = true;
  }

  @override
  T resolve<T extends Object>({String? named}) => _getIt<T>(instanceName: named);

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async => _getIt<T>(instanceName: named);

  @override
  void teardown() {
    if (_scopePushed) {
      _getIt.popScope();
      _scopePushed = false;
    }
  }

  @override
  DIAdapter openSubScope(String name) {
    return _GetItScopeAdapter(_getIt, name);
  }

  @override
  Future<void> waitForAsyncReady() async {
    await _getIt.allReady();
  }
}
