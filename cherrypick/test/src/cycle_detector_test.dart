import 'package:cherrypick/src/cycle_detector.dart';
import 'package:cherrypick/src/module.dart';
import 'package:cherrypick/src/scope.dart';
import 'package:test/test.dart';

void main() {
  group('CycleDetector', () {
    late CycleDetector detector;

    setUp(() {
      detector = CycleDetector();
    });

    test('should detect simple circular dependency', () {
      detector.startResolving<String>();
      
      expect(
        () => detector.startResolving<String>(),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('should detect circular dependency with named bindings', () {
      detector.startResolving<String>(named: 'test');
      
      expect(
        () => detector.startResolving<String>(named: 'test'),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('should allow different types to be resolved simultaneously', () {
      detector.startResolving<String>();
      detector.startResolving<int>();
      
      expect(() => detector.finishResolving<int>(), returnsNormally);
      expect(() => detector.finishResolving<String>(), returnsNormally);
    });

    test('should detect complex circular dependency chain', () {
      detector.startResolving<String>();
      detector.startResolving<int>();
      detector.startResolving<bool>();
      
      expect(
        () => detector.startResolving<String>(),
        throwsA(predicate((e) => 
          e is CircularDependencyException &&
          e.dependencyChain.contains('String') &&
          e.dependencyChain.length > 1
        )),
      );
    });

    test('should clear state properly', () {
      detector.startResolving<String>();
      detector.clear();
      
      expect(() => detector.startResolving<String>(), returnsNormally);
    });

    test('should track resolution history correctly', () {
      detector.startResolving<String>();
      detector.startResolving<int>();
      
      expect(detector.currentResolutionChain, contains('String'));
      expect(detector.currentResolutionChain, contains('int'));
      expect(detector.currentResolutionChain.length, equals(2));
      
      detector.finishResolving<int>();
      expect(detector.currentResolutionChain.length, equals(1));
      expect(detector.currentResolutionChain, contains('String'));
    });
  });

  group('Scope with Cycle Detection', () {
    test('should detect circular dependency in real scenario', () {
      final scope = Scope(null);
      scope.enableCycleDetection();
      
      // Создаем циклическую зависимость: A зависит от B, B зависит от A
      scope.installModules([
        CircularModuleA(),
        CircularModuleB(),
      ]);

      expect(
        () => scope.resolve<ServiceA>(),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('should work normally without cycle detection enabled', () {
      final scope = Scope(null);
      // Не включаем обнаружение циклических зависимостей
      
      scope.installModules([
        SimpleModule(),
      ]);

      expect(() => scope.resolve<SimpleService>(), returnsNormally);
      expect(scope.resolve<SimpleService>(), isA<SimpleService>());
    });

    test('should allow disabling cycle detection', () {
      final scope = Scope(null);
      scope.enableCycleDetection();
      expect(scope.isCycleDetectionEnabled, isTrue);
      
      scope.disableCycleDetection();
      expect(scope.isCycleDetectionEnabled, isFalse);
    });

    test('should handle named dependencies in cycle detection', () {
      final scope = Scope(null);
      scope.enableCycleDetection();
      
      scope.installModules([
        NamedCircularModule(),
      ]);

      expect(
        () => scope.resolve<String>(named: 'circular'),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('should detect cycles in async resolution', () async {
      final scope = Scope(null);
      scope.enableCycleDetection();
      
      scope.installModules([
        AsyncCircularModule(),
      ]);

      expect(
        () => scope.resolveAsync<AsyncServiceA>(),
        throwsA(isA<CircularDependencyException>()),
      );
    });
  });
}

// Test services and modules for circular dependency testing

class ServiceA {
  final ServiceB serviceB;
  ServiceA(this.serviceB);
}

class ServiceB {
  final ServiceA serviceA;
  ServiceB(this.serviceA);
}

class CircularModuleA extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ServiceA>().toProvide(() => ServiceA(currentScope.resolve<ServiceB>()));
  }
}

class CircularModuleB extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ServiceB>().toProvide(() => ServiceB(currentScope.resolve<ServiceA>()));
  }
}

class SimpleService {
  SimpleService();
}

class SimpleModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<SimpleService>().toProvide(() => SimpleService());
  }
}

class NamedCircularModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<String>()
        .withName('circular')
        .toProvide(() => currentScope.resolve<String>(named: 'circular'));
  }
}

class AsyncServiceA {
  final AsyncServiceB serviceB;
  AsyncServiceA(this.serviceB);
}

class AsyncServiceB {
  final AsyncServiceA serviceA;
  AsyncServiceB(this.serviceA);
}

class AsyncCircularModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<AsyncServiceA>().toProvideAsync(() async {
      final serviceB = await currentScope.resolveAsync<AsyncServiceB>();
      return AsyncServiceA(serviceB);
    });
    
    bind<AsyncServiceB>().toProvideAsync(() async {
      final serviceA = await currentScope.resolveAsync<AsyncServiceA>();
      return AsyncServiceB(serviceA);
    });
  }
}
