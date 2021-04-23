# Quick start

## Main components DI


### Binding

Binding is a custom instance configurator that contains methods for configuring a dependency.

There are two main methods for initializing a custom instance `toInstance ()` and `toProvide ()` and auxiliary `withName ()` and `singeltone ()`.

`toInstance()` - takes a initialized instance

`toProvide()` -  takes a `provider` function (instance constructor)

`withName()` - takes a string to name the instance. By this name, it will be possible to extract instance from the DI container

`singeltone()` -  sets a flag in the Binding that tells the DI container that there is only one dependency.

Example:

```dart
 // initializing a text string instance through a method toInstance()
 Binding<String>().toInstance("hello world");

 // or

 // initializing a text string instance
 Binding<String>().toProvide(() => "hello world");

 // initializing an instance of a string named
 Binding<String>().withName("my_string").toInstance("hello world");
 // or
 Binding<String>().withName("my_string").toProvide(() => "hello world");

 // instance initialization like singleton
 Binding<String>().toInstance("hello world");
 // or
 Binding<String>().toProvide(() => "hello world").singeltone();

```

### Module

Module is a container of user instances, and on the basis of which the user can create their modules. The user in his module must implement the `void builder (Scope currentScope)` method.


Example:

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
  }
}
```

### Scope

Scope is a container that stores the entire dependency tree (scope, modules, instances).
Through the scope, you can access the custom `instance`, for this you need to call the `resolve<T>()` method and specify the type of the object, and you can also pass additional parameters.

Example:

```dart
    // open main scope
    final rootScope =  DartDi.openRootScope();

    // initializing scope with a custom module
    rootScope.installModules([AppModule()]);

    // takes custom instance
    final str = rootScope.resolve<String>();
    // or
    final str = rootScope.tryResolve<String>();

    // close main scope
    DartDi.closeRootScope();
```

## Example app


```dart
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:dart_di/experimental/scope.dart';
import 'package:dart_di/experimental/module.dart';

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
        .singeltone();
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