---
sidebar_position: 4
---

# Disposable

CherryPick может автоматически очищать любые зависимости, реализующие интерфейс `Disposable`. Это упрощает управление ресурсами (контроллеры, потоки, сокеты, файлы и др.) — особенно при закрытии скоупа или приложения.

Если вы регистрируете объект, реализующий `Disposable`, как синглтон или через DI-контейнер, CherryPick вызовет его метод `dispose()` при закрытии или очистке скоупа.

## Основные моменты
- Поддерживаются синхронная и асинхронная очистка (dispose может возвращать `void` или `Future`).
- Все объекты `Disposable` из текущего скоупа и подскоупов будут удалены в правильном порядке.
- Предотвращает утечки ресурсов и обеспечивает корректную очистку.
- Не нужно вручную связывать очистку — просто реализуйте интерфейс.

## Минимальный синхронный пример
```dart
class CacheManager implements Disposable {
  void dispose() {
    cache.clear();
    print('CacheManager удалён!');
  }
}

final scope = CherryPick.openRootScope();
scope.installModules([
  Module((bind) => bind<CacheManager>().toProvide(() => CacheManager()).singleton()),
]);

// ...спустя время
await CherryPick.closeRootScope(); // выведет: CacheManager удалён!
```

## Асинхронный пример
```dart
class MyServiceWithSocket implements Disposable {
  @override
  Future<void> dispose() async {
    await socket.close();
    print('Socket закрыт!');
  }
}

scope.installModules([
  Module((bind) => bind<MyServiceWithSocket>().toProvide(() => MyServiceWithSocket()).singleton()),
]);

await CherryPick.closeRootScope(); // дождётся завершения async очистки
```

**Совет:** Всегда вызывайте `await CherryPick.closeRootScope()` или `await scope.closeSubScope(key)` в вашем shutdown/teardown-коде для гарантированной очистки ресурсов.
