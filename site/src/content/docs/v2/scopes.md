---
title: Scopes
description: Named scopes, dependency hierarchy, and opening/closing subscopes by path.
---

A scope holds a dependency tree. For most cases a single root scope is enough,
but CherryPick 2.x supports nested scopes for isolating and organizing
dependencies.

## Root and subscopes

```dart
final rootScope = CherryPick.openRootScope();

final profileScope = rootScope.openSubScope('profile')
  ..installModules([ProfileModule()]);
```

- A subscope can override parent dependencies.
- When resolving, CherryPick checks the current scope first, then walks up the
  hierarchy toward the root.

## Named scopes by path

`CherryPick.openScope` builds (or reuses) a tree of scopes from a
separator-delimited path:

```dart
// Opens 'profile' in root, then 'settings' inside 'profile'
final subScope = CherryPick.openScope(scopeName: 'profile.settings');
```

The default separator is a dot (`.`) and can be changed:

```dart
final subScope = CherryPick.openScope(
  scopeName: 'project>>dev>>api',
  separator: '>>',
);
```

Each level of the path is a separate scope, which is convenient for localizing
dependencies — e.g. `main.profile` for the profile feature, and
`main.profile.details` for a narrower context.

## Closing subscopes

Close a specific subscope by its path. Closing a top-level scope also removes all
of its children:

```dart
CherryPick.closeScope(scopeName: 'profile.settings');
```

## Methods summary

| Method | Description |
| ------ | ----------- |
| `openRootScope()` | Open or get the root scope |
| `closeRootScope()` | Close the root scope and remove all dependencies |
| `openScope(scopeName:)` | Open scope(s) by name and hierarchy (`'a.b.c'`) |
| `closeScope(scopeName:)` | Close the specified scope or subscope |

```dart
// Opens scopes by hierarchy: app -> module -> page
final scope = CherryPick.openScope(scopeName: 'app.module.page');

// Closes 'module' and all nested subscopes
CherryPick.closeScope(scopeName: 'app.module');
```

:::tip
Use meaningful names and dot notation to structure scopes in large apps — it
improves readability and dependency management at every level.
:::
