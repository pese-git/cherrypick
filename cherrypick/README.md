# CherryPick Flutter

`cherrypick_flutter` is a robust Flutter library designed for managing and accessing dependencies using a scope context provided by `CherryPickProvider`. It enhances your application's modularity and testability by simplifying dependency injection.

## Quick Start

### Core Components of Dependency Injection (DI)

#### Binding

A Binding is a custom instance configurator crucial for setting up dependencies. It offers the following key methods:

- `toInstance()`: Directly provides an initialized instance.
- `toProvide()`: Accepts a provider function for lazy initialization.
- `toProvideAsync()`: Accepts an asynchronous provider for lazy initialization.
- `toProvideWithParams()`: Accepts a provider function requiring dynamic parameters.
- `toProvideAsyncWithParams()`: Accepts an asynchronous provider requiring dynamic parameters.
- `withName()`: Assigns a name for instance retrieval by name.
- `singleton()`: Marks the instance as a singleton, ensuring only one instance exists within the scope.

##### Example:

```dart
// Direct instance initialization using toInstance()
Binding<String>().toInstance("hello world");

// Lazy initialization via provider
Binding<String>().toProvide(() => "hello world");

// Asynchronous lazy initialization
Binding<String>().toProvideAsync(() async => "hello async world");

// Asynchronous lazy initialization with dynamic parameters
Binding<String>().toProvideAsyncWithParams((params) async => "hello $params");

// Initialization with dynamic parameters
Binding<String>().toProvideWithParams((params) => "hello $params");

// Named instance for resolution
Binding<String>().toProvide(() => "hello world").withName("my_string").toInstance("hello world");

// Singleton instance
Binding<String>().toProvide(() => "hello world").singleton();
```

#### Module

A Module encapsulates bindings, logically organizing dependencies. Implement the `void builder(Scope currentScope)` method to create a custom module.

##### Example:

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
  }
}
```

#### Scope

A Scope manages your dependency tree, holding modules and instances. Use the scope to access dependencies with `resolve<T>()` or `resolveAsync<T>()` for asynchronous operations.

##### Example:

```dart
// Open the main scope
final rootScope = CherryPick.openRootScope();

// Install custom modules
rootScope.installModules([AppModule()]);

// Resolve an instance
final str = rootScope.resolve<String>();

// Asynchronously resolve an instance
final asyncStr = await rootScope.resolveAsync<String>();

// Close the main scope
CherryPick.closeRootScope();
```

## Example Application

The following example demonstrates module setup, scope management, and dependency resolution (both synchronous and asynchronous).

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
  final bool isMock;

  FeatureModule({required this.isMock});

  @override
  void builder(Scope currentScope) {
    // Using toProvideAsync for async initialization
    bind<DataRepository>()
        .withName("networkRepo")
        .toProvideAsync(() async {
          final client = await Future.delayed(
              Duration(milliseconds: 100),
              () => currentScope.resolve<ApiClient>(
                  named: isMock ? "apiClientMock" : "apiClientImpl"));
          return NetworkDataRepository(client);
        })
        .singleton();
    
    // Asynchronous initialization of DataBloc
    bind<DataBloc>().toProvideAsync(
      () async {
        final repo = await currentScope.resolveAsync<DataRepository>(named: "networkRepo");
        return DataBloc(repo);
      },
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

  // Asynchronous instance resolution
  final dataBloc = await subScope.resolveAsync<DataBloc>();
  dataBloc.data.listen((d) => print('Received data: $d'),
      onError: (e) => print('Error: $e'), onDone: () => print('DONE'));

  await dataBloc.fetchData();
}

class DataBloc {
  final DataRepository _dataRepository;

  Stream<String> get data => _dataController.stream;
  StreamController<String> _dataController = StreamController.broadcast();

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

## Features

- [x] Main Scope and Sub Scopes
- [x] Named Instance Initialization
- [x] Asynchronous Dependency Resolution
- [x] Dynamic Parameter Support for Providers

## Contributing

We welcome contributions from the community. Please feel free to submit issues or pull requests with suggestions or improvements.

## License

This project is licensed under the Apache License 2.0. You may obtain a copy of the License at [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

**Important:** Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for specific language governing permissions and limitations under the License.

## Links

- [GitHub Repository](https://github.com/pese-git/cherrypick)