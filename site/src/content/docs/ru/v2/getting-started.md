---
title: Быстрый старт
slug: ru/v2/getting-started
---

Минимальный пример регистрации и получения зависимости:

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
print(greeting); // напечатает: Hello, CherryPick!

await CherryPick.closeRootScope();
```
