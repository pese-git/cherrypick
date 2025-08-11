import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';
import 'mock_logger.dart';

class DummyService {}

class DummyModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<DummyService>().toInstance(DummyService()).withName('test');
  }
}

class A {}
class B {}

class CyclicModule extends Module {
  @override
  void builder(Scope cs) {
    bind<A>().toProvide(() => cs.resolve<B>() as A);
    bind<B>().toProvide(() => cs.resolve<A>() as B);
  }
}

void main() {
  late MockObserver observer;

  setUp(() {
    observer = MockObserver();
  });

  test('Global logger receives Binding events', () {
    final scope = Scope(null, observer: observer);
    scope.installModules([DummyModule()]);
    final _ = scope.resolve<DummyService>(named: 'test');

    // Проверяем, что биндинг DummyService зарегистрирован
    expect(
      observer.bindings.any((m) => m.contains('DummyService')),
      isTrue,
    );
    // Можно добавить проверки diagnostics, если Scope что-то пишет туда
  });

  test('CycleDetector logs cycle detection error', () {
    final scope = Scope(null, observer: observer);
    // print('[DEBUG] TEST SCOPE logger type=${scope.logger.runtimeType} hash=${scope.logger.hashCode}');
    scope.enableCycleDetection();
    scope.installModules([CyclicModule()]);
    expect(
      () => scope.resolve<A>(),
      throwsA(isA<CircularDependencyException>()),
    );
    // Проверяем, что цикл зафиксирован либо в errors, либо в diagnostics либо cycles
    final foundInErrors = observer.errors.any((m) => m.contains('cycle detected'));
    final foundInDiagnostics = observer.diagnostics.any((m) => m.contains('cycle detected'));
    final foundCycleNotified = observer.cycles.isNotEmpty;
    expect(foundInErrors || foundInDiagnostics || foundCycleNotified, isTrue,
      reason: 'Ожидаем хотя бы один лог о цикле! errors: ${observer.errors}\ndiag: ${observer.diagnostics}\ncycles: ${observer.cycles}');
  });
}