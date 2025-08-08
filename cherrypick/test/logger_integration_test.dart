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
  late MockLogger logger;

  setUp(() {
    logger = MockLogger();
  });

  test('Global logger receives Scope and Binding events', () {
    final scope = Scope(null, logger: logger);
    scope.installModules([DummyModule()]);
    final _ = scope.resolve<DummyService>(named: 'test');

    expect(logger.infos.any((m) => m.contains('Scope created')), isTrue);
    expect(logger.infos.any((m) => m.contains('Binding<DummyService> created')), isTrue);
    expect(logger.infos.any((m) =>
        m.contains('Binding<DummyService> named as [test]') || m.contains('named as [test]')), isTrue);
    expect(logger.infos.any((m) =>
        m.contains('Resolve<DummyService> [named=test]: successfully resolved') ||
        m.contains('Resolve<DummyService> [named=test]: successfully resolved in scope')), isTrue);
  });

  test('CycleDetector logs cycle detection error', () {
    final scope = Scope(null, logger: logger);
    scope.enableCycleDetection();
    scope.installModules([CyclicModule()]);
    expect(
      () => scope.resolve<A>(),
      throwsA(isA<CircularDependencyException>()),
    );
    expect(
      logger.errors.any((m) =>
        m.contains('CYCLE DETECTED!') || m.contains('Circular dependency detected')),
      isTrue,
    );
  });
}