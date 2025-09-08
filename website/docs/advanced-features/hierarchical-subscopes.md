---
sidebar_position: 1
---

# Hierarchical Subscopes

CherryPick supports a hierarchical structure of scopes, allowing you to create complex and modular dependency graphs for advanced application architectures. Each subscope inherits from its parent, enabling context-specific overrides while still allowing access to global or shared services.

## Key Points

- **Subscopes** are child scopes that can be opened from any existing scope (including the root).
- Dependencies registered in a subscope override those from parent scopes when resolved.
- If a dependency is not found in the current subscope, the resolution process automatically searches parent scopes up the hierarchy.
- Subscopes can have their own modules, lifetime, and disposable objects.
- You can nest subscopes to any depth, modeling features, flows, or components independently.

## Example

```dart
final rootScope = CherryPick.openRootScope();
rootScope.installModules([AppModule()]);

// Open a hierarchical subscope for a feature or page
final userFeatureScope = rootScope.openSubScope('userFeature');
userFeatureScope.installModules([UserFeatureModule()]);

// Dependencies defined in UserFeatureModule will take precedence
final userService = userFeatureScope.resolve<UserService>();

// If not found in the subscope, lookup continues in the parent (rootScope)
final sharedService = userFeatureScope.resolve<SharedService>();

// You can nest subscopes
final dialogScope = userFeatureScope.openSubScope('dialog');
dialogScope.installModules([DialogModule()]);
final dialogManager = dialogScope.resolve<DialogManager>();
```

## Use Cases

- Isolate feature modules, flows, or screens with their own dependencies.
- Provide and override services for specific navigation stacks or platform-specific branches.
- Manage the lifetime and disposal of groups of dependencies independently (e.g., per-user, per-session, per-component).

**Tip:** Always close subscopes when they are no longer needed to release resources and trigger cleanup of Disposable dependencies.
