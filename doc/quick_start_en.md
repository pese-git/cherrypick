# Quick start

## Main components DI


### Binding

Binding is a custom instance configurator that contains methods for configuring a dependency.

There are two main methods for initializing a custom instance `toInstance ()` and `toProvide ()` and auxiliary `withName ()` and `singleton ()`.

`toInstance()` - takes a initialized instance

`toProvide()` -  takes a `provider` function (instance constructor)

`withName()` - takes a string to name the instance. By this name, it will be possible to extract instance from the DI container

`singleton()` -  sets a flag in the Binding that tells the DI container that there is only one dependency.

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
 Binding<String>().toProvide(() => "hello world").singleton();

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
    final rootScope =  Cherrypick.openRootScope();

    // initializing scope with a custom module
    rootScope.installModules([AppModule()]);

    // takes custom instance
    final str = rootScope.resolve<String>();
    // or
    final str = rootScope.tryResolve<String>();

    // Recommended: Close the root scope & automatically release all Disposable resources
    await Cherrypick.closeRootScope();
    // Or, for advanced/manual scenarios:
    // await rootScope.dispose();
```

### Automatic resource management (`Disposable`, `dispose`)

If your service implements the `Disposable` interface, CherryPick will automatically await `dispose()` when you close a scope.

**Best practice:**  
Always finish your work with `await Cherrypick.closeRootScope()` (for the root scope) or `await scope.closeSubScope('feature')` (for subscopes).  
These methods will automatically await `dispose()` on all resolved objects implementing `Disposable`, ensuring safe and complete cleanup (sync and async). 

Manual `await scope.dispose()` is available if you manage scopes yourself.

#### Example

```dart
class MyService implements Disposable {
  @override
  FutureOr<void> dispose() async {
    // release resources, close connections, perform async shutdown, etc.
    print('MyService disposed!');
  }
}

final scope = openRootScope();
scope.installModules([
  ModuleImpl(),
]);

final service = scope.resolve<MyService>();

// ... use service

// Recommended:
await Cherrypick.closeRootScope(); // will print: MyService disposed!

// Or, to close a subscope:
await scope.closeSubScope('feature');

class ModuleImpl extends Module {
  @override
  void builder(Scope scope) {
    bind<MyService>().toProvide(() => MyService()).singleton();
  }
}
```

## Logging

To enable logging of all dependency injection (DI) events and errors in CherryPick, set the global logger before creating your scopes:

```dart
import 'package:cherrypick/cherrypick.dart';

void main() {
  // Set a global logger before any scopes are created
  CherryPick.setGlobalLogger(PrintLogger()); // or your own custom logger
  final scope = CherryPick.openRootScope();
  // All DI events and cycle errors will now be sent to your logger
}
```

- By default, CherryPick uses SilentLogger (no output in production).
- Any dependency resolution, scope events, or cycle detection errors are logged via info/error on your logger.

## Example app


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