# CherryPick Flutter

`cherrypick_flutter` is a powerful Flutter library for managing and accessing dependencies within your application through a root scope context using `CherryPickProvider`. It offers simplified dependency injection, making your application more modular and test-friendly.

## Quick Start

### Main Components in Dependency Injection (DI)

#### Binding

A Binding is a custom instance configurator, essential for setting up dependencies. It offers the following key methods:

- `toInstance()`: Directly provides an initialized instance.
- `toProvide()`: Accepts a provider function or constructor for lazy initialization.
- `withName()`: Assigns a name to an instance, allowing for retrieval by name.
- `singleton()`: Marks the instance as a singleton, ensuring only one instance exists in the scope.

##### Example:

```dart
// Direct instance initialization with toInstance()
Binding<String>().toInstance("hello world");

// Or use a provider for lazy initialization
Binding<String>().toProvide(() => "hello world");

// Named instance
Binding<String>().withName("my_string").toInstance("hello world");

// Singleton instance
Binding<String>().toProvide(() => "hello world").singleton();
```

#### Module

A Module encapsulates bindings, allowing you to organize dependencies logically. To create a custom module, implement the `void builder(Scope currentScope)` method.

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

A Scope is the container that manages your dependency tree, holding modules and instances. Use the scope to access dependencies with the `resolve<T>()` method.

##### Example:

```dart
// Open the main scope
final rootScope = Cherrypick.openRootScope();

// Install custom modules
rootScope.installModules([AppModule()]);

// Resolve an instance
final str = rootScope.resolve<String>();

// Close the main scope
Cherrypick.closeRootScope();
```

## Example Application

The following example demonstrates module setup, scope management, and dependency resolution.

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

## Features

- [x] Main Scope and Sub Scopes
- [x] Named Instance Initialization

## Contributing

We welcome contributions from the community. Please feel free to submit issues or pull requests with suggestions or improvements.

## License

This project is licensed under the Apache License 2.0. You may obtain a copy of the License at [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

**Important:** Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for specific language governing permissions and limitations under the License.

## Links

- [GitHub Repository](https://github.com/pese-git/cherrypick)