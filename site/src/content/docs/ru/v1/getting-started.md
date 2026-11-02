---
title: Быстрый старт
description: Основные компоненты DI в CherryPick 1.x — Binding, Module и Scope.
---

Это руководство знакомит с тремя основными компонентами CherryPick 1.x.

## Основные компоненты DI

### Binding

`Binding` настраивает создание зависимости. У него два основных метода —
`toInstance()` и `toProvide()` — и вспомогательные `withName()` и `singleton()`.

- `toInstance()` — принимает готовый экземпляр.
- `toProvide()` — принимает функцию `provider` (конструктор экземпляра).
- `withName()` — принимает строку для именования экземпляра, чтобы позже
  получить его из контейнера по этому имени.
- `singleton()` — помечает биндинг как singleton: контейнер создаёт единственный
  общий экземпляр.

```dart
// Готовый экземпляр через toInstance()
Binding<String>().toInstance("hello world");

// Лениво создаваемый экземпляр через фабрику
Binding<String>().toProvide(() => "hello world");

// Именованный экземпляр
Binding<String>().withName("my_string").toInstance("hello world");
// или
Binding<String>().withName("my_string").toProvide(() => "hello world");

// Singleton
Binding<String>().toInstance("hello world");
// или
Binding<String>().toProvide(() => "hello world").singleton();
```

### Module

`Module` — это контейнер биндингов. Наследуйте его и реализуйте
`void builder(Scope currentScope)`, регистрируя зависимости через `bind<T>()`.

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
  }
}
```

### Scope

`Scope` — это контейнер, хранящий всё дерево зависимостей (скоупы, модули,
экземпляры). Получайте зависимость через `resolve<T>()`, указывая тип и любые
дополнительные параметры. Используйте `tryResolve<T>()`, чтобы получить `null`
вместо исключения, если зависимость не найдена.

```dart
// Открываем корневой scope
final rootScope = CherryPick.openRootScope();

// Устанавливаем модуль
rootScope.installModules([AppModule()]);

// Получаем экземпляр
final client = rootScope.resolve<ApiClient>();
// или без исключения при отсутствии:
final maybeClient = rootScope.tryResolve<ApiClient>();

// Закрываем корневой scope
CherryPick.closeRootScope();
```

Продолжите полным [примером приложения](/ru/v1/example-application/).
