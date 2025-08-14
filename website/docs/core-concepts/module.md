---
sidebar_position: 2
---

# Module

A **Module** is a logical collection point for bindings, designed for grouping and initializing related dependencies. Implement the `builder` method to define how dependencies should be bound within the scope.

## Example

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
    bind<String>().toProvide(() => "Hello world!");
  }
}
```
