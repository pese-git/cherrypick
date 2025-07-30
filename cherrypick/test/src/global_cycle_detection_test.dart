import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

void main() {
  group('Global Cycle Detection', () {
    setUp(() {
      // Сбрасываем состояние перед каждым тестом
      CherryPick.closeRootScope();
      CherryPick.disableGlobalCycleDetection();
      CherryPick.disableGlobalCrossScopeCycleDetection();
      CherryPick.clearGlobalCycleDetector();
    });

    tearDown(() {
      // Очищаем состояние после каждого теста
      CherryPick.closeRootScope();
      CherryPick.disableGlobalCycleDetection();
      CherryPick.disableGlobalCrossScopeCycleDetection();
      CherryPick.clearGlobalCycleDetector();
    });

    group('Global Cross-Scope Cycle Detection', () {
      test('should enable global cross-scope cycle detection', () {
        expect(CherryPick.isGlobalCrossScopeCycleDetectionEnabled, isFalse);
        
        CherryPick.enableGlobalCrossScopeCycleDetection();
        
        expect(CherryPick.isGlobalCrossScopeCycleDetectionEnabled, isTrue);
      });

      test('should disable global cross-scope cycle detection', () {
        CherryPick.enableGlobalCrossScopeCycleDetection();
        expect(CherryPick.isGlobalCrossScopeCycleDetectionEnabled, isTrue);
        
        CherryPick.disableGlobalCrossScopeCycleDetection();
        
        expect(CherryPick.isGlobalCrossScopeCycleDetectionEnabled, isFalse);
      });

      test('should automatically enable global cycle detection for new root scope', () {
        CherryPick.enableGlobalCrossScopeCycleDetection();
        
        final scope = CherryPick.openRootScope();
        
        expect(scope.isGlobalCycleDetectionEnabled, isTrue);
      });

      test('should automatically enable global cycle detection for existing root scope', () {
        final scope = CherryPick.openRootScope();
        expect(scope.isGlobalCycleDetectionEnabled, isFalse);
        
        CherryPick.enableGlobalCrossScopeCycleDetection();
        
        expect(scope.isGlobalCycleDetectionEnabled, isTrue);
      });
    });

    group('Global Safe Scope Creation', () {
      test('should create global safe root scope with both detections enabled', () {
        final scope = CherryPick.openGlobalSafeRootScope();
        
        expect(scope.isCycleDetectionEnabled, isTrue);
        expect(scope.isGlobalCycleDetectionEnabled, isTrue);
      });

      test('should create global safe sub-scope with both detections enabled', () {
        final scope = CherryPick.openGlobalSafeScope(scopeName: 'feature.global');
        
        expect(scope.isCycleDetectionEnabled, isTrue);
        expect(scope.isGlobalCycleDetectionEnabled, isTrue);
      });
    });

    group('Cross-Scope Circular Dependency Detection', () {
      test('should detect circular dependency across parent-child scopes', () {
        final parentScope = CherryPick.openGlobalSafeRootScope();
        parentScope.installModules([GlobalParentModule()]);

        final childScope = parentScope.openSubScope('child');
        childScope.installModules([GlobalChildModule()]);

        expect(
          () => parentScope.resolve<GlobalServiceA>(),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('should detect circular dependency in complex scope hierarchy', () {
        final rootScope = CherryPick.openGlobalSafeRootScope();
        final level1Scope = rootScope.openSubScope('level1');
        final level2Scope = level1Scope.openSubScope('level2');

        // Устанавливаем модули на разных уровнях
        rootScope.installModules([GlobalRootModule()]);
        level1Scope.installModules([GlobalLevel1Module()]);
        level2Scope.installModules([GlobalLevel2Module()]);

        expect(
          () => level2Scope.resolve<GlobalLevel2Service>(),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('should provide detailed global resolution chain in exception', () {
        final scope = CherryPick.openGlobalSafeRootScope();
        scope.installModules([GlobalParentModule()]);
        
        final childScope = scope.openSubScope('child');
        childScope.installModules([GlobalChildModule()]);

        try {
          scope.resolve<GlobalServiceA>();
          fail('Expected CircularDependencyException');
        } catch (e) {
          expect(e, isA<CircularDependencyException>());
          final circularError = e as CircularDependencyException;
          
          // Проверяем, что цепочка содержит информацию о скоупах
          expect(circularError.dependencyChain, isNotEmpty);
          expect(circularError.dependencyChain.length, greaterThan(1));
          
          // Цепочка должна содержать оба сервиса
          final chainString = circularError.dependencyChain.join(' -> ');
          expect(chainString, contains('GlobalServiceA'));
          expect(chainString, contains('GlobalServiceB'));
        }
      });

      test('should track global resolution chain', () {
        final scope = CherryPick.openGlobalSafeRootScope();
        scope.installModules([SimpleGlobalModule()]);

        // До разрешения цепочка должна быть пустой
        expect(CherryPick.getGlobalResolutionChain(), isEmpty);

        final service = scope.resolve<SimpleGlobalService>();
        expect(service, isA<SimpleGlobalService>());

        // После разрешения цепочка должна быть очищена
        expect(CherryPick.getGlobalResolutionChain(), isEmpty);
      });

      test('should clear global cycle detector state', () {
        CherryPick.enableGlobalCrossScopeCycleDetection();
        // ignore: unused_local_variable
        final scope = CherryPick.openGlobalSafeRootScope();
        
        expect(CherryPick.getGlobalResolutionChain(), isEmpty);
        
        CherryPick.clearGlobalCycleDetector();
        
        // После очистки детектор должен быть сброшен
        expect(CherryPick.getGlobalResolutionChain(), isEmpty);
      });
    });

    group('Inheritance of Global Settings', () {
      test('should inherit global cycle detection in child scopes', () {
        CherryPick.enableGlobalCrossScopeCycleDetection();
        
        final parentScope = CherryPick.openRootScope();
        final childScope = parentScope.openSubScope('child');
        
        expect(parentScope.isGlobalCycleDetectionEnabled, isTrue);
        expect(childScope.isGlobalCycleDetectionEnabled, isTrue);
      });

      test('should inherit both local and global cycle detection', () {
        CherryPick.enableGlobalCycleDetection();
        CherryPick.enableGlobalCrossScopeCycleDetection();
        
        final scope = CherryPick.openScope(scopeName: 'feature.test');
        
        expect(scope.isCycleDetectionEnabled, isTrue);
        expect(scope.isGlobalCycleDetectionEnabled, isTrue);
      });
    });
  });
}

// Test services for global circular dependency testing

class GlobalServiceA {
  final GlobalServiceB serviceB;
  GlobalServiceA(this.serviceB);
}

class GlobalServiceB {
  final GlobalServiceA serviceA;
  GlobalServiceB(this.serviceA);
}

class GlobalParentModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<GlobalServiceA>().toProvide(() {
      // Получаем сервис B из дочернего скоупа
      final childScope = currentScope.openSubScope('child');
      return GlobalServiceA(childScope.resolve<GlobalServiceB>());
    });
  }
}

class GlobalChildModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<GlobalServiceB>().toProvide(() {
      // Получаем сервис A из родительского скоупа
      final parentScope = currentScope.parentScope!;
      return GlobalServiceB(parentScope.resolve<GlobalServiceA>());
    });
  }
}

// Services for complex hierarchy testing

class GlobalRootService {
  final GlobalLevel1Service level1Service;
  GlobalRootService(this.level1Service);
}

class GlobalLevel1Service {
  final GlobalLevel2Service level2Service;
  GlobalLevel1Service(this.level2Service);
}

class GlobalLevel2Service {
  final GlobalRootService rootService;
  GlobalLevel2Service(this.rootService);
}

class GlobalRootModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<GlobalRootService>().toProvide(() {
      final level1Scope = currentScope.openSubScope('level1');
      return GlobalRootService(level1Scope.resolve<GlobalLevel1Service>());
    });
  }
}

class GlobalLevel1Module extends Module {
  @override
  void builder(Scope currentScope) {
    bind<GlobalLevel1Service>().toProvide(() {
      final level2Scope = currentScope.openSubScope('level2');
      return GlobalLevel1Service(level2Scope.resolve<GlobalLevel2Service>());
    });
  }
}

class GlobalLevel2Module extends Module {
  @override
  void builder(Scope currentScope) {
    bind<GlobalLevel2Service>().toProvide(() {
      // Идем к корневому скоупу через цепочку родителей
      var rootScope = currentScope.parentScope?.parentScope;
      return GlobalLevel2Service(rootScope!.resolve<GlobalRootService>());
    });
  }
}

// Simple service for non-circular testing

class SimpleGlobalService {
  SimpleGlobalService();
}

class SimpleGlobalModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<SimpleGlobalService>().toProvide(() => SimpleGlobalService());
  }
}
