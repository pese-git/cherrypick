# Circular Dependency Detection

CherryPick provides robust circular dependency detection to prevent infinite loops and stack overflow errors in your dependency injection setup.

## What are Circular Dependencies?

Circular dependencies occur when two or more services depend on each other directly or indirectly, creating a cycle in the dependency graph.

### Example of circular dependencies within a scope

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

### Example of circular dependencies between scopes

```dart
// In parent scope
class ParentService {
  final ChildService childService;
  ParentService(this.childService); // Gets from child scope
}

// In child scope
class ChildService {
  final ParentService parentService;
  ChildService(this.parentService); // Gets from parent scope
}
```

## Detection Types

### 🔍 Local Detection

Detects circular dependencies within a single scope. Fast and efficient.

### 🌐 Global Detection

Detects circular dependencies across the entire scope hierarchy. Slower but provides complete protection.

## Usage

### Local Detection

```dart
final scope = Scope(null);
scope.enableCycleDetection(); // Enable local detection

scope.installModules([
  Module((bind) {
    bind<UserService>().to((scope) => UserService(scope.resolve<OrderService>()));
    bind<OrderService>().to((scope) => OrderService(scope.resolve<UserService>()));
  }),
]);

try {
  final userService = scope.resolve<UserService>(); // Will throw CircularDependencyException
} catch (e) {
  print(e); // CircularDependencyException: Circular dependency detected
}
```

### Global Detection

```dart
// Enable global detection for all scopes
CherryPick.enableGlobalCrossScopeCycleDetection();

final rootScope = CherryPick.openGlobalSafeRootScope();
final childScope = rootScope.openSubScope();

// Configure dependencies that create cross-scope cycles
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
  final parentService = rootScope.resolve<ParentService>(); // Will throw CircularDependencyException
} catch (e) {
  print(e); // CircularDependencyException with detailed chain information
}
```

## CherryPick Helper API

### Global Settings

```dart
// Enable/disable local detection globally
CherryPick.enableGlobalCycleDetection();
CherryPick.disableGlobalCycleDetection();

// Enable/disable global cross-scope detection
CherryPick.enableGlobalCrossScopeCycleDetection();
CherryPick.disableGlobalCrossScopeCycleDetection();

// Check current settings
bool localEnabled = CherryPick.isGlobalCycleDetectionEnabled;
bool globalEnabled = CherryPick.isGlobalCrossScopeCycleDetectionEnabled;
```

### Per-Scope Settings

```dart
// Enable/disable for specific scope
CherryPick.enableCycleDetectionForScope(scope);
CherryPick.disableCycleDetectionForScope(scope);

// Enable/disable global detection for specific scope
CherryPick.enableGlobalCycleDetectionForScope(scope);
CherryPick.disableGlobalCycleDetectionForScope(scope);
```

### Safe Scope Creation

```dart
// Create scopes with detection automatically enabled
final safeRootScope = CherryPick.openSafeRootScope(); // Local detection enabled
final globalSafeRootScope = CherryPick.openGlobalSafeRootScope(); // Both local and global enabled
final safeSubScope = CherryPick.openSafeSubScope(parentScope); // Inherits parent settings
```

## Performance Considerations

| Detection Type | Overhead | Recommended Usage |
|----------------|----------|-------------------|
| **Local** | Minimal (~5%) | Development, Testing |
| **Global** | Moderate (~15%) | Complex hierarchies, Critical features |
| **Disabled** | None | Production (after testing) |

### Recommendations

- **Development**: Enable both local and global detection for maximum safety
- **Testing**: Keep detection enabled to catch issues early
- **Production**: Consider disabling for performance, but only after thorough testing

```dart
import 'package:flutter/foundation.dart';

void configureCycleDetection() {
  if (kDebugMode) {
    // Enable full protection in debug mode
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  } else {
    // Disable in release mode for performance
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();
  }
}
```

## Architectural Patterns

### Repository Pattern

```dart
// ✅ Correct: Repository doesn't depend on service
class UserRepository {
  final ApiClient apiClient;
  UserRepository(this.apiClient);
}

class UserService {
  final UserRepository repository;
  UserService(this.repository);
}

// ❌ Incorrect: Circular dependency
class UserRepository {
  final UserService userService; // Don't do this!
  UserRepository(this.userService);
}
```

### Mediator Pattern

```dart
// ✅ Correct: Use mediator to break cycles
abstract class EventBus {
  void publish<T>(T event);
  Stream<T> listen<T>();
}

class UserService {
  final EventBus eventBus;
  UserService(this.eventBus);
  
  void createUser(User user) {
    // ... create user logic
    eventBus.publish(UserCreatedEvent(user));
  }
}

class OrderService {
  final EventBus eventBus;
  OrderService(this.eventBus) {
    eventBus.listen<UserCreatedEvent>().listen(_onUserCreated);
  }
  
  void _onUserCreated(UserCreatedEvent event) {
    // React to user creation without direct dependency
  }
}
```

## Scope Hierarchy Best Practices

### Proper Dependency Flow

```dart
// ✅ Correct: Dependencies flow downward in hierarchy
// Root Scope: Core services
final rootScope = CherryPick.openGlobalSafeRootScope();
rootScope.installModules([
  Module((bind) {
    bind<DatabaseService>().singleton((scope) => DatabaseService());
    bind<ApiClient>().singleton((scope) => ApiClient());
  }),
]);

// Feature Scope: Feature-specific services
final featureScope = rootScope.openSubScope();
featureScope.installModules([
  Module((bind) {
    bind<UserRepository>().to((scope) => UserRepository(scope.resolve<ApiClient>()));
    bind<UserService>().to((scope) => UserService(scope.resolve<UserRepository>()));
  }),
]);

// UI Scope: UI-specific services
final uiScope = featureScope.openSubScope();
uiScope.installModules([
  Module((bind) {
    bind<UserController>().to((scope) => UserController(scope.resolve<UserService>()));
  }),
]);
```

### Avoid Cross-Scope Dependencies

```dart
// ❌ Incorrect: Child scope depending on parent's specific services
childScope.installModules([
  Module((bind) {
    bind<ChildService>().to((scope) => 
      ChildService(rootScope.resolve<ParentService>()) // Risky!
    );
  }),
]);

// ✅ Correct: Use interfaces and proper dependency injection
abstract class IParentService {
  void doSomething();
}

class ParentService implements IParentService {
  void doSomething() { /* implementation */ }
}

// In root scope
rootScope.installModules([
  Module((bind) {
    bind<IParentService>().to((scope) => ParentService());
  }),
]);

// In child scope - resolve through normal hierarchy
childScope.installModules([
  Module((bind) {
    bind<ChildService>().to((scope) => 
      ChildService(scope.resolve<IParentService>()) // Safe!
    );
  }),
]);
```

## Debug Mode

### Resolution Chain Tracking

```dart
// Enable debug mode to track resolution chains
final scope = CherryPick.openGlobalSafeRootScope();

// Access current resolution chain for debugging
print('Current resolution chain: ${scope.currentResolutionChain}');

// Access global resolution chain
print('Global resolution chain: ${GlobalCycleDetector.instance.currentGlobalResolutionChain}');
```

### Exception Details

```dart
try {
  final service = scope.resolve<CircularService>();
} on CircularDependencyException catch (e) {
  print('Error: ${e.message}');
  print('Dependency chain: ${e.dependencyChain.join(' -> ')}');
  
  // For global detection, additional context is available
  if (e.message.contains('cross-scope')) {
    print('This is a cross-scope circular dependency');
  }
}
```

## Testing Integration

### Unit Tests

```dart
import 'package:test/test.dart';
import 'package:cherrypick/cherrypick.dart';

void main() {
  group('Circular Dependency Detection', () {
    setUp(() {
      // Enable detection for tests
      CherryPick.enableGlobalCycleDetection();
      CherryPick.enableGlobalCrossScopeCycleDetection();
    });
    
    tearDown(() {
      // Clean up after tests
      CherryPick.disableGlobalCycleDetection();
      CherryPick.disableGlobalCrossScopeCycleDetection();
    });
    
    test('should detect circular dependency', () {
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

### Integration Tests

```dart
testWidgets('should handle circular dependencies in widget tree', (tester) async {
  // Enable detection
  CherryPick.enableGlobalCycleDetection();
  
  await tester.pumpWidget(
    CherryPickProvider(
      create: () {
        final scope = CherryPick.openGlobalSafeRootScope();
        // Configure modules that might have cycles
        return scope;
      },
      child: MyApp(),
    ),
  );
  
  // Test that circular dependencies are properly handled
  expect(find.text('Error: Circular dependency detected'), findsNothing);
});
```

## Migration Guide

### From Version 2.1.x to 2.2.x

1. **Update dependencies**:
   ```yaml
   dependencies:
     cherrypick: ^2.2.0
   ```

2. **Enable detection in existing code**:
   ```dart
   // Before
   final scope = Scope(null);
   
   // After - with local detection
   final scope = CherryPick.openSafeRootScope();
   
   // Or with global detection
   final scope = CherryPick.openGlobalSafeRootScope();
   ```

3. **Update error handling**:
   ```dart
   try {
     final service = scope.resolve<MyService>();
   } on CircularDependencyException catch (e) {
     // Handle circular dependency errors
     logger.error('Circular dependency detected: ${e.dependencyChain}');
   }
   ```

4. **Configure for production**:
   ```dart
   void main() {
     // Configure detection based on build mode
     if (kDebugMode) {
       CherryPick.enableGlobalCycleDetection();
       CherryPick.enableGlobalCrossScopeCycleDetection();
     }
     
     runApp(MyApp());
   }
   ```

## API Reference

### Scope Methods

```dart
class Scope {
  // Local cycle detection
  void enableCycleDetection();
  void disableCycleDetection();
  bool get isCycleDetectionEnabled;
  List<String> get currentResolutionChain;
  
  // Global cycle detection
  void enableGlobalCycleDetection();
  void disableGlobalCycleDetection();
  bool get isGlobalCycleDetectionEnabled;
}
```

### CherryPick Helper Methods

```dart
class CherryPick {
  // Global settings
  static void enableGlobalCycleDetection();
  static void disableGlobalCycleDetection();
  static bool get isGlobalCycleDetectionEnabled;
  
  static void enableGlobalCrossScopeCycleDetection();
  static void disableGlobalCrossScopeCycleDetection();
  static bool get isGlobalCrossScopeCycleDetectionEnabled;
  
  // Per-scope settings
  static void enableCycleDetectionForScope(Scope scope);
  static void disableCycleDetectionForScope(Scope scope);
  static void enableGlobalCycleDetectionForScope(Scope scope);
  static void disableGlobalCycleDetectionForScope(Scope scope);
  
  // Safe scope creation
  static Scope openSafeRootScope();
  static Scope openGlobalSafeRootScope();
  static Scope openSafeSubScope(Scope parent);
}
```

### Exception Classes

```dart
class CircularDependencyException implements Exception {
  final String message;
  final List<String> dependencyChain;
  
  const CircularDependencyException(this.message, this.dependencyChain);
  
  @override
  String toString() {
    final chain = dependencyChain.join(' -> ');
    return 'CircularDependencyException: $message\nDependency chain: $chain';
  }
}
```

## Best Practices

### 1. Enable Detection During Development

```dart
void main() {
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }
  
  runApp(MyApp());
}
```

### 2. Use Safe Scope Creation

```dart
// Instead of
final scope = Scope(null);

// Use
final scope = CherryPick.openGlobalSafeRootScope();
```

### 3. Design Proper Architecture

- Follow single responsibility principle
- Use interfaces to decouple dependencies
- Implement mediator pattern for complex interactions
- Keep dependency flow unidirectional in scope hierarchy

### 4. Handle Errors Gracefully

```dart
T resolveSafely<T>() {
  try {
    return scope.resolve<T>();
  } on CircularDependencyException catch (e) {
    logger.error('Circular dependency detected', e);
    rethrow;
  }
}
```

### 5. Test Thoroughly

- Write unit tests for dependency configurations
- Use integration tests to verify complex scenarios
- Enable detection in test environments
- Test both positive and negative scenarios

## Troubleshooting

### Common Issues

1. **False Positives**: If you're getting false circular dependency errors, check if you have proper async handling in your providers.

2. **Performance Issues**: If global detection is too slow, consider using only local detection or disabling it in production.

3. **Complex Hierarchies**: For very complex scope hierarchies, consider simplifying your architecture or using more interfaces.

### Debug Tips

1. **Check Resolution Chain**: Use `scope.currentResolutionChain` to see the current dependency resolution path.

2. **Enable Logging**: Add logging to your providers to trace dependency resolution.

3. **Simplify Dependencies**: Break complex dependencies into smaller, more manageable pieces.

4. **Use Interfaces**: Abstract dependencies behind interfaces to reduce coupling.

## Conclusion

Circular dependency detection in CherryPick provides robust protection against infinite loops and stack overflow errors. By following the best practices and using the appropriate detection level for your use case, you can build reliable and maintainable dependency injection configurations.

For more information, see the [main documentation](../README.md) and [examples](../example/).
