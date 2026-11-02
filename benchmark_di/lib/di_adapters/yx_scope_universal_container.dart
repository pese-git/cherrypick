import 'package:yx_scope/yx_scope.dart';

/// Universal container for dynamic DI registration in yx_scope (for benchmarks).
/// Allows to register and resolve deps by name/type at runtime.
class UniversalYxScopeContainer extends ScopeContainer {
  final Map<Type, Map<String, Dep<dynamic>>> _namedDeps = {};
  final Map<Type, Dep<dynamic>> _typedDeps = {};

  void register<T>(Dep<T> dep, {String? name}) {
    if (name != null) {
      _namedDeps.putIfAbsent(T, () => {})[name] = dep;
    } else {
      _typedDeps[T] = dep;
    }
  }

  Dep<T> depFor<T>({String? name}) {
    if (name != null) {
      final dep = _namedDeps[T]?[name];
      if (dep is Dep<T>) return dep;
      throw Exception('No dep for type $T/$name');
    } else {
      final dep = _typedDeps[T];
      if (dep is Dep<T>) return dep;
      throw Exception('No dep for type $T');
    }
  }
}