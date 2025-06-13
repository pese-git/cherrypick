# Обнаружение циклических зависимостей

CherryPick предоставляет надежное обнаружение циклических зависимостей для предотвращения бесконечных циклов и ошибок переполнения стека в вашей настройке внедрения зависимостей.

## Что такое циклические зависимости?

Циклические зависимости возникают, когда два или более сервиса зависят друг от друга прямо или косвенно, создавая цикл в графе зависимостей.

### Пример циклических зависимостей в рамках скоупа

```dart
class UserService {
  final OrderService orderService;
  UserService(this.orderService);
}

class OrderService {
  final UserService userService;
  OrderService(this.userService);
}
```

### Пример циклических зависимостей между скоупами

```dart
// В родительском скоупе
class ParentService {
  final ChildService childService;
  ParentService(this.childService); // Получает из дочернего скоупа
}

// В дочернем скоупе
class ChildService {
  final ParentService parentService;
  ChildService(this.parentService); // Получает из родительского скоупа
}
```

## Типы обнаружения

### 🔍 Локальное обнаружение

Обнаруживает циклические зависимости в рамках одного скоупа. Быстрое и эффективное.

### 🌐 Глобальное обнаружение

Обнаруживает циклические зависимости во всей иерархии скоупов. Более медленное, но обеспечивает полную защиту.

## Использование

### Локальное обнаружение

```dart
final scope = Scope(null);
scope.enableCycleDetection(); // Включить локальное обнаружение

scope.installModules([
  Module((bind) {
    bind<UserService>().to((scope) => UserService(scope.resolve<OrderService>()));
    bind<OrderService>().to((scope) => OrderService(scope.resolve<UserService>()));
  }),
]);

try {
  final userService = scope.resolve<UserService>(); // Выбросит CircularDependencyException
} catch (e) {
  print(e); // CircularDependencyException: Circular dependency detected
}
```

### Глобальное обнаружение

```dart
// Включить глобальное обнаружение для всех скоупов
CherryPick.enableGlobalCrossScopeCycleDetection();

final rootScope = CherryPick.openGlobalSafeRootScope();
final childScope = rootScope.openSubScope();

// Настроить зависимости, которые создают межскоуповые циклы
rootScope.installModules([
  Module((bind) {
    bind<ParentService>().to((scope) => ParentService(childScope.resolve<ChildService>()));
  }),
]);

childScope.installModules([
  Module((bind) {
    bind<ChildService>().to((scope) => ChildService(rootScope.resolve<ParentService>()));
  }),
]);

try {
  final parentService = rootScope.resolve<ParentService>(); // Выбросит CircularDependencyException
} catch (e) {
  print(e); // CircularDependencyException с детальной информацией о цепочке
}
```

## API CherryPick Helper

### Глобальные настройки

```dart
// Включить/отключить локальное обнаружение глобально
CherryPick.enableGlobalCycleDetection();
CherryPick.disableGlobalCycleDetection();

// Включить/отключить глобальное межскоуповое обнаружение
CherryPick.enableGlobalCrossScopeCycleDetection();
CherryPick.disableGlobalCrossScopeCycleDetection();

// Проверить текущие настройки
bool localEnabled = CherryPick.isGlobalCycleDetectionEnabled;
bool globalEnabled = CherryPick.isGlobalCrossScopeCycleDetectionEnabled;
```

### Настройки для конкретного скоупа

```dart
// Включить/отключить для конкретного скоупа
CherryPick.enableCycleDetectionForScope(scope);
CherryPick.disableCycleDetectionForScope(scope);

// Включить/отключить глобальное обнаружение для конкретного скоупа
CherryPick.enableGlobalCycleDetectionForScope(scope);
CherryPick.disableGlobalCycleDetectionForScope(scope);
```

### Безопасное создание скоупов

```dart
// Создать скоупы с автоматически включенным обнаружением
final safeRootScope = CherryPick.openSafeRootScope(); // Локальное обнаружение включено
final globalSafeRootScope = CherryPick.openGlobalSafeRootScope(); // Включены локальное и глобальное
final safeSubScope = CherryPick.openSafeSubScope(parentScope); // Наследует настройки родителя
```

## Соображения производительности

| Тип обнаружения | Накладные расходы | Рекомендуемое использование |
|-----------------|-------------------|----------------------------|
| **Локальное** | Минимальные (~5%) | Разработка, тестирование |
| **Глобальное** | Умеренные (~15%) | Сложные иерархии, критические функции |
| **Отключено** | Нет | Продакшн (после тестирования) |

### Рекомендации

- **Разработка**: Включите локальное и глобальное обнаружение для максимальной безопасности
- **Тестирование**: Оставьте обнаружение включенным для раннего выявления проблем
- **Продакшн**: Рассмотрите отключение для производительности, но только после тщательного тестирования

```dart
import 'package:flutter/foundation.dart';

void configureCycleDetection() {
  if (kDebugMode) {
    // Включить полную защиту в режиме отладки
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  } else {
    // Отключить в релизном режиме для производительности
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();
  }
}
```

## Архитектурные паттерны

### Паттерн Repository

```dart
// ✅ Правильно: Repository не зависит от сервиса
class UserRepository {
  final ApiClient apiClient;
  UserRepository(this.apiClient);
}

class UserService {
  final UserRepository repository;
  UserService(this.repository);
}

// ❌ Неправильно: Циклическая зависимость
class UserRepository {
  final UserService userService; // Не делайте так!
  UserRepository(this.userService);
}
```

### Паттерн Mediator

```dart
// ✅ Правильно: Используйте медиатор для разрыва циклов
abstract class EventBus {
  void publish<T>(T event);
  Stream<T> listen<T>();
}

class UserService {
  final EventBus eventBus;
  UserService(this.eventBus);
  
  void createUser(User user) {
    // ... логика создания пользователя
    eventBus.publish(UserCreatedEvent(user));
  }
}

class OrderService {
  final EventBus eventBus;
  OrderService(this.eventBus) {
    eventBus.listen<UserCreatedEvent>().listen(_onUserCreated);
  }
  
  void _onUserCreated(UserCreatedEvent event) {
    // Реагировать на создание пользователя без прямой зависимости
  }
}
```

## Лучшие практики иерархии скоупов

### Правильный поток зависимостей

```dart
// ✅ Правильно: Зависимости текут вниз по иерархии
// Корневой скоуп: Основные сервисы
final rootScope = CherryPick.openGlobalSafeRootScope();
rootScope.installModules([
  Module((bind) {
    bind<DatabaseService>().singleton((scope) => DatabaseService());
    bind<ApiClient>().singleton((scope) => ApiClient());
  }),
]);

// Скоуп функции: Сервисы, специфичные для функции
final featureScope = rootScope.openSubScope();
featureScope.installModules([
  Module((bind) {
    bind<UserRepository>().to((scope) => UserRepository(scope.resolve<ApiClient>()));
    bind<UserService>().to((scope) => UserService(scope.resolve<UserRepository>()));
  }),
]);

// UI скоуп: Сервисы, специфичные для UI
final uiScope = featureScope.openSubScope();
uiScope.installModules([
  Module((bind) {
    bind<UserController>().to((scope) => UserController(scope.resolve<UserService>()));
  }),
]);
```

### Избегайте межскоуповых зависимостей

```dart
// ❌ Неправильно: Дочерний скоуп зависит от конкретных сервисов родителя
childScope.installModules([
  Module((bind) {
    bind<ChildService>().to((scope) => 
      ChildService(rootScope.resolve<ParentService>()) // Рискованно!
    );
  }),
]);

// ✅ Правильно: Используйте интерфейсы и правильное внедрение зависимостей
abstract class IParentService {
  void doSomething();
}

class ParentService implements IParentService {
  void doSomething() { /* реализация */ }
}

// В корневом скоупе
rootScope.installModules([
  Module((bind) {
    bind<IParentService>().to((scope) => ParentService());
  }),
]);

// В дочернем скоупе - разрешение через обычную иерархию
childScope.installModules([
  Module((bind) {
    bind<ChildService>().to((scope) => 
      ChildService(scope.resolve<IParentService>()) // Безопасно!
    );
  }),
]);
```

## Режим отладки

### Отслеживание цепочки разрешения

```dart
// Включить режим отладки для отслеживания цепочек разрешения
final scope = CherryPick.openGlobalSafeRootScope();

// Доступ к текущей цепочке разрешения для отладки
print('Текущая цепочка разрешения: ${scope.currentResolutionChain}');

// Доступ к глобальной цепочке разрешения
print('Глобальная цепочка разрешения: ${GlobalCycleDetector.instance.currentGlobalResolutionChain}');
```

### Детали исключений

```dart
try {
  final service = scope.resolve<CircularService>();
} on CircularDependencyException catch (e) {
  print('Ошибка: ${e.message}');
  print('Цепочка зависимостей: ${e.dependencyChain.join(' -> ')}');
  
  // Для глобального обнаружения доступен дополнительный контекст
  if (e.message.contains('cross-scope')) {
    print('Это межскоуповая циклическая зависимость');
  }
}
```

## Интеграция с тестированием

### Модульные тесты

```dart
import 'package:test/test.dart';
import 'package:cherrypick/cherrypick.dart';

void main() {
  group('Обнаружение циклических зависимостей', () {
    setUp(() {
      // Включить обнаружение для тестов
      CherryPick.enableGlobalCycleDetection();
      CherryPick.enableGlobalCrossScopeCycleDetection();
    });
    
    tearDown(() {
      // Очистка после тестов
      CherryPick.disableGlobalCycleDetection();
      CherryPick.disableGlobalCrossScopeCycleDetection();
    });
    
    test('должен обнаружить циклическую зависимость', () {
      final scope = CherryPick.openGlobalSafeRootScope();
      
      scope.installModules([
        Module((bind) {
          bind<ServiceA>().to((scope) => ServiceA(scope.resolve<ServiceB>()));
          bind<ServiceB>().to((scope) => ServiceB(scope.resolve<ServiceA>()));
        }),
      ]);
      
      expect(
        () => scope.resolve<ServiceA>(),
        throwsA(isA<CircularDependencyException>()),
      );
    });
  });
}
```

### Интеграционные тесты

```dart
testWidgets('должен обрабатывать циклические зависимости в дереве виджетов', (tester) async {
  // Включить обнаружение
  CherryPick.enableGlobalCycleDetection();
  
  await tester.pumpWidget(
    CherryPickProvider(
      create: () {
        final scope = CherryPick.openGlobalSafeRootScope();
        // Настроить модули, которые могут иметь циклы
        return scope;
      },
      child: MyApp(),
    ),
  );
  
  // Проверить, что циклические зависимости правильно обрабатываются
  expect(find.text('Ошибка: Обнаружена циклическая зависимость'), findsNothing);
});
```

## Руководство по миграции

### С версии 2.1.x на 2.2.x

1. **Обновите зависимости**:
   ```yaml
   dependencies:
     cherrypick: ^2.2.0
   ```

2. **Включите обнаружение в существующем коде**:
   ```dart
   // Раньше
   final scope = Scope(null);
   
   // Теперь - с локальным обнаружением
   final scope = CherryPick.openSafeRootScope();
   
   // Или с глобальным обнаружением
   final scope = CherryPick.openGlobalSafeRootScope();
   ```

3. **Обновите обработку ошибок**:
   ```dart
   try {
     final service = scope.resolve<MyService>();
   } on CircularDependencyException catch (e) {
     // Обработать ошибки циклических зависимостей
     logger.error('Обнаружена циклическая зависимость: ${e.dependencyChain}');
   }
   ```

4. **Настройте для продакшна**:
   ```dart
   void main() {
     // Настроить обнаружение в зависимости от режима сборки
     if (kDebugMode) {
       CherryPick.enableGlobalCycleDetection();
       CherryPick.enableGlobalCrossScopeCycleDetection();
     }
     
     runApp(MyApp());
   }
   ```

## Справочник API

### Методы Scope

```dart
class Scope {
  // Локальное обнаружение циклов
  void enableCycleDetection();
  void disableCycleDetection();
  bool get isCycleDetectionEnabled;
  List<String> get currentResolutionChain;
  
  // Глобальное обнаружение циклов
  void enableGlobalCycleDetection();
  void disableGlobalCycleDetection();
  bool get isGlobalCycleDetectionEnabled;
}
```

### Методы CherryPick Helper

```dart
class CherryPick {
  // Глобальные настройки
  static void enableGlobalCycleDetection();
  static void disableGlobalCycleDetection();
  static bool get isGlobalCycleDetectionEnabled;
  
  static void enableGlobalCrossScopeCycleDetection();
  static void disableGlobalCrossScopeCycleDetection();
  static bool get isGlobalCrossScopeCycleDetectionEnabled;
  
  // Настройки для конкретного скоупа
  static void enableCycleDetectionForScope(Scope scope);
  static void disableCycleDetectionForScope(Scope scope);
  static void enableGlobalCycleDetectionForScope(Scope scope);
  static void disableGlobalCycleDetectionForScope(Scope scope);
  
  // Безопасное создание скоупов
  static Scope openSafeRootScope();
  static Scope openGlobalSafeRootScope();
  static Scope openSafeSubScope(Scope parent);
}
```

### Классы исключений

```dart
class CircularDependencyException implements Exception {
  final String message;
  final List<String> dependencyChain;
  
  const CircularDependencyException(this.message, this.dependencyChain);
  
  @override
  String toString() {
    final chain = dependencyChain.join(' -> ');
    return 'CircularDependencyException: $message\nЦепочка зависимостей: $chain';
  }
}
```

## Лучшие практики

### 1. Включайте обнаружение во время разработки

```dart
void main() {
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }
  
  runApp(MyApp());
}
```

### 2. Используйте безопасное создание скоупов

```dart
// Вместо
final scope = Scope(null);

// Используйте
final scope = CherryPick.openGlobalSafeRootScope();
```

### 3. Проектируйте правильную архитектуру

- Следуйте принципу единственной ответственности
- Используйте интерфейсы для разделения зависимостей
- Реализуйте паттерн медиатор для сложных взаимодействий
- Поддерживайте однонаправленный поток зависимостей в иерархии скоупов

### 4. Обрабатывайте ошибки корректно

```dart
T resolveSafely<T>() {
  try {
    return scope.resolve<T>();
  } on CircularDependencyException catch (e) {
    logger.error('Обнаружена циклическая зависимость', e);
    rethrow;
  }
}
```

### 5. Тестируйте тщательно

- Пишите модульные тесты для конфигураций зависимостей
- Используйте интеграционные тесты для проверки сложных сценариев
- Включайте обнаружение в тестовых средах
- Тестируйте как положительные, так и отрицательные сценарии

## Устранение неполадок

### Распространенные проблемы

1. **Ложные срабатывания**: Если вы получаете ложные ошибки циклических зависимостей, проверьте правильность обработки async в ваших провайдерах.

2. **Проблемы производительности**: Если глобальное обнаружение слишком медленное, рассмотрите использование только локального обнаружения или отключение в продакшне.

3. **Сложные иерархии**: Для очень сложных иерархий скоупов рассмотрите упрощение архитектуры или использование большего количества интерфейсов.

### Советы по отладке

1. **Проверьте цепочку разрешения**: Используйте `scope.currentResolutionChain` для просмотра текущего пути разрешения зависимостей.

2. **Включите логирование**: Добавьте логирование в ваши провайдеры для трассировки разрешения зависимостей.

3. **Упростите зависимости**: Разбейте сложные зависимости на более мелкие, управляемые части.

4. **Используйте интерфейсы**: Абстрагируйте зависимости за интерфейсами для уменьшения связанности.

## Заключение

Обнаружение циклических зависимостей в CherryPick обеспечивает надежную защиту от бесконечных циклов и ошибок переполнения стека. Следуя лучшим практикам и используя подходящий уровень обнаружения для вашего случая использования, вы можете создавать надежные и поддерживаемые конфигурации внедрения зависимостей.

Для получения дополнительной информации см. [основную документацию](../README.md) и [примеры](../example/).
