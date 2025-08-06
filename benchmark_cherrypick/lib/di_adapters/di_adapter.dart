import 'package:cherrypick/cherrypick.dart';

/// Abstraction for Dependency Injection (DI) Adapter.
///
/// Provides a uniform interface to setup, resolve, and teardown DI containers/modules
/// and open sub-scopes to benchmark them under different libraries.
abstract class DIAdapter {
  /// Installs the provided modules into the DI container.
  void setupModules(List<Module> modules);

  /// Resolves an instance of type [T] by optional [named] tag.
  T resolve<T>({String? named});

  /// Asynchronously resolves an instance of type [T] by optional [named] tag.
  Future<T> resolveAsync<T>({String? named});

  /// Tears down or disposes of the DI container.
  void teardown();

  /// Opens a child DI sub-scope, useful for override/child-scope benchmarks.
  DIAdapter openSubScope(String name);
}
