# CherryPick

`cherrypick` is a flexible and lightweight dependency injection library for Dart and Flutter. It provides an easy-to-use system for registering, scoping, and resolving dependencies using modular bindings and hierarchical scopes. The design enables cleaner architecture, testability, and modular code in your applications.

## Key Concepts

### Binding

A **Binding** acts as a configuration for how to create or provide a particular dependency. Bindings support:


- Direct instance assignment (`toInstance()`, `toInstanceAsync()`)
- Lazy providers (sync/async functions)
- Provider functions supporting dynamic parameters
- Named instances for resolving by string key
- Optional singleton lifecycle

#### Example

```dart
// Provide a direct instance
Binding<String>().toInstance("Hello world");

// Provide an async direct instance
Binding<String>().toInstanceAsync(Future.value("Hello world"));

// Provide a lazy sync instance using a factory
Binding<String>().toProvide(() => "Hello world");

// Provide a lazy async instance using a factory
Binding<String>().toProvideAsync(() async => "Hello async world");

// Provide an instance with dynamic parameters (sync)
Binding<String>().toProvideWithParams((params) => "Hello $params");

// Provide an instance with dynamic parameters (async)
Binding<String>().toProvideAsyncWithParams((params) async => "Hello $params");

// Named instance for retrieval by name
Binding<String>().toProvide(() => "Hello world").withName("my_string");

// Mark as singleton (only one instance within the scope)
Binding<String>().toProvide(() => "Hello world").singleton();
```

### Module

A **Module** is a logical collection point for bindings, designed for grouping and initializing related dependencies. Implement the `builder` method to define how dependencies should be bound within the scope.

#### Example

```dart
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
    bind<String>().toProvide(() => "Hello world!");
  }
}
```

### Scope

A **Scope** manages a tree of modules and dependency instances. Scopes can be nested into hierarchies (parent-child), supporting modular app composition and context-specific overrides.

You typically work with the root scope, but can also create named subscopes as needed.

#### Example

```dart
// Open the main/root scope
final rootScope = CherryPick.openRootScope();

// Install a custom module
rootScope.installModules([AppModule()]);

// Resolve a dependency synchronously
final str = rootScope.resolve<String>();

// Resolve a dependency asynchronously
final result = await rootScope.resolveAsync<String>();

// Close the root scope once done
CherryPick.closeRootScope();
```

#### Working with Subscopes

```dart
// Open a named child scope (e.g., for a feature/module)
final subScope = rootScope.openSubScope('featureScope')
  ..installModules([FeatureModule()]);

// Resolve from subScope, with fallback to parents if missing
final dataBloc = await subScope.resolveAsync<DataBloc>();
```

### Dependency Lookup API

- `resolve<T>()` — Locates a dependency instance or throws if missing.
- `resolveAsync<T>()` — Async variant for dependencies requiring async binding.
- `tryResolve<T>()` — Returns `null` if not found (sync).
- `tryResolveAsync<T>()` — Returns `null` async if not found.

Supports:
- Synchronous and asynchronous dependencies
- Named dependencies
- Provider functions with and without runtime parameters

## Example Application

Below is a complete example illustrating modules, subscopes, async providers, and dependency resolution.

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
    // Async provider for DataRepository with named dependency selection
    bind<DataRepository>()
        .withName("networkRepo")
        .toProvideAsync(() async {
          final client = await Future.delayed(
            Duration(milliseconds: 100),
            () => currentScope.resolve<ApiClient>(
              named: isMock ? "apiClientMock" : "apiClientImpl",
            ),
          );
          return NetworkDataRepository(client);
        })
        .singleton();

    // Chained async provider for DataBloc
    bind<DataBloc>().toProvideAsync(
      () async {
        final repo = await currentScope.resolveAsync<DataRepository>(
            named: "networkRepo");
        return DataBloc(repo);
      },
    );
  }
}

void main() async {
  final scope = CherryPick.openRootScope().installModules([AppModule()]);
  final featureScope = scope.openSubScope("featureScope")
    ..installModules([FeatureModule(isMock: true)]);

  final dataBloc = await featureScope.resolveAsync<DataBloc>();
  dataBloc.data.listen(
    (d) => print('Received data: $d'),
    onError: (e) => print('Error: $e'),
    onDone: () => print('DONE'),
  );

  await dataBloc.fetchData();
}

class DataBloc {
  final DataRepository _dataRepository;
  Stream<String> get data => _dataController.stream;
  final StreamController<String> _dataController = StreamController.broadcast();

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
  Future<String> getData() async =>
      await _apiClient.sendRequest(
        url: 'www.google.com',
        token: _token,
        requestBody: {'type': 'data'},
      );
}

abstract class ApiClient {
  Future sendRequest({@required String? url, String? token, Map? requestBody});
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

- [x] Main Scope and Named Subscopes
- [x] Named Instance Binding and Resolution
- [x] Asynchronous and Synchronous Providers
- [x] Providers Supporting Runtime Parameters
- [x] Singleton Lifecycle Management
- [x] Modular and Hierarchical Composition
- [x] Null-safe Resolution (tryResolve/tryResolveAsync)

## Contributing

Contributions are welcome! Please open issues or submit pull requests on [GitHub](https://github.com/pese-git/cherrypick).

## License

Licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

---

**Important:** Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for specific language governing permissions and limitations under the License.

## Links

- [GitHub Repository](https://github.com/pese-git/cherrypick)