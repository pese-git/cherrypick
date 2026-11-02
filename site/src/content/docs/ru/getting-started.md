---
title: "Быстрый старт"
description: Первый модуль, скоуп и разрешение зависимости — в Dart и во Flutter.
---

На этой странице — минимум, который нужен, чтобы связать приложение с помощью CherryPick.
Предполагается, что пакет `cherrypick` уже [установлен](/ru/installation/).

## 1. Опишите модуль

[Модуль](/ru/core-concepts/module/) объединяет [биндинги](/ru/core-concepts/binding/),
которые говорят CherryPick, как создавать каждую зависимость. Переопределите `builder` и
вызовите `bind<T>()` для каждого типа, который нужно предоставить:

```dart
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    // Готовый экземпляр.
    bind<ApiClient>().toInstance(ApiClientMock());

    // Фабрика, вызывается при каждом resolve.
    bind<String>().toProvide(() => "Hello, CherryPick!");
  }
}
```

## 2. Откройте скоуп и установите модуль

Корневой [скоуп](/ru/core-concepts/scope/) — вершина дерева зависимостей. Установите в него
модули один раз при запуске:

```dart
final rootScope = CherryPick.openRootScope();
rootScope.installModules([AppModule()]);
```

## 3. Получите зависимости

Запросите тип у скоупа. Для асинхронных биндингов используйте `resolveAsync`, а `tryResolve` —
когда отсутствие биндинга это нормальная ситуация, а не ошибка. Подробнее —
в [API разрешения зависимостей](/ru/dependency-resolution-api/).

```dart
final greeting = rootScope.resolve<String>();
print(greeting); // выведет: Hello, CherryPick!
```

## 4. Закройте скоуп

Когда приложение (или тест) завершается, закройте скоуп. Это освободит все
[`Disposable`](/ru/core-concepts/disposable/), которыми он владеет. Всегда используйте
`await` — даже если сейчас освобождать нечего:

```dart
await CherryPick.closeRootScope();
```

## Использование во Flutter

Добавьте `cherrypick_flutter` и оберните приложение в `CherryPickProvider`. Виджеты ниже
получают доступ к скоупам через `CherryPickProvider.of(context)`:

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  CherryPick.openRootScope().installModules([AppModule()]);
  runApp(const CherryPickProvider(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CherryPickProvider.of(context).openRootScope();
    return MaterialApp(home: Text(scope.resolve<String>()));
  }
}
```

`CherryPickProvider.of(context).openSubScope(scopeName: 'feature')` открывает
[подскоуп](/ru/advanced-features/hierarchical-subscopes/) для фичи или экрана.

## Что дальше

- [Аннотации](/ru/using-annotations/) — генерация модулей и внедрения полей вместо ручного кода.
- [Иерархические подскоупы](/ru/advanced-features/hierarchical-subscopes/) — изоляция фич и экранов.
- [Пример приложения](/ru/example-application/) — полноценное приложение на CherryPick.
- [Линтинг](/ru/linting/) — ловите типичные ошибки прямо в IDE.
