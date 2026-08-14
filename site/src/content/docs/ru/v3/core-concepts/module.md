---
title: Модуль
slug: ru/v3/core-concepts/module
---

**Модуль** — это логическая точка сбора для привязок (bindings), предназначенная для группирования и инициализации связанных зависимостей. Реализуйте метод `builder`, чтобы определить, как зависимости будут связываться внутри скоупа.

## Пример

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
    bind<String>().toProvide(() => "Hello world!");
  }
}
```
