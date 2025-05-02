# CherryPick Flutter

`cherrypick_flutter` is a Flutter library that allows access to the root scope through the context using `CherryPickProvider`. This package is designed to provide a simple and convenient way to interact with the root scope within the widget tree.

## Installation

Add `cherrypick_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  cherrypick_flutter: ^1.0.0
```

Then run `flutter pub get` to install the package.

## Usage

### Importing the Package

To start using `cherrypick_flutter`, import it into your Dart code:

```dart
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
```

### Providing State with `CherryPickProvider`

Use `CherryPickProvider` to wrap the part of the widget tree that requires access to the provided state.

```dart
import 'package:flutter/material.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';

void main() {
  runApp(
    CherryPickProvider(
      rootScope: yourRootScopeInstance,
      child: MyApp(),
    ),
  );
}
```

### Accessing State

To access the state provided by `CherryPickProvider`, use the `of` method. This is typically done in the `build` method of your widgets.

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).rootScope;

    return Text('Current state: ${rootScope.someStateValue}');
  }
}
```

### Updating State

The `CherryPickProvider` will automatically update its dependents when its state changes. Ensure to override the `updateShouldNotify` method to specify when notifications should occur, as shown in the provided implementation.

## Example

Here is a simple example showing how to implement and use the `CherryPickProvider`.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).rootScope;

    return MaterialApp.router(
      routerDelegate: rootScope.resolve<AppRouter>().delegate(),
      routeInformationParser:
          rootScope.resolve<AppRouter>().defaultRouteParser(),
    );
  }
}
```

## Contributing

We welcome contributions from the community. Please open issues and pull requests if you have ideas for improvements.

## License

This project is licensed under the Apache License 2.0.