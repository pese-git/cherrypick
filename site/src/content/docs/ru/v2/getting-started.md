---
title: Быстрый старт
description: Основные компоненты DI в CherryPick 2.x — Binding, Module и Scope.
---

Это руководство знакомит с тремя основными компонентами CherryPick 2.x. Полный
API биндингов — в разделе [Биндинги](/ru/v2/bindings/), дерево скоупов — в
разделе [Скоупы](/ru/v2/scopes/).

## Основные компоненты DI

### Binding

`Binding` настраивает создание зависимости. Основные методы — `toInstance()` и
`toProvide()`, вспомогательные — `withName()` и `singleton()`.

- `toInstance()` — принимает готовый экземпляр.
- `toProvide()` — принимает функцию `provider` (конструктор экземпляра).
- `withName()` — именует экземпляр, чтобы получать его по имени.
- `singleton()` — помечает биндинг как singleton в рамках скоупа.

```dart
// Готовый экземпляр
Binding<String>().toInstance("hello world");

// Ленивая фабрика
Binding<String>().toProvide(() => "hello world");

// Именованный экземпляр
Binding<String>().withName("my_string").toProvide(() => "hello world");

// Singleton
Binding<String>().toProvide(() => "hello world").singleton();
```

### Module

`Module` — контейнер биндингов. Наследуйте его и реализуйте
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

`Scope` хранит всё дерево зависимостей. Получайте зависимость через `resolve<T>()`
или `tryResolve<T>()`, чтобы получить `null` вместо исключения при отсутствии.

```dart
// Открываем корневой scope
final rootScope = CherryPick.openRootScope();

// Устанавливаем модуль
rootScope.installModules([AppModule()]);

// Получаем экземпляр
final client = rootScope.resolve<ApiClient>();
// или без исключения:
final maybeClient = rootScope.tryResolve<ApiClient>();

// Закрываем корневой scope
CherryPick.closeRootScope();
```

## Дальше

- [Биндинги](/ru/v2/bindings/) — async, именованные и параметризованные биндинги.
- [Скоупы](/ru/v2/scopes/) — именованные скоупы и иерархия.
- [Аннотации](/ru/v2/using-annotations/) — DI с кодогенерацией.
- [Пример приложения](/ru/v2/example-application/) — полное приложение.
