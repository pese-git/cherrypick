---
sidebar_position: 4
---

# Disposable

CherryPick может автоматически очищать любые зависимости, реализующие интерфейс `Disposable`. Это упрощает управление ресурсами (контроллеры, потоки, сокеты, файлы и др.) — особенно при закрытии скоупа или приложения.

Если вы регистрируете объект, реализующий `Disposable`, как синглтон или через DI-контейнер, CherryPick вызовет его метод `dispose()` при закрытии или очистке скоупа.

## Основные моменты
- Поддерживаются синхронная и асинхронная очистка (dispose может возвращать `void` или `Future`).
- Все объекты `Disposable` из текущего скоупа и подскоупов будут удалены в правильном порядке.
- Объектом владеет тот скоуп, в котором **объявлен его биндинг** — см. [Владение](#владение-какой-скоуп-что-освобождает).
- Предотвращает утечки ресурсов и обеспечивает корректную очистку.
- Не нужно вручную связывать очистку — просто реализуйте интерфейс.

## Владение: какой скоуп что освобождает

`Disposable` освобождает тот скоуп, в котором **объявлен его биндинг**, а не тот,
у которого вы вызвали `resolve()`.

Подскоуп обращается к родителю за всем, что не объявлено в нём самом, поэтому
резолв родительской зависимости через подскоуп **не** передаёт владение:

```dart
final root = CherryPick.openRootScope()
  ..installModules([AppModule()]);        // Database объявлена здесь
final feature = root.openSubScope('feature');

final db = feature.resolve<Database>();   // резолв через подскоуп...
await root.closeSubScope('feature');      // ...но dispose здесь НЕ вызывается

db.query('...');                          // объект жив — им владеет root

await CherryPick.closeRootScope();        // вот здесь произойдёт dispose
```

**Что важно учитывать:** если биндинг объявлен в долгоживущем скоупе и **не**
помечен `.singleton()`, каждый экземпляр, созданный им для короткоживущих
подскоупов, копится в этом долгоживущем скоупе до его закрытия. Объявляйте
биндинг в том скоупе, чьему времени жизни соответствует ресурс:

```dart
// Копится до закрытия root: по соединению на экран, все принадлежат root.
// root: bind<Connection>().toProvide(() => Connection());

// Освобождается вместе с экраном: биндинг живёт там, где нужен ресурс.
screenScope.installModules([ConnectionModule()]);
```

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

**Совет:** Всегда вызывайте `await CherryPick.closeRootScope()` или `await scope.closeSubScope(key)` в вашем shutdown/teardown-коде для гарантированной очистки ресурсов. Закрытие подскоупа освобождает то, что объявлено в нём самом; зависимости, унаследованные от родителя, освобождаются вместе с родителем.
