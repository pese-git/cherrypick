import 'package:cherrypick/cherrypick.dart';

class MockObserver implements CherryPickObserver {
  final List<String> diagnostics = [];
  final List<String> warnings = [];
  final List<String> errors = [];
  final List<List<String>> cycles = [];
  final List<String> bindings = [];

  @override
  void onDiagnostic(String message, {Object? details}) =>
      diagnostics.add(message);

  @override
  void onWarning(String message, {Object? details}) => warnings.add(message);

  @override
  void onError(String message, Object? error, StackTrace? stackTrace) => errors.add(
      '$message${error != null ? ' $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}');

  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) =>
      cycles.add(chain);

  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) =>
      bindings.add('$name $type');

  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) {}
  @override
  void onInstanceCreated(String name, Type type, Object instance,
      {String? scopeName}) {}
  @override
  void onInstanceDisposed(String name, Type type, Object instance,
      {String? scopeName}) {}
  @override
  void onModulesInstalled(List<String> moduleNames, {String? scopeName}) {}
  @override
  void onModulesRemoved(List<String> moduleNames, {String? scopeName}) {}
  @override
  void onScopeOpened(String name) {}
  @override
  void onScopeClosed(String name) {}
  @override
  void onCacheHit(String name, Type type, {String? scopeName}) {}
  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) {}
}
