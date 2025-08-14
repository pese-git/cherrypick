---
sidebar_position: 4
---

# Performance Improvements

> **Performance Note:**  
> **Starting from version 3.0.0**, CherryPick uses a Map-based resolver index for dependency lookup. This means calls to `resolve<T>()` and related methods are now O(1) operations, regardless of the number of modules or bindings in your scope. Previously, the library had to iterate over all modules and bindings to locate the requested dependency, which could impact performance as your project grew.
>
> This optimization is internal and does not change any library APIs or usage patterns, but it significantly improves resolution speed in larger applications.
