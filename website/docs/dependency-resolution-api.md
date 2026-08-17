---
sidebar_position: 4
---

# Dependency Resolution API

- `resolve<T>()` — Locates a dependency instance or throws if missing.
- `resolveAsync<T>()` — Async variant for dependencies requiring async binding.
- `tryResolve<T>()` — Returns `null` if no such binding is registered (sync).
- `tryResolveAsync<T>()` — Returns `null` async if no such binding is registered.

`null` from `tryResolve`/`tryResolveAsync` means "not registered", not "failed":
a binding that *is* registered but is asked for the wrong way still reports the
problem. Calling `tryResolve<T>()` on an async binding throws and points you to
`resolveAsync<T>()`, a parameterized provider invoked without `params` throws,
and errors raised by a provider propagate to the caller.

Supports:
- Synchronous and asynchronous dependencies
- Named dependencies
- Provider functions with and without runtime parameters
