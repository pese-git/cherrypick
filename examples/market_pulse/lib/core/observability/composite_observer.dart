import 'package:cherrypick/cherrypick.dart';

/// Fans every container event out to several observers.
///
/// Used to run the in-app [InspectorObserver] and `TalkerCherryPickObserver`
/// side by side: the Inspector renders the events, Talker writes them to the
/// log console. Observers compose — you do not have to choose one.
class CompositeCherryPickObserver implements CherryPickObserver {
  final List<CherryPickObserver> _observers;

  CompositeCherryPickObserver(this._observers);

  void _each(void Function(CherryPickObserver o) action) {
    for (final observer in _observers) {
      action(observer);
    }
  }

  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) =>
      _each((o) => o.onBindingRegistered(name, type, scopeName: scopeName));

  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) =>
      _each((o) => o.onInstanceRequested(name, type, scopeName: scopeName));

  @override
  void onInstanceCreated(
    String name,
    Type type,
    Object instance, {
    String? scopeName,
  }) => _each(
    (o) => o.onInstanceCreated(name, type, instance, scopeName: scopeName),
  );

  @override
  void onInstanceDisposed(
    String name,
    Type type,
    Object instance, {
    String? scopeName,
  }) => _each(
    (o) => o.onInstanceDisposed(name, type, instance, scopeName: scopeName),
  );

  @override
  void onModulesInstalled(List<String> moduleNames, {String? scopeName}) =>
      _each((o) => o.onModulesInstalled(moduleNames, scopeName: scopeName));

  @override
  void onModulesRemoved(List<String> moduleNames, {String? scopeName}) =>
      _each((o) => o.onModulesRemoved(moduleNames, scopeName: scopeName));

  @override
  void onScopeOpened(String name) => _each((o) => o.onScopeOpened(name));

  @override
  void onScopeClosed(String name) => _each((o) => o.onScopeClosed(name));

  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) =>
      _each((o) => o.onCycleDetected(chain, scopeName: scopeName));

  @override
  void onCacheHit(String name, Type type, {String? scopeName}) =>
      _each((o) => o.onCacheHit(name, type, scopeName: scopeName));

  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) =>
      _each((o) => o.onCacheMiss(name, type, scopeName: scopeName));

  @override
  void onDiagnostic(String message, {Object? details}) =>
      _each((o) => o.onDiagnostic(message, details: details));

  @override
  void onWarning(String message, {Object? details}) =>
      _each((o) => o.onWarning(message, details: details));

  @override
  void onError(String message, Object? error, StackTrace? stackTrace) =>
      _each((o) => o.onError(message, error, stackTrace));
}
