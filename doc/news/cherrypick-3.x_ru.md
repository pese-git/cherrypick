# Release - CherryPick 3.x

> **CherryPick** — лёгкий и модульный DI-фреймворк для Dart и Flutter, который решает задачу через строгую типизацию, кодогенерацию и контроль за зависимостями.

Недавно вышла версия **3.x**, где появились заметные улучшения.


## Основные изменения в 3.x

* **O(1) разрешение зависимостей** — благодаря Map-индексации биндингов производительность не зависит от размера скоупа в DI графе. На больших проектах это даёт ощутимое ускорение.
* **Защита от циклических зависимостей** — проверка работает как внутри одного scope, так и во всей иерархии. При обнаружении цикла выбрасывается информативное исключение с цепочкой зависимостей.
* **Интеграция с Talker** — все события DI (регистрация, создание, удаление, ошибки) логируются и могут выводиться в консоль или UI.
* **Автоматическая очистка ресурсов** — объекты, реализующие `Disposable`, корректно освобождаются при закрытии scope.
* **Стабилизирована поддержка декларативного подхода** — аннотации и генерация кода теперь работают надёжнее и удобнее для использования в проектах.


## Пример с очисткой ресурсов

```dart
class MyServiceWithSocket implements Disposable {
  @override
  Future<void> dispose() async {
    await socket.close();
    print('Socket закрыт!');
  }
}

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    // singleton Api
    bind<MyServiceWithSocket>()
      .toProvide(() => MyServiceWithSocket())
      .singleton();
  }
}

scope.installModules([AppModule()]);

await CherryPick.closeRootScope(); // дождётся завершения async dispose
```

## Проверка циклических зависимостей

Одна из новинок CherryPick 3.x — встроенная защита от циклов.
Это помогает на раннем этапе отлавливать ситуации, когда сервисы начинают зависеть друг от друга рекурсивно.

### Как включить проверку

Для проверки внутри одного scope:

```dart
final scope = CherryPick.openRootScope();
scope.enableCycleDetection();
```

Для глобальной проверки во всей иерархии:

```dart
CherryPick.enableGlobalCycleDetection();
CherryPick.enableGlobalCrossScopeCycleDetection();
final rootScope = CherryPick.openRootScope();
```

### Как может возникнуть цикл

Предположим, у нас есть два сервиса, которые зависят друг от друга:

```dart
class UserService {
  final OrderService orderService;
  UserService(this.orderService);
}

class OrderService {
  final UserService userService;
  OrderService(this.userService);
}
```

Если зарегистрировать их в одном scope:

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<UserService>().toProvide(() => UserService(scope.resolve());
    bind<OrderService>().toProvide(() => OrderService(scope.resolve()));
  }
}

final scope = CherryPick.openRootScope()
  ..enableCycleDetection()
  ..installModules([AppModule()]);

scope.resolve<UserService>();
```

То при попытке разрешить зависимость будет выброшено исключение:

```bash
❌ Circular dependency detected for UserService
Dependency chain: UserService -> OrderService -> UserService
```

Таким образом, ошибка выявляется сразу, а не «где-то в runtime».

## Интеграция с Talker

CherryPick 3.x позволяет логировать все события DI через [Talker](https://pub.dev/packages/talker): регистрацию, создание объектов, удаление и ошибки. Это удобно для отладки и диагностики графа зависимостей.

Пример подключения:

```dart
final talker = Talker();
final observer = TalkerCherryPickObserver(talker);
CherryPick.setGlobalObserver(observer);
```

После этого в консоли или UI будут отображаться события DI:

```bash
┌───────────────────────────────────────────────────────────────
│ [info]    9:41:33  | [scope opened][CherryPick] scope_1757054493089_7072
└───────────────────────────────────────────────────────────────
┌───────────────────────────────────────────────────────────────
│ [verbose] 9:41:33  | [diagnostic][CherryPick] Scope created: scope_1757054493089_7072 {type: Scope, name: scope_1757054493089_7072, description: scope created}
└───────────────────────────────────────────────────────────────
```

В логе можно увидеть, когда scope создаётся, какие объекты регистрируются и удаляются, а также отлавливать ошибки и циклы в реальном времени.


## Декларативный подход с аннотациями

Помимо полностью программного описания модулей, CherryPick поддерживает **декларативный стиль DI через аннотации**.  
Это позволяет минимизировать ручной код и автоматически генерировать модули и mixin для автоподстановки зависимостей.

Пример декларативного модуля:

```dart
@module()
abstract class AppModule extends Module {
  @provide()
  @singleton()
  Api api() => Api();

  @provide()
  Repo repo(Api api) => Repo(api);
}
````

После генерации кода можно автоматически подтягивать зависимости в виджеты или сервисы:

```dart
@injectable()
class MyScreen extends StatelessWidget with _$MyScreen {
  @inject()
  late final Repo repo;

  MyScreen() {
    _inject(this);
  }
}
```

Таким образом можно выбрать подход в разработке: **программный (императивный) с явной регистрацией зависимостей** или **декларативный через аннотации**.


## Кому может быть полезен CherryPick?

* проектам, где важно гарантировать **отсутствие циклов в графе зависимостей**;
* командам, которые хотят **минимизировать ручной DI-код** и использовать декларативный стиль с аннотациями;
* приложениям, где требуется **автоматическое освобождение ресурсов** (сокеты, контроллеры, потоки).

## Полезные ссылки

* 📦 Пакет: [pub.dev/packages/cherrypick](https://pub.dev/packages/cherrypick)
* 💻 Код: [github.com/pese-git/cherrypick](https://github.com/pese-git/cherrypick)
* 📖 Документация: [cherrypick-di.netlify.app](https://cherrypick-di.netlify.app/)