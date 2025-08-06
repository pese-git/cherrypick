import 'package:cherrypick/cherrypick.dart';

abstract class DIAdapter {
  void setupModules(List<Module> modules);
  T resolve<T>({String? named});
  Future<T> resolveAsync<T>({String? named});
  void teardown();
  DIAdapter openSubScope(String name);
}
