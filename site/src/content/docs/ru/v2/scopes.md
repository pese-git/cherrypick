---
title: Скоупы
description: Именованные скоупы, иерархия зависимостей, открытие и закрытие подскоупов по пути.
---

Скоуп хранит дерево зависимостей. В большинстве случаев достаточно одного
корневого скоупа, но CherryPick 2.x поддерживает вложенные скоупы для изоляции и
организации зависимостей.

## Корневой и подскоупы

```dart
final rootScope = CherryPick.openRootScope();

final profileScope = rootScope.openSubScope('profile')
  ..installModules([ProfileModule()]);
```

- Подскоуп может переопределять зависимости родителя.
- При получении CherryPick сначала проверяет текущий скоуп, затем поднимается по
  иерархии к корню.

## Именованные скоупы по пути

`CherryPick.openScope` строит (или переиспользует) дерево скоупов из пути с
разделителем:

```dart
// Открывает 'profile' в корне, затем 'settings' внутри 'profile'
final subScope = CherryPick.openScope(scopeName: 'profile.settings');
```

Разделитель по умолчанию — точка (`.`), его можно изменить:

```dart
final subScope = CherryPick.openScope(
  scopeName: 'project>>dev>>api',
  separator: '>>',
);
```

Каждый уровень пути — отдельный скоуп, что удобно для локализации зависимостей:
например, `main.profile` — для фичи профиля, `main.profile.details` — для более
узкого контекста.

## Закрытие подскоупов

Закрывайте конкретный подскоуп по его пути. Закрытие скоупа верхнего уровня
удаляет и все его дочерние:

```dart
CherryPick.closeScope(scopeName: 'profile.settings');
```

## Сводка методов

| Метод | Описание |
| ----- | -------- |
| `openRootScope()` | Открыть или получить корневой скоуп |
| `closeRootScope()` | Закрыть корневой скоуп и удалить все зависимости |
| `openScope(scopeName:)` | Открыть скоуп(ы) по имени и иерархии (`'a.b.c'`) |
| `closeScope(scopeName:)` | Закрыть указанный скоуп или подскоуп |

```dart
// Открывает скоупы по иерархии: app -> module -> page
final scope = CherryPick.openScope(scopeName: 'app.module.page');

// Закрывает 'module' и все вложенные подскоупы
CherryPick.closeScope(scopeName: 'app.module');
```

:::tip
Используйте осмысленные имена и точечную нотацию для структурирования скоупов в
больших приложениях — это улучшает читаемость и управление зависимостями на
любом уровне.
:::
