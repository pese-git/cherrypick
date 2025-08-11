# CherryPick

`cherrypick` is a flexible and lightweight dependency injection library for Dart and Flutter.
It provides an easy-to-use system for registering, scoping, and resolving dependencies using modular bindings and hierarchical scopes. The design enables cleaner architecture, testability, and modular code in your applications.

---

### Fast Dependency Lookup (Performance Improvement)

> **Performance Note:**  
> **Starting from version 3.0.0**, CherryPick uses a Map-based resolver index for dependency lookup. This means calls to `resolve<T>()` and related methods are now O(1) operations, regardless of the number of modules or bindings in your scope. Previously, the library had to iterate over all modules and bindings to locate the requested dependency, which could impact performance as your project grew.
>
> This optimization is internal and does not change any library APIs or usage patterns, but it significantly improves resolution speed in larger applications.

---

## Table of Contents
- [Key Features](#key-features)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Core Concepts](#core-concepts)
  - [Binding](#binding)
  - [Module](#module)
  - [Scope](#scope)
  - [Automatic Resource Cleanup with Disposable](#automatic-resource-cleanup-with-disposable)
- [Dependency Resolution API](#dependency-resolution-api)
- [Using Annotations & Code Generation](#using-annotations--code-generation)
- [Advanced Features](#advanced-features)
  - [Hierarchical Subscopes](#hierarchical-subscopes)
  - [Logging](#logging)
  - [Circular Dependency Detection](#circular-dependency-detection)
  - [Performance Improvements](#performance-improvements)
- [Example Application](#example-application)
- [FAQ](#faq)
- [Documentation Links](#documentation-links)
- [Contributing](#contributing)
- [License](#license)

---

## Key Features
- Main Scope and Named Subscopes
- Named Instance Binding and Resolution
- Asynchronous and Synchronous Providers
- Providers Supporting Runtime Parameters
- Singleton Lifecycle Management
- Modular and Hierarchical Composition
- Null-safe Resolution (tryResolve/tryResolveAsync)
- Circular Dependency Detection (Local and Global)
- Comprehensive logging of dependency injection state and actions
- Automatic resource cleanup for all registered Disposable dependencies

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cherrypick: ^<latest_version>
```

Then run:

```shell
dart pub get
```
---

## Getting Started

Here is a minimal example that registers and resolves a dependency:

```dart
import 'package:cherrypick/cherrypick.dart';


class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toInstance(ApiClientMock());
    bind<String>().toProvide(() => "Hello, CherryPick!");
  }
}

final rootScope = CherryPick.openRootScope();
rootScope.installModules([AppModule()]);

final greeting = rootScope.resolve<String>();
print(greeting); // prints: Hello, CherryPick!

await CherryPick.closeRootScope();
```

---

## Core Concepts

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

// Recommended: Close the root scope and release all resources
await CherryPick.closeRootScope();

// Alternatively, you may manually call dispose on any scope you manage individually
// await rootScope.dispose();
```

---

### Automatic Resource Cleanup with Disposable

CherryPick can automatically clean up any dependency that implements the `Disposable` interface. This makes resource management (for controllers, streams, sockets, files, etc.) easy and reliable—especially when scopes or the app are shut down.

If you bind an object implementing `Disposable` as a singleton or provide it via the DI container, CherryPick will call its `dispose()` method when the scope is closed or cleaned up.

#### Key Points
- Supports both synchronous and asynchronous cleanup (dispose may return `void` or `Future`).
- All `Disposable` instances from the current scope and subscopes will be disposed in the correct order.
- Prevents resource leaks and enforces robust cleanup.
- No manual wiring needed once your class implements `Disposable`.

#### Minimal Sync Example
```dart
class CacheManager implements Disposable {
  void dispose() {
    cache.clear();
    print('CacheManager disposed!');
  }
}

final scope = CherryPick.openRootScope();
scope.installModules([
  Module((bind) => bind<CacheManager>().toProvide(() => CacheManager()).singleton()),
]);

// ...later
await CherryPick.closeRootScope(); // prints: CacheManager disposed!
```

#### Async Example
```dart
class MyServiceWithSocket implements Disposable {
  @override
  Future<void> dispose() async {
    await socket.close();
    print('Socket closed!');
  }
}

scope.installModules([
  Module((bind) => bind<MyServiceWithSocket>().toProvide(() => MyServiceWithSocket()).singleton()),
]);

await CherryPick.closeRootScope(); // awaits async disposal
```

**Tip:** Always call `await CherryPick.closeRootScope()` or `await scope.closeSubScope(key)` in your shutdown/teardown logic to ensure all resources are released automatically.

---

#### Working with Subscopes

```dart
// Open a named child scope (e.g., for a feature/module)
final subScope = rootScope.openSubScope('featureScope')
  ..installModules([FeatureModule()]);

// Resolve from subScope, with fallback to parents if missing
final dataBloc = await subScope.resolveAsync<DataBloc>();
```

---

## Using Annotations & Code Generation

CherryPick provides best-in-class developer ergonomics and type safety through **Dart annotations** and code generation. This lets you dramatically reduce boilerplate: simply annotate your classes, fields, and modules, run the code generator, and enjoy auto-wired dependency injection!

### How It Works

1. **Annotate** your services, providers, and fields using `cherrypick_annotations`.
2. **Generate** code using `cherrypick_generator` with `build_runner`.
3. **Use** generated modules and mixins for fully automated DI (dependency injection).

---

### Supported Annotations

| Annotation        | Target         | Description                                                                    |
|-------------------|---------------|--------------------------------------------------------------------------------|
| `@injectable()`   | class         | Enables automatic field injection for this class (mixin will be generated)      |
| `@inject()`       | field         | Field will be injected using DI (works with @injectable classes)                |
| `@module()`       | class         | Declares a DI module; its methods can provide services/providers                |
| `@provide`        | method        | Registers as a DI provider method (may have dependencies as parameters)         |
| `@instance`       | method/class  | Registers an instance (new object on each resolution, i.e. factory)             |
| `@singleton`      | method/class  | Registers as a singleton (one instance per scope)                               |
| `@named`          | field/param   | Use named instance (bind/resolve by name or apply to field/param)               |
| `@scope`          | field/param   | Inject or resolve from a specific named scope                                   |
| `@params`         | param         | Marks method parameter as filled by user-supplied runtime params at resolution  |

You can easily **combine** these annotations for advanced scenarios!

---

### Field Injection Example

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class ProfilePage with _\$ProfilePage {
  @inject()
  late final AuthService auth;

  @inject()
  @scope('profile')
  late final ProfileManager manager;

  @inject()
  @named('admin')
  late final UserService adminUserService;
}
```

- After running build_runner, the mixin `_ProfilePage` will be generated for field injection.
- Call `myProfilePage.injectFields();` or use the mixin's auto-inject feature, and all dependencies will be set up for you.

---

### Module and Provider Example

```dart
@module()
abstract class AppModule {
  @singleton
  AuthService provideAuth(Api api) => AuthService(api);

  @named('logging')
  @provide
  Future<Logger> provideLogger(@params Map<String, dynamic> args) async => ...;
}
```

- Mark class as `@module`, write provider methods.
- Use `@singleton`, `@named`, `@provide`, `@params` to control lifecycle, key names, and parameters.
- The generator will produce a class like `$AppModule` with the proper DI bindings.

---

### Usage Steps

1. **Add to your pubspec.yaml**:

   ```yaml
   dependencies:
     cherrypick: any
     cherrypick_annotations: any

   dev_dependencies:
     cherrypick_generator: any
     build_runner: any
   ```

2. **Annotate** your classes and modules as above.

3. **Run code generation:**

   ```shell
   dart run build_runner build --delete-conflicting-outputs
   # or in Flutter:
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Register modules and use auto-injection:**

   ```dart
   final scope = CherryPick.openRootScope()
     ..installModules([$AppModule()]);

   final profile = ProfilePage();
   profile.injectFields(); // injects all @inject fields
   ```

---

### Advanced: Parameters, Named Instances, and Scopes

- Use `@named` for key-based multi-implementation injection.
- Use `@scope` when dependencies live in a non-root scope.
- Use `@params` for runtime arguments passed during resolution.

---

### Troubleshooting & Tips

- After modifying DI-related code, always re-run `build_runner`.
- Do not manually edit `.g.dart` files—let the generator manage them.
- Errors in annotation usage (e.g., using `@singleton` on wrong target) are shown at build time.

---

### References

- [Full annotation reference (en)](doc/annotations_en.md)
- [cherrypick_annotations/README.md](../cherrypick_annotations/README.md)
- [cherrypick_generator/README.md](../cherrypick_generator/README.md)
- See the [`examples/postly`](../examples/postly) for a full working DI+annotations app.

---

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

## Logging

CherryPick supports centralized logging of all dependency injection (DI) events and errors. You can globally enable logs for your application or test environment with:

```dart
import 'package:cherrypick/cherrypick.dart';

void main() {
  // Set a global logger before any scopes are created
  CherryPick.setGlobalLogger(PrintLogger()); // or your custom logger

  final scope = CherryPick.openRootScope();
  // All DI actions and errors will now be logged!
}
```
- All dependency resolution, scope creation, module installation, and circular dependency errors will be sent to your logger (via info/error method).
- By default, logs are off (SilentLogger is used in production).

If you want fine-grained, test-local, or isolated logging, you can provide a logger directly to each scope:

```dart
final logger = MockLogger();
final scope = Scope(null, logger: logger); // works in tests for isolation
scope.installModules([...]);
```

## Features

- [x] Main Scope and Named Subscopes
- [x] Named Instance Binding and Resolution
- [x] Asynchronous and Synchronous Providers
- [x] Providers Supporting Runtime Parameters
- [x] Singleton Lifecycle Management
- [x] Modular and Hierarchical Composition
- [x] Null-safe Resolution (tryResolve/tryResolveAsync)
- [x] Circular Dependency Detection (Local and Global)
- [x] Comprehensive logging of dependency injection state and actions
- [x] Automatic resource cleanup for all registered Disposable dependencies

## Quick Guide: Circular Dependency Detection

CherryPick can detect circular dependencies in your DI configuration, helping you avoid infinite loops and hard-to-debug errors.

**How to use:**

### 1. Enable Cycle Detection for Development

**Local detection (within one scope):**
```dart
final scope = CherryPick.openSafeRootScope(); // Local detection enabled by default
// or, for an existing scope:
scope.enableCycleDetection();
```

**Global detection (across all scopes):**
```dart
CherryPick.enableGlobalCrossScopeCycleDetection();
final rootScope = CherryPick.openGlobalSafeRootScope();
```

### 2. Error Example

If you declare mutually dependent services:
```dart
class A { A(B b); }
class B { B(A a); }

scope.installModules([
  Module((bind) {
    bind<A>().to((s) => A(s.resolve<B>()));
    bind<B>().to((s) => B(s.resolve<A>()));
  }),
]);

scope.resolve<A>(); // Throws CircularDependencyException
```

### 3. Typical Usage Pattern

- **Always enable detection** in debug and test environments for maximum safety.
- **Disable detection** in production for performance (after code is tested).

```dart
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }
  runApp(MyApp());
}
```

### 4. Handling and Debugging Errors

On detection, `CircularDependencyException` is thrown with a readable dependency chain:
```dart
try {
  scope.resolve<MyService>();
} on CircularDependencyException catch (e) {
  print('Dependency chain: ${e.dependencyChain}');
}
```

**More details:** See [cycle_detection.en.md](doc/cycle_detection.en.md)


## FAQ

### Q: Do I need to use `await` with CherryPick.closeRootScope(), CherryPick.closeScope(), or scope.dispose() if I have no Disposable services?

**A:**  
Yes! Even if none of your services currently implement `Disposable`, always use `await` when closing scopes. If you later add resource cleanup (by implementing `dispose()`), CherryPick will handle it automatically without you needing to change your scope cleanup code. This ensures resource management is future-proof, robust, and covers all application scenarios.

## Documentation

- [Circular Dependency Detection (English)](doc/cycle_detection.en.md)
- [Обнаружение циклических зависимостей (Русский)](doc/cycle_detection.ru.md)

## Contributing

Contributions are welcome! Please open issues or submit pull requests on [GitHub](https://github.com/pese-git/cherrypick).

## License

Licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

---

**Important:** Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for specific language governing permissions and limitations under the License.

## Links

- [GitHub Repository](https://github.com/pese-git/cherrypick)
