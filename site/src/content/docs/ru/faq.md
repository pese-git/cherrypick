---
title: "Часто задаваемые вопросы"
---

### В: Нужно ли использовать `await` с CherryPick.closeRootScope(), CherryPick.closeScope() или scope.dispose(), если у меня нет Disposable-сервисов?

**О:**  
Да! Даже если ваши сервисы сейчас не реализуют `Disposable`, всегда используйте `await` при закрытии скоупов. Если вы позже добавите очистку ресурсов (реализовав dispose()), CherryPick всё обработает автоматически и ваш код останется без изменений. Это гарантирует надежное освобождение ресурсов для любого сценария.

> 💡 [`cherrypick_lint`](https://github.com/pese-git/cherrypick/tree/master/cherrypick_lint) подсвечивает пропущенный `await` на закрытии скоупа прямо в IDE.
