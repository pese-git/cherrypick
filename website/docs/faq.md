---
sidebar_position: 7
---

# FAQ

### Q: Do I need to use `await` with CherryPick.closeRootScope(), CherryPick.closeScope(), or scope.dispose() if I have no Disposable services?

**A:**
Yes! Even if none of your services currently implement `Disposable`, always use `await` when closing scopes. If you later add resource cleanup (by implementing `dispose()`), CherryPick will handle it automatically without you needing to change your scope cleanup code. This ensures resource management is future-proof, robust, and covers all application scenarios.
