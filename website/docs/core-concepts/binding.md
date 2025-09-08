---
sidebar_position: 1
---

# Binding

A **Binding** acts as a configuration for how to create or provide a particular dependency. Bindings support:

* Direct instance assignment (`toInstance()`, `toInstanceAsync()`)
* Lazy providers (sync/async functions)
* Provider functions supporting dynamic parameters
* Named instances for resolving by string key
* Optional singleton lifecycle

## Example

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
