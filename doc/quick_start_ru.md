# Быстрый старт

## Основные компоненты DI


### Binding

Binding - по сути это конфигуратор  для  пользовательского instance, который соддержит методы для конфигурирования зависимости.

Есть два основных метода для инициализации пользовательского instance `toInstance()` и `toProvide()` и вспомогательных `withName()` и `singleton()`.

`toInstance()` - принимает готовый экземпляр

`toProvide()` -  принимает функцию `provider` (конструктор экземпляра)

`withName()` - принимает строку для именования экземпляра. По этому имени можно будет извлечь instance из  DI контейнера

`singleton()` -  устанавливает флаг в Binding, который говорит DI контейнеру, что зависимость одна.

Пример:

```dart
 // инициализация экземпляра текстовой строки через метод toInstance()
 Binding<String>().toInstance("hello world");

 // или

 // инициализация экземпляра текстовой строки
 Binding<String>().toProvide(() => "hello world");

 // инициализация экземпляра строки с именем
 Binding<String>().withName("my_string").toInstance("hello world");
 // или
 Binding<String>().withName("my_string").toProvide(() => "hello world");

 // инициализация экземпляра, как сингелтон
 Binding<String>().toInstance("hello world");
 // или
 Binding<String>().toProvide(() => "hello world").singleton();

```

### Module

Module - это контейнер пользовательских instances, и на основе которого пользователь может создавать свои модули. Пользователь в своем модуле должен реализовать метод `void builder(Scope currentScope)`.


Пример:

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
  }
}
```

### Scope

Scope - это контейнер, который хранит все дерево зависимостей (scope,modules,instances).
Через scope можно получить доступ к `instance`, для этого нужно вызвать метод `resolve<T>()` и указать тип объекта, а так же можно передать дополнительные параметры.

Пример:

```dart
    // открыть главный scope
    final rootScope =  CherryPick.openRootScope();

    // инициализация scope пользовательским модулем
    rootScope.installModules([AppModule()]);

    // получаем экземпляр класса 
    final str = rootScope.resolve<String>();
    // или
    final str = rootScope.tryResolve<String>();

    // Рекомендуется: закрывайте главный scope для автоматического освобождения всех ресурсов
    await Cherrypick.closeRootScope();
    // Или, для продвинутых/ручных сценариев:
    // await rootScope.dispose();
```

### Автоматическое управление ресурсами (`Disposable`, `dispose`)

Если ваш сервис реализует интерфейс `Disposable`, CherryPick автоматически дождётся выполнения `dispose()` при закрытии scope.

**Рекомендация:**  
Завершайте работу через `await Cherrypick.closeRootScope()` (для root scope) или `await scope.closeSubScope('feature')` (для подскоупов).  
Эти методы автоматически await-ят `dispose()` для всех разрешённых через DI объектов, реализующих `Disposable`, обеспечивая корректную очистку (sync и async) и высвобождение ресурсов.

Вызывайте `await scope.dispose()` если вы явно управляете custom-скоупом.

#### Пример

```dart
class MyService implements Disposable {
  @override
  FutureOr<void> dispose() async {
    // закрытие ресурса, соединений, таймеров и т.п., async/await
    print('MyService disposed!');
  }
}

final scope = openRootScope();
scope.installModules([
  ModuleImpl(),
]);

final service = scope.resolve<MyService>();

// ... используем сервис ...

// Рекомендуемый финал:
await Cherrypick.closeRootScope(); // выведет в консоль 'MyService disposed!'

// Или для подскоупа:
await scope.closeSubScope('feature');

class ModuleImpl extends Module {
  @override
  void builder(Scope scope) {
    bind<MyService>().toProvide(() => MyService()).singleton();
  }
}
```

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

## Пример приложения


```dart
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().withName("apiClientMock").toInstance(ApiClientMock());
    bind<ApiClient>().withName("apiClientImpl").toInstance(ApiClientImpl());
  }
}

class FeatureModule extends Module {
  bool isMock;

  FeatureModule({required this.isMock});

  @override
  void builder(Scope currentScope) {
    bind<DataRepository>()
        .withName("networkRepo")
        .toProvide(
          () => NetworkDataRepository(
            currentScope.resolve<ApiClient>(
              named: isMock ? "apiClientMock" : "apiClientImpl",
            ),
          ),
        )
        .singleton();
    bind<DataBloc>().toProvide(
      () => DataBloc(
        currentScope.resolve<DataRepository>(named: "networkRepo"),
      ),
    );
  }
}

void main() async {
  final scope = openRootScope().installModules([
    AppModule(),
  ]);

  final subScope = scope
      .openSubScope("featureScope")
      .installModules([FeatureModule(isMock: true)]);

  final dataBloc = subScope.resolve<DataBloc>();
  dataBloc.data.listen((d) => print('Received data: $d'),
      onError: (e) => print('Error: $e'), onDone: () => print('DONE'));

  await dataBloc.fetchData();
}

class DataBloc {
  final DataRepository _dataRepository;

  Stream<String> get data => _dataController.stream;
  StreamController<String> _dataController = new StreamController.broadcast();

  DataBloc(this._dataRepository);

  Future<void> fetchData() async {
    try {
      _dataController.sink.add(await _dataRepository.getData());
    } catch (e) {
      _dataController.sink.addError(e);
    }
  }

  void dispose() {
    _dataController.close();
  }
}

abstract class DataRepository {
  Future<String> getData();
}

class NetworkDataRepository implements DataRepository {
  final ApiClient _apiClient;
  final _token = 'token';

  NetworkDataRepository(this._apiClient);

  @override
  Future<String> getData() async => await _apiClient.sendRequest(
      url: 'www.google.com', token: _token, requestBody: {'type': 'data'});
}

abstract class ApiClient {
  Future sendRequest({@required String url, String token, Map requestBody});
}

class ApiClientMock implements ApiClient {
  @override
  Future sendRequest(
      {@required String? url, String? token, Map? requestBody}) async {
    return 'Local Data';
  }
}

class ApiClientImpl implements ApiClient {
  @override
  Future sendRequest(
      {@required String? url, String? token, Map? requestBody}) async {
    return 'Network data';
  }
}
```
