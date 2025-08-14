---
sidebar_position: 3
---

# Обнаружение циклических зависимостей

CherryPick может обнаруживать циклические зависимости в вашей DI-конфигурации, помогая избежать бесконечных циклов и сложных для отладки ошибок.

## Как использовать:

### 1. Включите обнаружение во время разработки

**Локально (в рамках одного скоупа):**
```dart
final scope = CherryPick.openSafeRootScope(); // Локальное обнаружение включено по умолчанию
// или для существующего скоупа:
scope.enableCycleDetection();
```

**Глобально (между скоупами):**
```dart
CherryPick.enableGlobalCrossScopeCycleDetection();
final rootScope = CherryPick.openGlobalSafeRootScope();
```

### 2. Пример ошибки

Если вы объявите взаимозависимые сервисы:
```dart
class A { A(B b); }
class B { B(A a); }

scope.installModules([
  Module((bind) {
    bind<A>().to((s) => A(s.resolve<B>()));
    bind<B>().to((s) => B(s.resolve<A>()));
  }),
]);

scope.resolve<A>(); // выбросит CircularDependencyException
```

### 3. Общая рекомендация

- **Включайте обнаружение** всегда в debug и тестовой среде для максимальной безопасности.
- **Отключайте обнаружение** в production после завершения тестирования, ради производительности.

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

### 4. Отладка и обработка ошибок

При обнаружении будет выброшено исключение `CircularDependencyException` с цепочкой зависимостей:
```dart
try {
  scope.resolve<MyService>();
} on CircularDependencyException catch (e) {
  print('Цепочка зависимостей: ${e.dependencyChain}');
}
```

**Подробнее:** смотрите [cycle_detection.ru.md](doc/cycle_detection.ru.md)
