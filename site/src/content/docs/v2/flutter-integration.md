---
title: Flutter Integration
description: Access DI scopes from the widget tree with cherrypick_flutter's CherryPickProvider.
---

[`cherrypick_flutter`](https://pub.dev/packages/cherrypick_flutter) integrates
CherryPick DI with Flutter. It provides a `CherryPickProvider` widget that sits in
the widget tree and gives access to the root scope (and subscopes) from
`BuildContext`.

## Features

- **Global scope access** — reach the root scope and subscopes anywhere in the
  widget tree.
- **Context integration** — use `CherryPickProvider.of(context)` inside widgets.

## Usage

Wrap your app with `CherryPickProvider`:

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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).openRootScope();

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            rootScope.resolve<AppService>().getStatus(),
          ),
        ),
      ),
    );
  }
}
```

Open a subscope for a specific screen or feature:

```dart
final subScope = CherryPickProvider.of(context)
    .openSubScope(scopeName: "profileFeature");
```
