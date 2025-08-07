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
    // get_it не поддерживает scope, возвращаем новый инстанс
    return GetItAdapter();
  }

  @override
  Future<void> waitForAsyncReady() async {
    await _getIt.allReady();
  }
}
