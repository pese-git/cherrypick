# dart_di

Экспериментальная разработка DI на ЯП Dart

## Документация

### Быстрый старт

Основным классом для всех операций является `DiContainer`. Вы можете зарегистрировать свои зависимости,
получив `ResolvingContext` через метод `bind<T>()` и используя его различные методы регистрации зависимостей.
Далее вы можете получить зависимости с помощью `resolve<T>()`.

Пример:

```dart
final container = DiContainer();
container.bind<SomeService>().toValue(SomeServiceImpl());
/*
...
 */

// Метод `resolve` просто возвращает зарегистрированный ранее экземпляр
final someService = container.resolve<SomeService>();
```

### Ленивая инициализация

Если вам нужно создать объект в момент резолвинга, вы можете использовать ленивую (другими словами, по запросу) инициализацию объекта 
с помощью метода `toFactoryN()`.

Пример:

```dart
final container = DiContainer();
// В методе `toFactory` вы просто определяете, как построить экземпляр через фабричную лямбду
container.bind<SomeService>().toFactory( () => SomeServiceImpl() );
/*
...
 */
// Метод `resolve()` будет создавать экземпляр через зарегистрированную фабричную лямбду каждый раз, когда вы вызываете его
final someService = container.resolve<SomeService>();
final anotherSomeService = container.resolve<SomeService>();
assert(someService != anotherSomeService);
```

Но обычно у вас есть много типов с разными зависимостями, которые образуют граф зависимостей.

Пример:

```dart
class A {}
class B {}

class C {
    final A a;
    final B b;

    C(this.a, this.b);
}
```


Если вам нужно зарегистрировать некоторый тип, зависящий от других типов из контейнера,
вы можете использовать методы `toFactory1<T1>` - `toFactory8<T1 ... T8>`, где число в конце,
является количеством запрошенных через аргументы типов зависимостей.
(Обратите внимание, что вам нужно определить все зависимости в аргументах - `toFactory2<A1, A2>`).


Пример:

```dart
class SomeService {
    final A a;
    final B b;

    SomeService(this.a, this.b);
}

final container = DiContainer();
container.bind<A>(A::class).toFactory (() => A());
container.bind<B>(B::class).toFactory (() => B());

/// В фабричной лямбде вы определяете, как построить зависимость от других зависимостей
/// (Порядок разрешенных экземпляров соответствует порядку типов аргументов)
container.bind<SomeService>().toFactory2<A, B>((a, b) => SomeService(a, b));

/*
...
 */

/// Получаем экземпляр `SomeService` через resolve своих зависимостей.
/// В нашем случае - это resolve A и B
/// Внимание!!! То, что он будет создавать новые экземпляры A и B каждый раз, когда вы вызываете `resolve` SomeService
final someService = container.resolve<SomeService>();
```

### Время жизни экземпляров и контроль области видимости

Если вы хотите создать экземпляр зарегистрированной зависимости только один раз,
и вам нужно получить/разрешить зависимость много раз в контейнере, то вы можете зарегистрировать
свою зависимость с добавлением `asSingeton()`. Например:

```dart
final container = DiContainer();
container.bind<A>()
  .toFactory(() => A())
  .asSingleton();

container
  .bind<B>()
  .toFactory(() => B());
  .asSingleton();

container.bind<SomeService>().toFactory2<A, B>((a, b) -> SomeService(a, b));

// Код выше означает: Контейнер, регистрирует создание A и B только в первый раз, когда оно будет запрошен,
// и регистрирует создание SomeService каждый раз, когда оно будет запрошен.

final a = container.resolve<A>();
final b = container.resolve<B>();
final anotherA = container.resolve<A>();
final anotherB = container.resolve<B>();

assert(a == anotherA && b == anotherB);

final someService = container.resolve<SomeService>();
final anotherSomeService = container.resolve<SomeService>();

assert(someService != anotherSomeService);
```

Если вы хотите сразу создать свой зарегистрированный экземпляр, вы можете вызвать `resolve()`. Например:


```dart
final container = DiContainer();
// Это заставит создать зависимость после регистрации
container.bind <SomeService>()
  .toFactory(() => SomeService())
  .asSingleton()
  .resolve();
```

Когда вы работаете со сложным приложением, в большинстве случаев вы можете работать со многими модулями с собственными зависимостями.
Эти модули могут быть настроены различными `DiContainer`-ми. И вы можете прикрепить контейнер к другому, как родительский.
В этом случае родительские зависимости будут видны для дочернего контейнера,
и через него вы можете формировать различные области видимости зависимостей. Например:

```dart
final parentContainer = DiContainer();
parentContainer.bind<A>().toFactory(() => A())

final childContainer =  DiContainer(parentContainer);
// Обратите внимание, что родительская зависимость A видна для дочернего контейнера
final a = childContainer.resolve<A>();

/*
// Но следующий код потерпит неудачу с ошибкой, потому что родитель не знает о своем потомке.
final parentContainer = DiContainer();
final childContainer = DiContainer();
childContainer.bind<A>().toFactory(() => A());

// Выдает ошибку
final a = parentContainer.resolve<A>();
 */
```

### Структура библиотеки

Библиотека состоит из DiContainer и Resolver. 
DiContainer - это контейнер со всеми Resolver для разных типов. А `Resolver` - это просто объект, который знает, как разрешить данный тип.
Многие из resolver-ов обернуты другими, поэтому они могут быть составлены для разных вариантов использования.
Resolver - интерфейс, поэтому он имеет много реализаций. Основным является ResolvingContext. 
Вы можете думать об этом как об объекте контекста, который имеет вспомогательные методы для создания различных вариантов  resolver-ов (`toFactory`,` toValue`, `asSingleton`).
Но все они просто используют метод `toResolver` для определения некоторого корневого resolver в контексте.
Когда вы запрашиваете тип из контейнера с помощью метода `resolve<T>()`, он просто находит контекст для типа и вызывает корневой resolver, который может вызывать другие resolver-ы.


Пример (из ```example```): 

```dart
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:dart_di/dart_di.dart';

void main() async {
  final dataModule = new DiContainer()
    ..bind<ApiClient>().toValue(new ApiClientMock())
    ..bind<DataRepository>()
        .toFactory1<ApiClient>((c) => new NetworkDataRepository(c))
    ..bind<DataBloc>().toFactory1<DataRepository>((s) => new DataBloc(s));

  final dataBloc = dataModule.resolve<DataBloc>();
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
      {@required String url, String token, Map requestBody}) async {
    return 'hello world';
  }
}
```
