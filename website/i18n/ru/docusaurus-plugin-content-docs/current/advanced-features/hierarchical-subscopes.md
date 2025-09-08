---
sidebar_position: 1
---

# Иерархические подскоупы

CherryPick поддерживает иерархическую структуру скоупов, что позволяет строить сложные и модульные графы зависимостей для профессиональных архитектур приложений. Каждый подскоуп наследует зависимости родителя и позволяет переопределять их локально.

## Основные моменты

- **Подскоупы** — дочерние скоупы, открываемые от любого существующего (в том числе root).
- Зависимости подскоупа перекрывают родительские при разрешении.
- Если зависимость не найдена в подскоупе, CherryPick ищет её выше по иерархии.
- Подскоупы могут иметь собственные модули, "жизненный цикл", Disposable-объекты.
- Можно делать вложенность любой глубины для фич, компонентов и т.д.

## Пример

```dart
final rootScope = CherryPick.openRootScope();
rootScope.installModules([AppModule()]);

// Открыть подскоуп для функции/страницы
final userFeatureScope = rootScope.openSubScope('userFeature');
userFeatureScope.installModules([UserFeatureModule()]);

// В userFeatureScope сперва ищет в своей области
final userService = userFeatureScope.resolve<UserService>();

// Если не нашлось — идёт в rootScope
final sharedService = userFeatureScope.resolve<SharedService>();

// Подскоупы можно вкладывать друг в друга сколь угодно глубоко
final dialogScope = userFeatureScope.openSubScope('dialog');
dialogScope.installModules([DialogModule()]);
final dialogManager = dialogScope.resolve<DialogManager>();
```

## Применение

- Модульная изоляция частей/экранов с собственными зависимостями
- Переопределение сервисов для конкретных сценариев/навигации
- Управление жизнью и освобождением ресурсов по группам

**Совет:** Всегда закрывайте подскоупы, когда они больше не нужны, чтобы освободить ресурсы.
