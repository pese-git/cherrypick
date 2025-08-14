---
sidebar_position: 3
---

# Circular Dependency Detection

CherryPick can detect circular dependencies in your DI configuration, helping you avoid infinite loops and hard-to-debug errors.

## How to use:

### 1. Enable Cycle Detection for Development

**Local detection (within one scope):**
```dart
final scope = CherryPick.openSafeRootScope(); // Local detection enabled by default
// or, for an existing scope:
scope.enableCycleDetection();
```

**Global detection (across all scopes):**
```dart
CherryPick.enableGlobalCrossScopeCycleDetection();
final rootScope = CherryPick.openGlobalSafeRootScope();
```

### 2. Error Example

If you declare mutually dependent services:
```dart
class A { A(B b); }
class B { B(A a); }

scope.installModules([
  Module((bind) {
    bind<A>().to((s) => A(s.resolve<B>()));
    bind<B>().to((s) => B(s.resolve<A>()));
  }),
]);

scope.resolve<A>(); // Throws CircularDependencyException
```

### 3. Typical Usage Pattern

- **Always enable detection** in debug and test environments for maximum safety.
- **Disable detection** in production for performance (after code is tested).

```dart
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }
  runApp(MyApp());
}
```

### 4. Handling and Debugging Errors

On detection, `CircularDependencyException` is thrown with a readable dependency chain:
```dart
try {
  scope.resolve<MyService>();
} on CircularDependencyException catch (e) {
  print('Dependency chain: ${e.dependencyChain}');
}
```

**More details:** See [cycle_detection.en.md](doc/cycle_detection.en.md)
