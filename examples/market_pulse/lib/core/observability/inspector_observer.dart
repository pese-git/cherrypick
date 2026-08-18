import 'package:cherrypick/cherrypick.dart';

import 'di_event.dart';
import 'inspector_cubit.dart';

/// Translates container callbacks into [InspectorCubit] updates.
///
/// Kept separate from the cubit because the two interfaces collide:
/// `BlocBase.onError(Object, StackTrace)` and
/// `CherryPickObserver.onError(String, Object?, StackTrace?)` are different
/// methods with the same name, so no single class can implement both. An
/// adapter is the plain fix — and it keeps the hot path free of bloc machinery.
class InspectorObserver implements CherryPickObserver {
  final InspectorCubit _cubit;

  InspectorObserver(this._cubit);

  @override
  void onBindingRegistered(String name, Type type, {String? scopeName}) =>
      _cubit.push(DiEventKind.binding, '$name → $type', scopeName: scopeName);

  @override
  void onInstanceRequested(String name, Type type, {String? scopeName}) =>
      _cubit.push(
        DiEventKind.request,
        'resolve<$type>($name)',
        scopeName: scopeName,
      );

  @override
  void onInstanceCreated(
    String name,
    Type type,
    Object instance, {
    String? scopeName,
  }) {
    final isNewInstance = _cubit.recordResolve(type, instance);

    _cubit.push(
      isNewInstance ? DiEventKind.created : DiEventKind.reused,
      isNewInstance ? '$type created' : '$type reused',
      scopeName: scopeName,
    );
  }

  @override
  void onInstanceDisposed(
    String name,
    Type type,
    Object instance, {
    String? scopeName,
  }) {
    _cubit.recordDispose();
    _cubit.push(DiEventKind.disposed, '$type disposed', scopeName: scopeName);
  }

  @override
  void onModulesInstalled(List<String> moduleNames, {String? scopeName}) =>
      _cubit.push(
        DiEventKind.module,
        'installed ${moduleNames.join(', ')}',
        scopeName: scopeName,
      );

  @override
  void onModulesRemoved(List<String> moduleNames, {String? scopeName}) =>
      _cubit.push(
        DiEventKind.module,
        'dropped ${moduleNames.join(', ')}',
        scopeName: scopeName,
      );

  @override
  void onScopeOpened(String name) =>
      _cubit.push(DiEventKind.scope, 'scope opened', scopeName: name);

  @override
  void onScopeClosed(String name) =>
      _cubit.push(DiEventKind.scope, 'scope closed', scopeName: name);

  @override
  void onCycleDetected(List<String> chain, {String? scopeName}) {
    _cubit.recordCycle(chain);
    _cubit.push(DiEventKind.cycle, chain.join(' → '), scopeName: scopeName);
  }

  // The container declares these hooks but has no call sites for them yet, so
  // they never fire today. Wired up anyway: the day they start firing, the
  // Inspector reports them without another change here.
  @override
  void onCacheHit(String name, Type type, {String? scopeName}) => _cubit.push(
    DiEventKind.cacheHit,
    '$type served from cache',
    scopeName: scopeName,
  );

  @override
  void onCacheMiss(String name, Type type, {String? scopeName}) => _cubit.push(
    DiEventKind.cacheMiss,
    '$type not cached',
    scopeName: scopeName,
  );

  @override
  void onDiagnostic(String message, {Object? details}) =>
      _cubit.push(DiEventKind.diagnostic, message);

  @override
  void onWarning(String message, {Object? details}) =>
      _cubit.push(DiEventKind.warning, message);

  @override
  void onError(String message, Object? error, StackTrace? stackTrace) =>
      _cubit.push(DiEventKind.error, '$message: $error');
}
