---
title: Интеграция с Flutter
description: Доступ к DI-скоупам из дерева виджетов через CherryPickProvider из cherrypick_flutter.
---

[`cherrypick_flutter`](https://pub.dev/packages/cherrypick_flutter) интегрирует
CherryPick DI с Flutter. Пакет предоставляет виджет `CherryPickProvider`, который
размещается в дереве виджетов и даёт доступ к корневому скоупу (и подскоупам) из
`BuildContext`.

## Возможности

- **Глобальный доступ к скоупу** — обращайтесь к корневому скоупу и подскоупам в
  любом месте дерева виджетов.
- **Интеграция с context** — используйте `CherryPickProvider.of(context)` внутри
  виджетов.

## Использование

Оберните приложение в `CherryPickProvider`:

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

Откройте подскоуп для конкретного экрана или фичи:

```dart
final subScope = CherryPickProvider.of(context)
    .openSubScope(scopeName: "profileFeature");
```
