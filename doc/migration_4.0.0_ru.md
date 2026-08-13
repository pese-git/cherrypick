# Руководство по миграции: cherrypick 3.x → 4.0.0

Версия 4.0.0 финализирует публичный API резолверов и провайдеров ядра
`cherrypick`. Перечисленные ниже изменения являются **breaking** для кода,
который напрямую использовал старые typedef'ы провайдеров или полагался на то,
что `toProvideAsync` — это свободный алиас `toProvide`. Обычное использование
`bind<T>().toProvide(...)` / `.toInstance(...)` не затронуто.

> Изменилось только ядро `cherrypick`. Пакеты `cherrypick_flutter`,
> `cherrypick_generator`, `cherrypick_annotations` и `talker_cherrypick_logger`
> сохраняют существующий публичный интерфейс.

## Сводка breaking-изменений

| Область | 3.x | 4.0.0 |
| --- | --- | --- |
| Typedef фабрики провайдера | `ProviderFactory<T> = FutureOr<T> Function()` | `ProviderFactory<T> = T Function()` (строго синхронный) |
| Удалённые typedef'ы | `Instance<T>`, `ProviderWithParams<T>` | удалены — используйте `FutureOr<T>` и новые typedef'ы фабрик |
| Async-провайдеры | `toProvideAsync` был deprecated-алиасом `toProvide` | строго асинхронные: требуют `Future<T> Function()` / `Future<T> Function(dynamic)` |
| Конкретные резолверы | `InstanceResolver`, `ProviderResolver` экспортировались | больше не экспортируются — публичны только `BindingResolver` и typedef'ы фабрик |
| `toInstanceAsync` | доступен | **устарел** — используйте `toInstance` (он принимает `FutureOr<T>`) |

## Новые публичные typedef'ы

```dart
typedef ProviderFactory<T>              = T Function();
typedef ProviderFactoryWithParams<T>    = T Function(dynamic);
typedef AsyncProviderFactory<T>         = Future<T> Function();
typedef AsyncProviderFactoryWithParams<T> = Future<T> Function(dynamic);
```

## Пошагово

### 1. Удалены typedef'ы `Instance<T>` и `ProviderWithParams<T>`

Если вы ссылались на них напрямую (редкий случай), замените их:

```dart
// Было — Instance<T> был алиасом FutureOr<T> (значение, а не функция)
Instance<MyService> value = MyService();
ProviderWithParams<User> factory = (params) => User(params);

// Стало — используйте FutureOr<T> / новые typedef'ы фабрик
FutureOr<MyService> value = MyService();
ProviderFactoryWithParams<User> factory = (params) => User(params);
```

### 2. `ProviderFactory<T>` теперь только синхронный

Раньше `ProviderFactory<T>` допускал возврат `Future`. Теперь это
`T Function()`. Для асинхронных фабрик используйте `AsyncProviderFactory<T>`
(`Future<T> Function()`).

### 3. `toProvideAsync` / `toProvideAsyncWithParams` строго асинхронны

Это больше не алиасы `toProvide`; теперь они требуют фабрику, возвращающую
`Future`:

```dart
// По-прежнему валидно — замыкание возвращает Future
bind<Db>().toProvideAsync(() async => await openDb());

// Случайно принималось в 3.x, теперь ошибка типа — фабрика синхронна:
bind<Db>().toProvideAsync(() => openDbSync()); // ❌
// Для синхронных фабрик используйте toProvide:
bind<Db>().toProvide(() => openDbSync());      // ✅
```

Async-провайдеры получайте через `resolveAsync<T>()` / `tryResolveAsync<T>()`.

### 4. `InstanceResolver` / `ProviderResolver` больше не экспортируются

Публичными являются только `BindingResolver<T>` и typedef'ы фабрик. Если вы
реализовывали или ссылались на конкретные классы резолверов, перейдите на
методы билдера `bind<T>()` (`toInstance`, `toProvide`, `toProvideWithParams`,
`toProvideAsync`, `toProvideAsyncWithParams`).

### 5. `toInstanceAsync` устарел

`toInstance` уже принимает `FutureOr<T>`, поэтому уже запущенный `Future` можно
регистрировать напрямую:

```dart
// Было
bind<Environment>().toInstanceAsync(loadEnvironment());

// Стало
bind<Environment>().toInstance(loadEnvironment()); // получать через resolveAsync
```

## Изменение поведения: повторная попытка async-синглтона после ошибки

В 3.x, если провайдер async-синглтона выбрасывал исключение при первой
инициализации, неуспешный результат кэшировался, и каждый последующий
`resolveAsync` повторял ту же ошибку. В 4.0.0 неуспешная инициализация
async-синглтона не кэшируется, поэтому следующий `resolveAsync` повторит
попытку.
