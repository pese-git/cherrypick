---
title: Dependency Resolution API
slug: v3/dependency-resolution-api
---

* `resolve<T>()` — Locates a dependency instance or throws if missing.
* `resolveAsync<T>()` — Async variant for dependencies requiring async binding.
* `tryResolve<T>()` — Returns `null` if not found (sync).
* `tryResolveAsync<T>()` — Returns `null` async if not found.

Supports:

* Synchronous and asynchronous dependencies
* Named dependencies
* Provider functions with and without runtime parameters
