import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

void main() {
  group('Cross-Scope Circular Dependency Detection', () {
    tearDown(() {
      CherryPick.closeRootScope();
      CherryPick.disableGlobalCycleDetection();
    });

    test('should detect circular dependency across parent-child scopes', () {
      // Создаем родительский скоуп с сервисом A
      final parentScope = CherryPick.openSafeRootScope();
      parentScope.installModules([ParentScopeModule()]);

      // Создаем дочерний скоуп с сервисом B, который зависит от A
      final childScope = parentScope.openSubScope('child');
      childScope.enableCycleDetection();
      childScope.installModules([ChildScopeModule()]);

      // Сервис A в родительском скоупе пытается получить сервис B из дочернего скоупа
      // Это создает циклическую зависимость между скоупами
      expect(
        () => parentScope.resolve<CrossScopeServiceA>(),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test('should detect circular dependency in complex scope hierarchy', () {
      final rootScope = CherryPick.openSafeRootScope();
      final level1Scope = rootScope.openSubScope('level1');
      final level2Scope = level1Scope.openSubScope('level2');

      level1Scope.enableCycleDetection();
      level2Scope.enableCycleDetection();

      // Устанавливаем модули на разных уровнях
      rootScope.installModules([RootLevelModule()]);
      level1Scope.installModules([Level1Module()]);
      level2Scope.installModules([Level2Module()]);

      // Попытка разрешить зависимость, которая создает цикл через все уровни
      expect(
        () => level2Scope.resolve<Level2Service>(),
        throwsA(isA<CircularDependencyException>()),
      );
    });

    test(
        'current implementation limitation - may not detect cross-scope cycles',
        () {
      // Этот тест демонстрирует ограничение текущей реализации
      final parentScope = CherryPick.openRootScope();
      parentScope.enableCycleDetection();

      final childScope = parentScope.openSubScope('child');
      // НЕ включаем cycle detection для дочернего скоупа

      parentScope.installModules([ParentScopeModule()]);
      childScope.installModules([ChildScopeModule()]);

      // В текущей реализации это может не обнаружить циклическую зависимость
      // если детекторы работают независимо в каждом скоупе
      try {
        // ignore: unused_local_variable
        final service = parentScope.resolve<CrossScopeServiceA>();
        // Если мы дошли сюда, значит циклическая зависимость не была обнаружена
        print('Циклическая зависимость между скоупами не обнаружена');
      } catch (e) {
        if (e is CircularDependencyException) {
          print('Циклическая зависимость обнаружена: ${e.message}');
        } else {
          print('Другая ошибка: $e');
        }
      }
    });
  });
}

// Тестовые сервисы для демонстрации циклических зависимостей между скоупами

class CrossScopeServiceA {
  final CrossScopeServiceB serviceB;
  CrossScopeServiceA(this.serviceB);
}

class CrossScopeServiceB {
  final CrossScopeServiceA serviceA;
  CrossScopeServiceB(this.serviceA);
}

class ParentScopeModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<CrossScopeServiceA>().toProvide(() {
      // Пытаемся получить сервис B из дочернего скоупа
      final childScope = currentScope.openSubScope('child');
      return CrossScopeServiceA(childScope.resolve<CrossScopeServiceB>());
    });
  }
}

class ChildScopeModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<CrossScopeServiceB>().toProvide(() {
      // Пытаемся получить сервис A из родительского скоупа
      final parentScope = currentScope.parentScope!;
      return CrossScopeServiceB(parentScope.resolve<CrossScopeServiceA>());
    });
  }
}

// Сервисы для сложной иерархии скоупов

class RootLevelService {
  final Level1Service level1Service;
  RootLevelService(this.level1Service);
}

class Level1Service {
  final Level2Service level2Service;
  Level1Service(this.level2Service);
}

class Level2Service {
  final RootLevelService rootService;
  Level2Service(this.rootService);
}

class RootLevelModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<RootLevelService>().toProvide(() {
      final level1Scope = currentScope.openSubScope('level1');
      return RootLevelService(level1Scope.resolve<Level1Service>());
    });
  }
}

class Level1Module extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Level1Service>().toProvide(() {
      final level2Scope = currentScope.openSubScope('level2');
      return Level1Service(level2Scope.resolve<Level2Service>());
    });
  }
}

class Level2Module extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Level2Service>().toProvide(() {
      // Идем к корневому скоупу через цепочку родителей
      var rootScope = currentScope.parentScope?.parentScope;
      return Level2Service(rootScope!.resolve<RootLevelService>());
    });
  }
}
