import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';
import '../mock_logger.dart';
import 'package:cherrypick/cherrypick.dart';

void main() {
  late MockLogger logger;
  setUp(() {
    logger = MockLogger();
    CherryPick.setGlobalLogger(logger);
  });
  group('CherryPick Cycle Detection Helper Methods', () {
    setUp(() {
      // Сбрасываем состояние перед каждым тестом
      CherryPick.closeRootScope();
      CherryPick.disableGlobalCycleDetection();
    });

    tearDown(() {
      // Очищаем состояние после каждого теста
      CherryPick.closeRootScope();
      CherryPick.disableGlobalCycleDetection();
    });

    group('Global Cycle Detection', () {
      test('should enable global cycle detection', () {
        expect(CherryPick.isGlobalCycleDetectionEnabled, isFalse);
        
        CherryPick.enableGlobalCycleDetection();
        
        expect(CherryPick.isGlobalCycleDetectionEnabled, isTrue);
      });

      test('should disable global cycle detection', () {
        CherryPick.enableGlobalCycleDetection();
        expect(CherryPick.isGlobalCycleDetectionEnabled, isTrue);
        
        CherryPick.disableGlobalCycleDetection();
        
        expect(CherryPick.isGlobalCycleDetectionEnabled, isFalse);
      });

      test('should automatically enable cycle detection for new root scope when global is enabled', () {
        CherryPick.enableGlobalCycleDetection();
        
        final scope = CherryPick.openRootScope();
        
        expect(scope.isCycleDetectionEnabled, isTrue);
      });

      test('should automatically enable cycle detection for existing root scope when global is enabled', () {
        final scope = CherryPick.openRootScope();
        expect(scope.isCycleDetectionEnabled, isFalse);
        
        CherryPick.enableGlobalCycleDetection();
        
        expect(scope.isCycleDetectionEnabled, isTrue);
      });

      test('should automatically disable cycle detection for existing root scope when global is disabled', () {
        CherryPick.enableGlobalCycleDetection();
        final scope = CherryPick.openRootScope();
        expect(scope.isCycleDetectionEnabled, isTrue);
        
        CherryPick.disableGlobalCycleDetection();
        
        expect(scope.isCycleDetectionEnabled, isFalse);
      });

      test('should apply global setting to sub-scopes', () {
        CherryPick.enableGlobalCycleDetection();
        
        final scope = CherryPick.openScope(scopeName: 'test.subscope');
        
        expect(scope.isCycleDetectionEnabled, isTrue);
      });
    });

    group('Scope-specific Cycle Detection', () {
      test('should enable cycle detection for root scope', () {
        final scope = CherryPick.openRootScope();
        expect(scope.isCycleDetectionEnabled, isFalse);
        
        CherryPick.enableCycleDetectionForScope();
        
        expect(CherryPick.isCycleDetectionEnabledForScope(), isTrue);
        expect(scope.isCycleDetectionEnabled, isTrue);
      });

      test('should disable cycle detection for root scope', () {
        CherryPick.enableCycleDetectionForScope();
        expect(CherryPick.isCycleDetectionEnabledForScope(), isTrue);
        
        CherryPick.disableCycleDetectionForScope();
        
        expect(CherryPick.isCycleDetectionEnabledForScope(), isFalse);
      });

      test('should enable cycle detection for specific scope', () {
        final scopeName = 'feature.auth';
        CherryPick.openScope(scopeName: scopeName);
        
        expect(CherryPick.isCycleDetectionEnabledForScope(scopeName: scopeName), isFalse);
        
        CherryPick.enableCycleDetectionForScope(scopeName: scopeName);
        
        expect(CherryPick.isCycleDetectionEnabledForScope(scopeName: scopeName), isTrue);
      });

      test('should disable cycle detection for specific scope', () {
        final scopeName = 'feature.auth';
        CherryPick.enableCycleDetectionForScope(scopeName: scopeName);
        expect(CherryPick.isCycleDetectionEnabledForScope(scopeName: scopeName), isTrue);
        
        CherryPick.disableCycleDetectionForScope(scopeName: scopeName);
        
        expect(CherryPick.isCycleDetectionEnabledForScope(scopeName: scopeName), isFalse);
      });
    });

    group('Safe Scope Creation', () {
      test('should create safe root scope with cycle detection enabled', () {
        final scope = CherryPick.openSafeRootScope();
        
        expect(scope.isCycleDetectionEnabled, isTrue);
      });

      test('should create safe sub-scope with cycle detection enabled', () {
        final scope = CherryPick.openSafeScope(scopeName: 'feature.safe');
        
        expect(scope.isCycleDetectionEnabled, isTrue);
      });

      test('safe scope should work independently of global setting', () {
        // Глобальная настройка отключена
        expect(CherryPick.isGlobalCycleDetectionEnabled, isFalse);
        
        final scope = CherryPick.openSafeScope(scopeName: 'feature.independent');
        
        expect(scope.isCycleDetectionEnabled, isTrue);
      });
    });

    group('Resolution Chain Tracking', () {
      test('should return empty resolution chain for scope without cycle detection', () {
        CherryPick.openRootScope();
        
        final chain = CherryPick.getCurrentResolutionChain();
        
        expect(chain, isEmpty);
      });

      test('should return empty resolution chain for scope with cycle detection but no active resolution', () {
        CherryPick.enableCycleDetectionForScope();
        
        final chain = CherryPick.getCurrentResolutionChain();
        
        expect(chain, isEmpty);
      });

      test('should track resolution chain for specific scope', () {
        final scopeName = 'feature.tracking';
        CherryPick.enableCycleDetectionForScope(scopeName: scopeName);
        
        final chain = CherryPick.getCurrentResolutionChain(scopeName: scopeName);
        
        expect(chain, isEmpty); // Пустая, так как нет активного разрешения
      });
    });

    group('Integration with Circular Dependencies', () {
      test('should detect circular dependency with global cycle detection enabled', () {
        CherryPick.enableGlobalCycleDetection();
        
        final scope = CherryPick.openRootScope();
        scope.installModules([CircularTestModule()]);
        
        expect(
          () => scope.resolve<CircularServiceA>(),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('should detect circular dependency with safe scope', () {
        final scope = CherryPick.openSafeRootScope();
        scope.installModules([CircularTestModule()]);
        
        expect(
          () => scope.resolve<CircularServiceA>(),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('should not detect circular dependency when cycle detection is disabled', () {
        final scope = CherryPick.openRootScope();
        scope.installModules([CircularTestModule()]);
        
        // Без обнаружения циклических зависимостей не будет выброшено CircularDependencyException,
        // но может произойти StackOverflowError при попытке создания объекта
        expect(() => scope.resolve<CircularServiceA>(), 
               throwsA(isA<StackOverflowError>()));
      });
    });

    group('Scope Name Handling', () {
      test('should handle empty scope name as root scope', () {
        CherryPick.enableCycleDetectionForScope(scopeName: '');
        
        expect(CherryPick.isCycleDetectionEnabledForScope(scopeName: ''), isTrue);
        expect(CherryPick.isCycleDetectionEnabledForScope(), isTrue);
      });

      test('should handle complex scope names', () {
        final complexScopeName = 'app.feature.auth.login';
        CherryPick.enableCycleDetectionForScope(scopeName: complexScopeName);
        
        expect(CherryPick.isCycleDetectionEnabledForScope(scopeName: complexScopeName), isTrue);
      });

      test('should handle custom separator', () {
        final scopeName = 'app/feature/auth';
        CherryPick.enableCycleDetectionForScope(scopeName: scopeName, separator: '/');
        
        expect(CherryPick.isCycleDetectionEnabledForScope(scopeName: scopeName, separator: '/'), isTrue);
      });
    });
  });
}

// Test services for circular dependency testing
class CircularServiceA {
  final CircularServiceB serviceB;
  CircularServiceA(this.serviceB);
}

class CircularServiceB {
  final CircularServiceA serviceA;
  CircularServiceB(this.serviceA);
}

class CircularTestModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<CircularServiceA>().toProvide(() => CircularServiceA(currentScope.resolve<CircularServiceB>()));
    bind<CircularServiceB>().toProvide(() => CircularServiceB(currentScope.resolve<CircularServiceA>()));
  }
}
