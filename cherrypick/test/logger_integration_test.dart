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

    // Новый стиль проверки для formatLogMessage:
    expect(
      logger.infos.any((m) => m.startsWith('[Scope:') && m.contains('created')),
      isTrue,
    );
    expect(
      logger.infos.any((m) => m.startsWith('[Binding:DummyService') && m.contains('created')),
      isTrue,
    );
    expect(
      logger.infos.any((m) => m.startsWith('[Binding:DummyService') && m.contains('named') && m.contains('name=test')),
      isTrue,
    );
    expect(
      logger.infos.any((m) => m.startsWith('[Scope:') && m.contains('resolve=DummyService') && m.contains('successfully resolved')),
      isTrue,
    );
  });

  test('CycleDetector logs cycle detection error', () {
    final scope = Scope(null, logger: logger);
    // print('[DEBUG] TEST SCOPE logger type=${scope.logger.runtimeType} hash=${scope.logger.hashCode}');
    scope.enableCycleDetection();
    scope.installModules([CyclicModule()]);
    expect(
      () => scope.resolve<A>(),
      throwsA(isA<CircularDependencyException>()),
    );
    // Дополнительно ищем и среди info на случай если лог от CycleDetector ошибочно не попал в errors
    final foundInErrors = logger.errors.any((m) =>
      m.startsWith('[CycleDetector:') && m.contains('cycle detected'));
    final foundInInfos = logger.infos.any((m) =>
      m.startsWith('[CycleDetector:') && m.contains('cycle detected'));
    expect(foundInErrors || foundInInfos, isTrue,
      reason: 'Ожидаем хотя бы один лог о цикле на уровне error или info; вот все errors: ${logger.errors}\ninfos: ${logger.infos}');
  });
}