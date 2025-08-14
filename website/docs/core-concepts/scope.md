---
sidebar_position: 3
---

# Scope

A **Scope** manages a tree of modules and dependency instances. Scopes can be nested into hierarchies (parent-child), supporting modular app composition and context-specific overrides.

You typically work with the root scope, but can also create named subscopes as needed.

## Example

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
