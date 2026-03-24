# Полный гайд по CherryPick DI для Dart и Flutter: внедрение зависимостей с аннотациями и автоматической генерацией кода

**CherryPick** — это мощный инструмент для инъекции зависимостей в проектах на Dart и Flutter. Он предлагает современный подход с поддержкой генерации кода, асинхронных провайдеров, именованных и параметризируемых биндингов, а также field injection с использованием аннотаций.

> Инструменты:  
> - [`cherrypick`](https://pub.dev/packages/cherrypick) — runtime DI core  
> - [`cherrypick_annotations`](https://pub.dev/packages/cherrypick_annotations) — аннотации для DI  
> - [`cherrypick_generator`](https://pub.dev/packages/cherrypick_generator) — генерация DI-кода  
>

---

## Преимущества CherryPick по сравнению с другими DI-фреймворками

- 📦 Простой декларативный API для регистрации и разрешения зависимостей.
- ⚡️ Полная поддержка синхронных _и_ асинхронных регистраций.
- 🧩 DI через аннотации с автогенерацией кода, включая field injection.
- 🏷️ Именованные зависимости (named bindings).
- 🏭 Параметризация биндингов для runtime-использования фабрик.
- 🌲 Гибкая система Scope'ов для изоляции и иерархии зависимостей.
- 🕹️ Опциональное разрешение (tryResolve).
- 🐞 Ясные compile-time ошибки при неправильной аннотации или неверном DI-описании.

---

## Как работает CherryPick: основные концепции

### Регистрация зависимостей: биндинги

```dart
bind<MyService>().toProvide(() => MyServiceImpl());
bind<MyRepository>().toProvideAsync(() async => await initRepo());
bind<UserService>().toProvideWithParams((id) => UserService(id));

// Singleton
bind<MyApi>().toProvide(() => MyApi()).singleton();

// Зарегистрировать уже существующий объект
final config = AppConfig.dev();
bind<AppConfig>().toInstance(config);

// Зарегистрировать уже существующий Future/асинхронное значение
final setupFuture = loadEnvironment();
bind<Environment>().toInstanceAsync(setupFuture);
```


> ⚠️ **Важное примечание по использованию toInstance в Module**
>
> Если вы регистрируете цепочку зависимостей через `toInstance` внутри метода `builder` вашего `Module`, нельзя в это же время вызывать `scope.resolve<T>()` для только что объявленного типа.
>
> CherryPick инициализирует биндинги последовательно внутри builder: в этот момент ещё не все зависимости зарегистрированы в DI-контейнере. Попытка воспользоваться `scope.resolve<T>()` для только что добавленного объекта приведёт к ошибке (`Can't resolve dependency ...`).
>
> **Как правильно:**  
> Складывайте всю цепочку вручную до регистрации:
>
> ```dart
> void builder(Scope scope) {
>   final a = A();
>   final b = B(a);
>   final c = C(b);
>   bind<A>().toInstance(a);
>   bind<B>().toInstance(b);
>   bind<C>().toInstance(c);
> }
> ```
>
> **Неправильно:**
> ```dart
> void builder(Scope scope) {
>   bind<A>().toInstance(A());
>   // Ошибка! В этот момент A ещё не зарегистрирован.
>   bind<B>().toInstance(B(scope.resolve<A>()));
> }
> ```
>
> **Неправильно:**
> ```dart
> void builder(Scope scope) {
>   bind<A>().toProvide(() => A());
>   // Ошибка! В этот момент A ещё не зарегистрирован.
>   bind<B>().toInstance(B(scope.resolve<A>()));
> }
> ```
>
> **Примечание:** Это ограничение касается только `toInstance`. Для провайдеров (`toProvide`/`toProvideAsync`) и других стратегий вы можете использовать `scope.resolve<T>()` внутри builder без ограничений.



- **toProvide** — обычная синхронная фабрика.
- **toProvideAsync** — асинхронная фабрика (например, если нужно дожидаться Future).
- **toProvideWithParams / toProvideAsyncWithParams** — фабрики с параметрами.
- **toInstance** — регистрирует уже созданный экземпляр класса как зависимость.
- **toInstanceAsync** — регистрирует уже запущенный Future, как асинхронную зависимость.

### Именованные биндинги (Named)

Можно регистрировать несколько реализаций одного интерфейса под разными именами:

```dart
bind<ApiClient>().toProvide(() => ApiClientProd()).withName('prod');
bind<ApiClient>().toProvide(() => ApiClientMock()).withName('mock');

// Получение по имени:
final api = scope.resolve<ApiClient>(named: 'mock');
```

### Жизненный цикл: singleton

- `.singleton()` — один инстанс на всё время жизни Scope.
- По умолчанию каждый resolve создаёт новый объект.

> ℹ️ **Примечание о `.singleton()` и `.toInstance()`:**
>
> Вызов `.singleton()` после `.toInstance()` не изменяет поведения биндинга: объект, переданный через `toInstance()`, и так всегда будет "единственным" (single instance), возвращаемым при каждом resolve.
>
> Применять `.singleton()` к уже существующему объекту нет необходимости — этот вызов ничего не меняет.
>
> `.singleton()` нужен только для провайдеров (например, `toProvide`/`toProvideAsync`), чтобы зафиксировать единственный экземпляр, создаваемый фабрикой.


### Параметрические биндинги

Позволяют создавать зависимости с runtime-параметрами — например, сервис для пользователя с ID:

```dart
bind<UserService>().toProvideWithParams((userId) => UserService(userId));

// Получение
final userService = scope.resolve<UserService>(params: '123');
```

> ⚠️ **Особенности использования `.singleton()` после `toProvideWithParams` или `toProvideAsyncWithParams`:**
>
> Если вы объявляете биндинг через `.toProvideWithParams((params) => ...)` (или асинхронный вариант) и затем вызываете `.singleton()`, DI-контейнер создаст и закэширует **только один экземпляр** при первом вызове `resolve` — с первыми переданными параметрами. Все последующие вызовы `resolve<T>(params: ...)` вернут этот же (кэшированный) объект **независимо от новых параметров**.
>
> **Пример:**
> ```dart
> bind<Service>().toProvideWithParams((params) => Service(params)).singleton();
>
> final a = scope.resolve<Service>(params: 1); // Создаётся Service(1)
> final b = scope.resolve<Service>(params: 2); // Возвращается уже Service(1)
> print(identical(a, b)); // true
> ```
>
> То есть:  
> - параметры работают только для первого вызова,
> - дальше всегда возвращается экземпляр, созданный при первом обращении.
>
> **Рекомендация:**  
> Используйте `.singleton()` совместно с провайдерами с параметрами только тогда, когда вы точно уверены, что все параметры всегда должны совпадать, или нужны именно “мастер”-экземпляры. В противном случае не используйте `.singleton()`, чтобы каждый вызов с новыми parameters создавал новый объект.

---

## Управление Scope'ами: иерархия зависимостей

Для большинства бизнес-кейсов достаточно одного Scope (root), но CherryPick поддерживает создание вложенных Scope:

```dart
final rootScope = CherryPick.openRootScope();
final profileScope = rootScope.openSubScope('profile')
    ..installModules([ProfileModule()]);
```

- **Под-скоуп** может переопределять зависимости родителя.
- При разрешении сначала проверяется свой Scope, потом иерархия вверх.


## Работа с именованием и иерархией подскоупов (subscopes) в CherryPick

CherryPick поддерживает вложенные области видимости (scopes), где каждый scope может быть как "корневым", так и дочерним. Для доступа и управления иерархией используется понятие **scope name** (имя области видимости), а также удобные методы для открытия и закрытия скопов по строковым идентификаторам.

### Открытие subScope по имени

CherryPick использует строки с разделителями для поиска и построения дерева областей видимости. Например:

```dart
final subScope = CherryPick.openScope(scopeName: 'profile.settings');
```

- Здесь `'profile.settings'` означает, что сначала откроется подскоуп `profile` у rootScope, затем — подскоуп `settings` у `profile`.
- Разделитель по умолчанию — точка (`.`). Его можно изменить, указав `separator` аргументом.

**Пример с другим разделителем:**

```dart
final subScope = CherryPick.openScope(
  scopeName: 'project>>dev>>api',
  separator: '>>',
);
```

### Иерархия и доступ

Каждый уровень иерархии соответствует отдельному scope.  
Это удобно для ограничения и локализации зависимостей, например:  
- `main.profile` — зависимости только для профиля пользователя  
- `main.profile.details` — ещё более "узкая" область видимости

### Закрытие подскоупов

Чтобы закрыть конкретный subScope, используйте тот же путь:

```dart
CherryPick.closeScope(scopeName: 'profile.settings');
```

- Если закрываете верхний скоуп (`profile`), все дочерние тоже будут очищены.

### Кратко о методах

| Метод                    | Описание                                                |
|--------------------------|--------------------------------------------------------|
| `openRootScope()`        | Открыть/получить корневой scope                        |
| `closeRootScope()`       | Закрыть root scope, удалить все зависимости            |
| `openScope(scopeName)`   | Открыть scope(ы) по имени с иерархией (`'a.b.c'`)      |
| `closeScope(scopeName)`  | Закрыть указанный scope или subscope                   |

---

**Рекомендации:**  
Используйте осмысленные имена и "точечную" нотацию для структурирования зон видимости в крупных приложениях — это повысит читаемость и позволит удобно управлять зависимостями на любых уровнях.

---

**Пример:**

```dart
// Откроет scopes по иерархии: app -> module -> page
final scope = CherryPick.openScope(scopeName: 'app.module.page');

// Закроет 'module' и все вложенные subscopes
CherryPick.closeScope(scopeName: 'app.module');
```

---

Это позволит масштабировать DI-подход CherryPick в приложениях любой сложности!

---

## Безопасное разрешение зависимостей

Если не уверены, что нужная зависимость есть, используйте tryResolve/tryResolveAsync:

```dart
final service = scope.tryResolve<OptionalService>(); // вернет null, если нет
```

---

### Быстрый поиск зависимостей (Performance Improvement)

> **Примечание по производительности:**  
> Начиная с версии **3.0.0**, CherryPick для поиска зависимости внутри scope использует Map-индекс. Благодаря этому методы `resolve<T>()`, `tryResolve<T>()` и аналогичные теперь работают за O(1), независимо от количества модулей и биндингов в вашем проекте. Ранее для поиска приходилось перебирать весь список вручную, что могло замедлять работу крупных приложений. Это внутреннее улучшение не меняет внешнего API или паттернов использования, но заметно ускоряет разрешение зависимостей на больших проектах.

---

## Автоматическое управление ресурсами: Disposable и dispose

CherryPick позволяет автоматически очищать ресурсы для ваших синглтонов и любых сервисов, зарегистрированных через DI.  
Если ваш класс реализует интерфейс `Disposable`, всегда вызывайте и **await**-те `scope.dispose()` (или `CherryPick.closeRootScope()`), когда хотите освободить все ресурсы — CherryPick дождётся завершения `dispose()` для всех объектов, которые реализуют Disposable и были резолвлены из DI.  
Это позволяет избежать утечек памяти, корректно завершать процессы и грамотно освобождать любые ресурсы (файлы, потоки, соединения и т.д., включая async).

### Пример

```dart
class LoggingService implements Disposable {
  @override
  FutureOr<void> dispose() async {
    // Закрыть файлы, потоки, соединения и т.д. (можно с await)
    print('LoggingService disposed!');
  }
}

Future<void> main() async {
  final scope = openRootScope();
  scope.installModules([
    _LoggingModule(),
  ]);
  final logger = scope.resolve<LoggingService>();
  // Используем logger...
  await scope.dispose(); // выведет: LoggingService disposed!
}

class _LoggingModule extends Module {
  @override
  void builder(Scope scope) {
    bind<LoggingService>().toProvide(() => LoggingService()).singleton();
  }
}
```

## Внедрение зависимостей через аннотации и автогенерацию

CherryPick поддерживает DI через аннотации, что позволяет полностью избавиться от ручного внедрения зависимостей.

### Структура аннотаций

| Аннотация     | Для чего                  | Где применяют                    |
| ------------- | ------------------------- | -------------------------------- |
| `@module`     | DI-модуль                 | Классы                           |
| `@singleton`  | Singleton                 | Методы класса                    |
| `@instance`   | Новый объект              | Методы класса                    |
| `@provide`    | Провайдер                 | Методы (с DI params)             |
| `@named`      | Именованный биндинг       | Аргумент метода/Аттрибуты класса |
| `@params`     | Передача параметров       | Аргумент провайдера              |
| `@injectable` | Поддержка field injection | Классы                           |
| `@inject`     | Автовнедрение             | Аттрибуты класса                 |
| `@scope`      | Scope/realm               | Аттрибуты класса                 |

### Пример DI-модуля

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule extends Module {
  @singleton()
  @provide()
  ApiClient apiClient() => ApiClient();

  @provide()
  UserService userService(ApiClient api) => UserService(api);

  @singleton()
  @provide()
  @named('mock')
  ApiClient mockApiClient() => ApiClientMock();
}
```
- Методы, отмеченные `@provide`, становятся фабриками DI.  
- Можно добавлять другие аннотации для уточнения типа биндинга, имени.

Сгенерированный код будет выглядеть вот таким образом:

```dart
class $AppModule extends AppModule {
	@override
	void builder(Scope currentScope) {
		bind<ApiClient>().toProvide(() => apiClient()).singelton();
		bind<UserService>().toProvide(() => userService(currentScope.resolve<ApiClient>()));
		bind<ApiClient>().toProvide(() => mockApiClient()).withName('mock').singelton();
	}	
}
```


### Пример инъекций зависимостей через field injection

```dart
@injectable()
class ProfileBloc with _$ProfileBloc {
  @inject()
  late final AuthService auth;

  @inject()
  @named('admin')
  late final UserService adminUser;
  
  ProfileBloc() {
    _inject(this); // injectFields — сгенерированный метод
  }
}
```
- Генератор создаёт mixin (`_$ProfileBloc`), который автоматически резолвит и подставляет зависимости в поля класса.
- Аннотация `@named` привязывает конкретную реализацию по имени.

Сгенерированный код будет выглядеть вот таким образом:

```dart
mixin $ProfileBloc {
	@override
	void _inject(ProfileBloc instance) {
		instance.auth = CherryPick.openRootScope().resolve<AuthService>();
		instance.adminUser = CherryPick.openRootScope().resolve<UserService>(named: 'admin');
	}	
}
```


### Как это подключается

```dart
void main() async {
  final scope = CherryPick.openRootScope();
  scope.installModules([
    $AppModule(),
  ]);
  // DI через field injection
  final bloc = ProfileBloc();
  runApp(MyApp(bloc: bloc));
}
```

---

## Асинхронные зависимости

Для асинхронных провайдеров используйте `toProvideAsync`, а получать их — через `resolveAsync`:

```dart
bind<RemoteConfig>().toProvideAsync(() async => await RemoteConfig.load());

// Использование:
final config = await scope.resolveAsync<RemoteConfig>();
```

---

## Проверка и диагностика

- При неправильных аннотациях или ошибках DI появляется понятное compile-time сообщение.
- Ошибки биндингов выявляются при генерации кода. Это минимизирует runtime-ошибки и ускоряет разработку.

---

## Использование CherryPick с Flutter: пакет cherrypick_flutter

### Что это такое

[`cherrypick_flutter`](https://pub.dev/packages/cherrypick_flutter) — это пакет интеграции CherryPick DI с Flutter. Он предоставляет удобный виджет-провайдер `CherryPickProvider`, который размещается в вашем дереве виджетов и даёт доступ к root scope DI (и подскоупам) прямо из контекста.

### Ключевые возможности

- **Глобальный доступ к DI Scope:**  
  Через `CherryPickProvider` вы легко получаете доступ к rootScope и подскоупам из любого места дерева Flutter.
- **Интеграция с контекстом:**  
  Используйте `CherryPickProvider.of(context)` для доступа к DI внутри ваших виджетов.

### Пример использования

```dart
import 'package:flutter/material.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';

void main() {
  runApp(
    CherryPickProvider(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).openRootScope();

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            rootScope.resolve<AppService>().getStatus(),
          ),
        ),
      ),
    );
  }
}
```

- В этом примере `CherryPickProvider` оборачивает приложение и предоставляет доступ к DI scope через контекст.
- Вы можете создавать подскоупы, если нужно, например, для экранов или модулей:  
  `final subScope = CherryPickProvider.of(context).openSubScope(scopeName: "profileFeature");`

---

## Логирование

Чтобы включить вывод логов о событиях и ошибках DI в CherryPick, настройте глобальный логгер до создания любых scope:

```dart
import 'package:cherrypick/cherrypick.dart';

void main() {
  // Установите глобальный логгер до создания scope
  CherryPick.setGlobalLogger(PrintLogger()); // или свой логгер
  final scope = CherryPick.openRootScope();
  // Логи DI и циклов будут выводиться через ваш логгер
}
```

- По умолчанию используется SilentLogger (нет логов в продакшене).
- Любые ошибки резолва и события циклов логируются через info/error на логгере.

---
## CherryPick подходит не только для Flutter!

Вы можете использовать CherryPick и в Dart CLI, серверных проектах и микросервисах. Все основные возможности доступны и без Flutter.

---

## Пример проекта на CherryPick: полный путь

1. Установите зависимости:
    ```yaml
    dependencies:
      cherrypick: ^1.0.0
      cherrypick_annotations: ^1.0.0

    dev_dependencies:
      build_runner: ^2.0.0
      cherrypick_generator: ^1.0.0
    ```

2. Описываете свои модули с помощью аннотаций.

3. Для автоматической генерации DI кода используйте:
    ```shell
    dart run build_runner build --delete-conflicting-outputs
    ```

4. Наслаждайтесь современным DI без боли!

---

## Заключение

**CherryPick** — это современное DI-решение для Dart и Flutter, сочетающее лаконичный API и расширенные возможности аннотирования и генерации кода. Гибкость Scopes, параметрические провайдеры, именованные биндинги и field-injection делают его особенно мощным как для небольших, так и для масштабных проектов.


**Полный список аннотаций и их предназначение:**

| Аннотация     | Для чего                  | Где применяют                    |
| ------------- | ------------------------- | -------------------------------- |
| `@module`     | DI-модуль                 | Классы                           |
| `@singleton`  | Singleton                 | Методы класса                    |
| `@instance`   | Новый объект              | Методы класса                    |
| `@provide`    | Провайдер                 | Методы (с DI params)             |
| `@named`      | Именованный биндинг       | Аргумент метода/Аттрибуты класса |
| `@params`     | Передача параметров       | Аргумент провайдера              |
| `@injectable` | Поддержка field injection | Классы                           |
| `@inject`     | Автовнедрение             | Аттрибуты класса                 |
| `@scope`      | Scope/realm               | Аттрибуты класса                 |

---

## FAQ

### В: Нужно ли использовать `await` для CherryPick.closeRootScope(), CherryPick.closeScope() или scope.dispose(), если ни один сервис не реализует Disposable?

**О:**  
Да! Даже если в данный момент ни один сервис не реализует Disposable, всегда используйте `await` при закрытии скоупа. Если в будущем потребуется добавить освобождение ресурсов через dispose, CherryPick вызовет его автоматически без изменения завершения работы ваших скоупов. Такой подход делает управление ресурсами устойчивым и безопасным для любых изменений архитектуры.

---

## Полезные ссылки

- [cherrypick](https://pub.dev/packages/cherrypick)
- [cherrypick_annotations](https://pub.dev/packages/cherrypick_annotations)
- [cherrypick_generator](https://pub.dev/packages/cherrypick_generator)
- [Исходники на GitHub](https://github.com/pese-git/cherrypick)
