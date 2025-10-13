---
marp: true
---

<!--
#backgroundImage: url('./doc/assets/image.png')
backgroundSize: cover
-->

# CherryPick 3.x  
### Быстро. Безопасно. Просто.

Современный DI-framework для Dart и Flutter  
Автор: Сергей Пеньковский

---
<!--
backgroundImage: none
-->

## Что такое CherryPick?

- Лёгкий и модульный framework для внедрения зависимостей (DI)
- Фокус: производительность, безопасность и лаконичный код
- Применяется во frontend, backend, CLI

---

## Эволюция: что нового в 3.x?

- Оптимизация скорости разрешения зависимостей
- Интеграция с Talker для наглядного логирования DI-событий
- Защита от циклических зависимостей на уровне ядра
- Полностью декларативное описание DI через аннотации и генерацию кода
- Автоматическая очистка ресурсов

---

## Быстро

* Мгновенное разрешение зависимостей

---

### Мгновенное разрешение зависимостей

- Операция resolve<T> теперь выполняется за O(1)
- Используется Map-индексация всех биндингов в каждом скоупе (в среднем ускорение в 10x+ на крупных графах)
- Производительность не зависит от размера приложения

---

## Безопасно

* Циклические зависимости больше не страшны
* Интеграция с Talker и расширенное логирование

---

### Циклические зависимости больше не страшны

- CherryPick 3.x автоматически выявляет циклы при разрешении зависимостей.
- Возможна проверка как внутри отдельного scope, так и во всём DI-графе (глобально).

---

#### Как включить проверку циклов


- Для защиты только внутри одного scope:

```dart
// 1. Для текущего scope (локальная проверка)
final scope = CherryPick.openRootScope();
scope.enableCycleDetection();
```

- Для защиты всей иерархии скоупов:

```dart
// 2. Для всей иерархии скоупов (глобальная проверка)
CherryPick.enableGlobalCycleDetection();
CherryPick.enableGlobalCrossScopeCycleDetection();
final rootScope = CherryPick.openRootScope();
```

---

#### Пример обработки ошибки

При обнаружении цикла будет выброшено исключение с подробной трассировкой:

```dart
try {
  scope.resolve<A>();
} on CircularDependencyException catch(e) {
  print(e.dependencyChain);
}
```

```bash
=== Circular Dependency Detection Example ===

1. Attempt to create a scope with circular dependencies:
❌ Circular dependency detected: CircularDependencyException: Circular dependency detected for UserService
Dependency chain: UserService -> OrderService -> UserService
```

---

### Интеграция с Talker и расширенное логирование

- Всё, что происходит в DI: регистрация, создание, удаление, ошибки ― теперь логируется!
- Достаточно подключить observer:

```dart
  final talker = Talker();
  final talkerLogger = TalkerCherryPickObserver(talker);
  CherryPick.setGlobalObserver(talkerLogger);
```
- Логи сразу видны в консоли, UI 

```bash
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ [info] | 9:41:33 89ms | [scope opened][CherryPick] scope_1757054493089_7072
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ [verbose] | 9:41:33 90ms | [diagnostic][CherryPick] Scope created: scope_1757054493089_7072 {type: Scope, name: scope_1757054493089_7072, description: scope created}
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

---

## Просто

* Декларативный DI
* Автоматическая очистка ресурсов

---

### Декларативный DI: аннотации и генерация кода

- Описывайте зависимости с помощью аннотаций
- Автоматически генерируется модуль DI и mixin для автоподстановки зависимостей

```dart
@module()
abstract class AppModule extends Module {
  @provide()
  @singleton()
  Api api() => Api();
  @provide()
  Repo repo(Api api) => Repo(api);
}
```

Регистрация модуля

```dart
final scope = openRootScope()
  ..installModules([$AppModule()]);
```

---

### Field injection: минимум кода — максимум удобства

```dart
@injectable()
class MyScreen  extends StatelessWidget with _$MyScreen {
  @inject()
  late final Repo repo;

  MyScreen() {
    _inject(this);
  }
}
```

- После генерации mixin и вызова `screen._inject()` — зависимости готовы
- Сильная типизация, никаких ручных вызовов resolve

---

## Автоматическая очистка ресурсов

Автоматическая очистка ресурсов (контроллеры, потоки, сокеты, файлы и др.).

Если вы регистрируете объект, реализующий Disposable, через DI-контейнер, CherryPick вызовет его метод dispose() при закрытии скоупа.

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

---

## Почему это удобно?  
### Сравнение с ручным DI

|| Аннотации  | Ручной DI   |
|:---|:-----------|:------------|
|Гибко|✅|✅|
|Кратко|✅|❌|
|Безопасно|✅|❌ (легко ошибиться)|

---

## CherryPick 3.x: ваш DI-фреймворк

- Быстрое разрешение зависимостей
- Гарантия безопасности и тестируемости
- Интеграция с логированием
- Максимально простой и декларативный код

---

<!--
#backgroundImage: url('./doc/assets/image.png')
backgroundSize: cover
-->

## Спасибо за внимание

---

## Вопросы?

- Try CherryPick - [https://pub.dev/packages/cherrypick](https://pub.dev/packages/cherrypick)
- Contributing — [https://github.com/pese-git/cherrypick](https://github.com/pese-git/cherrypick)
- Документация и примеры — [https://cherrypick-di.netlify.app](https://cherrypick-di.netlify.app/)
- Готов помочь — пишите, пробуйте, внедряйте!

