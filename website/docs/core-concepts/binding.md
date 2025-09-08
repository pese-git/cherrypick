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

#### Example

```dart
void builder(Scope scope) {
  // Provide a direct instance
  bind<String>().toInstance("Hello world");

  // Provide an async direct instance
  bind<String>().toInstanceAsync(Future.value("Hello world"));

  // Provide a lazy sync instance using a factory
  bind<String>().toProvide(() => "Hello world");

  // Provide a lazy async instance using a factory
  bind<String>().toProvideAsync(() async => "Hello async world");

  // Provide an instance with dynamic parameters (sync)
  bind<String>().toProvideWithParams((params) => "Hello $params");

  // Provide an instance with dynamic parameters (async)
  bind<String>().toProvideAsyncWithParams((params) async => "Hello $params");

  // Named instance for retrieval by name
  bind<String>().toProvide(() => "Hello world").withName("my_string");

  // Mark as singleton (only one instance within the scope)
  bind<String>().toProvide(() => "Hello world").singleton();
}
```

> ⚠️ **Important note about using `toInstance` in Module `builder`:**
>
> If you register a chain of dependencies via `toInstance` inside a Module's `builder`, **do not** call `scope.resolve<T>()` for types that are also being registered in the same builder — at the moment they are registered.
>
> CherryPick initializes all bindings in the builder sequentially. Dependencies registered earlier are not yet available to `resolve` within the same builder execution. Trying to resolve just-registered types will result in an error (`Can't resolve dependency ...`).
>
> **How to do it right:**  
> Manually construct the full dependency chain before calling `toInstance`:
>
> ```dart
> void builder(Scope scope) {
>   final a = A();
>   final b = B(a);
>   final c = C(b);
>   bind<A>().toInstance(a);
>   bind<B>().toInstance(b);
>   bind<C>().toInstance(c);
> }
> ```
>
> **Wrong:**
> ```dart
> void builder(Scope scope) {
>   bind<A>().toInstance(A());
>   // Error! At this point, A is not registered yet.
>   bind<B>().toInstance(B(scope.resolve<A>()));
> }
> ```
>
> **Wrong:**
> ```dart
> void builder(Scope scope) {
>   bind<A>().toProvide(() => A());
>   // Error! At this point, A is not registered yet.
>   bind<B>().toInstance(B(scope.resolve<A>()));
> }
> ```
>
> **Note:** This limitation applies **only** to `toInstance`. With `toProvide`/`toProvideAsync` and similar providers, you can safely use `scope.resolve<T>()` inside the builder.


  > ⚠️ **Special note regarding `.singleton()` with `toProvideWithParams()` / `toProvideAsyncWithParams()`:**
  >
  > If you declare a binding using `.toProvideWithParams(...)` (or its async variant) and then chain `.singleton()`, only the **very first** `resolve<T>(params: ...)` will use its parameters; every subsequent call (regardless of params) will return the same (cached) instance.
  >
  > **Example:**
  > ```dart
  > bind<Service>().toProvideWithParams((params) => Service(params)).singleton();
  > final a = scope.resolve<Service>(params: 1); // creates Service(1)
  > final b = scope.resolve<Service>(params: 2); // returns Service(1)
  > print(identical(a, b)); // true
  > ```
  >
  > Use this pattern only when you want a “master” singleton. If you expect a new instance per params, **do not** use `.singleton()` on parameterized providers.


> ℹ️ **Note about `.singleton()` and `.toInstance()`:**
>
> Calling `.singleton()` after `.toInstance()` does **not** change the binding’s behavior: the object passed with `toInstance()` is already a single, constant instance that will be always returned for every resolve.
>
> It is not necessary to use `.singleton()` with an existing object—this call has no effect.
>
> `.singleton()` is only meaningful with providers (such as `toProvide`/`toProvideAsync`), to ensure only one instance is created by the factory.
