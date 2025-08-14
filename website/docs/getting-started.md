---
sidebar_position: 3
---

# Getting Started

Here is a minimal example that registers and resolves a dependency:

```dart
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
    bind<String>().toProvide(() => "Hello, CherryPick!");
  }
}

final rootScope = CherryPick.openRootScope();
rootScope.installModules([AppModule()]);

final greeting = rootScope.resolve<String>();
print(greeting); // prints: Hello, CherryPick!

await CherryPick.closeRootScope();
```
