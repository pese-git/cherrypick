/// Observer for DI container (CherryPick): lifecycle, cache, modules, errors, etc.
abstract class CherryPickObserver {
  // === Registration and instance lifecycle ===
  void onBindingRegistered(String name, Type type, {String? scopeName});
  void onInstanceRequested(String name, Type type, {String? scopeName});
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName});
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName});

  // === Module events ===
  void onModulesInstalled(List<String> moduleNames, {String? scopeName});
  void onModulesRemoved(List<String> moduleNames, {String? scopeName});

  // === Scope lifecycle ===
  void onScopeOpened(String name);
  void onScopeClosed(String name);

  // === Cycle detection ===
  void onCycleDetected(List<String> chain, {String? scopeName});

  // === Cache events ===
  void onCacheHit(String name, Type type, {String? scopeName});
  void onCacheMiss(String name, Type type, {String? scopeName});

  // === Диагностика ===
  void onDiagnostic(String message, {Object? details});

  // === Warnings & errors ===
  void onWarning(String message, {Object? details});
  void onError(String message, Object? error, StackTrace? stackTrace);
}

/// Diagnostic/Debug observer that prints all events
class PrintCherryPickObserver implements CherryPickObserver {
  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) =>
      print('[binding][CherryPick] $name — $type (scope: $scopeName)');

  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) =>
      print('[request][CherryPick] $name — $type (scope: $scopeName)');

  @override
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName}) =>
      print('[create][CherryPick] $name — $type => $instance (scope: $scopeName)');

  @override
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName}) =>
      print('[dispose][CherryPick] $name — $type => $instance (scope: $scopeName)');

  @override
  void onModulesInstalled(List<String> modules, {String? scopeName}) =>
      print('[modules installed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');
  @override
  void onModulesRemoved(List<String> modules, {String? scopeName}) =>
      print('[modules removed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');

  @override
  void onScopeOpened(String name) => print('[scope opened][CherryPick] $name');

  @override
  void onScopeClosed(String name) => print('[scope closed][CherryPick] $name');

  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) =>
      print('[cycle][CherryPick] Detected: ${chain.join(' -> ')}${scopeName != null ? ' (scope: $scopeName)' : ''}');

  @override
  void onCacheHit(String name, Type type, {String? scopeName}) =>
      print('[cache hit][CherryPick] $name — $type (scope: $scopeName)');
  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) =>
      print('[cache miss][CherryPick] $name — $type (scope: $scopeName)');

  @override
  void onDiagnostic(String message, {Object? details}) =>
      print('[diagnostic][CherryPick] $message ${details ?? ''}');

  @override
  void onWarning(String message, {Object? details}) =>
      print('[warn][CherryPick] $message ${details ?? ''}');
  @override
  void onError(String message, Object? error, StackTrace? stackTrace) {
    print('[error][CherryPick] $message');
    if (error != null) print('  error: $error');
    if (stackTrace != null) print('  stack: $stackTrace');
  }
}

/// Silent observer: игнорирует все события
class SilentCherryPickObserver implements CherryPickObserver {
  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) {}
  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) {}
  @override
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName}) {}
  @override
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName}) {}
  @override
  void onModulesInstalled(List<String> modules, {String? scopeName}) {}
  @override
  void onModulesRemoved(List<String> modules, {String? scopeName}) {}
  @override
  void onScopeOpened(String name) {}
  @override
  void onScopeClosed(String name) {}
  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) {}
  @override
  void onCacheHit(String name, Type type, {String? scopeName}) {}
  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) {}
  @override
  void onDiagnostic(String message, {Object? details}) {}
  @override
  void onWarning(String message, {Object? details}) {}
  @override
  void onError(String message, Object? error, StackTrace? stackTrace) {}
}
