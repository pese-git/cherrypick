---
title: Биндинги
description: Синхронные и асинхронные фабрики, экземпляры, именованные и параметризованные биндинги, синглтоны.
---

Биндинг описывает, как создаётся отдельная зависимость. CherryPick 2.x
поддерживает синхронные и асинхронные фабрики, готовые экземпляры, имена,
runtime-параметры и жизненный цикл singleton.

## Методы регистрации

```dart
// Синхронная фабрика
bind<MyService>().toProvide(() => MyServiceImpl());

// Асинхронная фабрика (ожидает Future)
bind<MyRepository>().toProvideAsync(() async => await initRepo());

// Фабрика с runtime-параметрами
bind<UserService>().toProvideWithParams((id) => UserService(id));

// Singleton
bind<MyApi>().toProvide(() => MyApi()).singleton();

// Уже созданный объект
final config = AppConfig.dev();
bind<AppConfig>().toInstance(config);

// Уже запущенный Future / async-значение
final setupFuture = loadEnvironment();
bind<Environment>().toInstanceAsync(setupFuture);
```

| Метод | Описание |
| ----- | -------- |
| `toProvide` | Обычная синхронная фабрика |
| `toProvideAsync` | Асинхронная фабрика (ожидание `Future`) |
| `toProvideWithParams` / `toProvideAsyncWithParams` | Фабрики с runtime-параметрами |
| `toInstance` | Регистрация готового объекта |
| `toInstanceAsync` | Регистрация уже запущенного `Future` |

## Именованные биндинги

Зарегистрируйте несколько реализаций интерфейса под разными именами и получайте
их по имени:

```dart
bind<ApiClient>().toProvide(() => ApiClientProd()).withName('prod');
bind<ApiClient>().toProvide(() => ApiClientMock()).withName('mock');

final api = scope.resolve<ApiClient>(named: 'mock');
```

## Жизненный цикл singleton

- `.singleton()` — единственный экземпляр на время жизни скоупа.
- По умолчанию каждый `resolve` создаёт новый объект.

## Параметризованные биндинги

Создавайте зависимости из runtime-параметров — например, сервис для пользователя
с заданным ID:

```dart
bind<UserService>().toProvideWithParams((userId) => UserService(userId));

final userService = scope.resolve<UserService>(params: '123');
```

## Асинхронные зависимости

Используйте `toProvideAsync` (или `toInstanceAsync`) для async-зависимостей и
получайте их через `resolveAsync`:

```dart
bind<RemoteConfig>().toProvideAsync(() async => await RemoteConfig.load());

final config = await scope.resolveAsync<RemoteConfig>();
```

## Безопасное получение

Если не уверены, что зависимость существует, используйте `tryResolve` /
`tryResolveAsync` — они возвращают `null` вместо исключения:

```dart
final service = scope.tryResolve<OptionalService>(); // null, если нет
final remote = await scope.tryResolveAsync<RemoteConfig>();
```
