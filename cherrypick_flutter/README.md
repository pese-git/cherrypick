# CherryPick Flutter

`cherrypick_flutter` offers a Flutter integration to access and manage dependency injection scopes using the `CherryPickProvider`. This setup facilitates accessing the root scope directly from the widget tree, providing a straightforward mechanism for dependences management within Flutter applications.

## Installation

Add `cherrypick_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  cherrypick_flutter: ^1.0.0
```

Run `flutter pub get` to install the package dependencies.

## Usage

### Importing the Package

To begin using `cherrypick_flutter`, import it within your Dart file:

```dart
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
```

### Providing State with `CherryPickProvider`

Use `CherryPickProvider` to encase the widget tree section that requires access to the root or specific subscopes:

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
```

Note: The current implementation of `CherryPickProvider` does not directly pass a `rootScope`. Instead, it utilizes its methods to open root and sub-scopes internally.

### Accessing State

Access the state provided by `CherryPickProvider` within widget `build` methods using the `of` method:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CherryPickProvider cherryPick = CherryPickProvider.of(context);
    final rootScope = cherryPick.openRootScope();

    // Use the rootScope or open a subScope as needed
    final subScope = cherryPick.openSubScope(scopeName: "exampleScope");

    return Text('Scope accessed!');
  }
}
```

### Updating State

The `CherryPickProvider` setup internally manages state updates. Ensure the `updateShouldNotify` method accurately reflects when the dependents should receive updates. In the provided implementation, it currently does not notify updates automatically.

## Example

Here is an example illustrating how to implement and utilize `CherryPickProvider` within a Flutter application:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).openRootScope();

    return MaterialApp.router(
      routerDelegate: rootScope.resolve<AppRouter>().delegate(),
      routeInformationParser:
          rootScope.resolve<AppRouter>().defaultRouteParser(),
    );
  }
}
```

In this example, `CherryPickProvider` accesses and resolves dependencies using root scope and potentially sub-scopes configured by the application.

## Contributing

Contributions to improve this library are welcome. Feel free to open issues and submit pull requests on the repository.

## License

This project is licensed under the Apache License 2.0. A copy of the license can be obtained at [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).