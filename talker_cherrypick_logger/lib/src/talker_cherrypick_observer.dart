import 'package:cherrypick/cherrypick.dart';
import 'package:talker/talker.dart';

/// CherryPickObserver-адаптер для логирования событий CherryPick через Talker
class TalkerCherryPickObserver implements CherryPickObserver {
  final Talker talker;

  TalkerCherryPickObserver(this.talker);

  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) {
    talker.info('[binding][CherryPick] $name — $type (scope: $scopeName)');
  }
  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) {
    talker.info('[request][CherryPick] $name — $type (scope: $scopeName)');
  }
  @override
  void onInstanceCreated(String name, Type type, Object instance, {String? scopeName}) {
    talker.info('[create][CherryPick] $name — $type => $instance (scope: $scopeName)');
  }
  @override
  void onInstanceDisposed(String name, Type type, Object instance, {String? scopeName}) {
    talker.info('[dispose][CherryPick] $name — $type => $instance (scope: $scopeName)');
  }
  @override
  void onModulesInstalled(List<String> modules, {String? scopeName}) {
    talker.info('[modules installed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');
  }
  @override
  void onModulesRemoved(List<String> modules, {String? scopeName}) {
    talker.info('[modules removed][CherryPick] ${modules.join(', ')} (scope: $scopeName)');
  }
  @override
  void onScopeOpened(String name) {
    talker.info('[scope opened][CherryPick] $name');
  }
  @override
  void onScopeClosed(String name) {
    talker.info('[scope closed][CherryPick] $name');
  }
  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) {
    talker.warning('[cycle][CherryPick] Detected: ${chain.join(' -> ')}${scopeName != null ? ' (scope: $scopeName)' : ''}');
  }
  @override
  void onCacheHit(String name, Type type, {String? scopeName}) {
    talker.info('[cache hit][CherryPick] $name — $type (scope: $scopeName)');
  }
  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) {
    talker.info('[cache miss][CherryPick] $name — $type (scope: $scopeName)');
  }
  @override
  void onDiagnostic(String message, {Object? details}) {
    talker.verbose('[diagnostic][CherryPick] $message ${details ?? ''}');
  }
  @override
  void onWarning(String message, {Object? details}) {
    talker.warning('[warn][CherryPick] $message ${details ?? ''}');
  }
  @override
  void onError(String message, Object? error, StackTrace? stackTrace) {
    talker.handle(error ?? '[CherryPick] $message', stackTrace, '[error][CherryPick] $message');
  }
}
