---
sidebar_position: 5
---

# Использование аннотаций и генерация кода

CherryPick предоставляет продвинутую эргономику и безопасный DI благодаря **аннотациям Dart** и генерации кода. Это позволяет избавить вас от рутины — просто аннотируйте классы, поля и модули, запускайте генератор и используйте полностью автосвязанный DI!

## Как это работает

1. **Аннотируйте** сервисы, провайдеры и поля с помощью `cherrypick_annotations`.
2. **Генерируйте** код с помощью `cherrypick_generator` и `build_runner`.
3. **Используйте** автосгенерированные модули и миксины для автоматического внедрения.

---

## Поддерживаемые аннотации

| Аннотация           | Target         | Описание                                                     |
|---------------------|---------------|--------------------------------------------------------------|
| `@injectable()`     | класс         | Включает автоподстановку полей (генерируется mixin)          |
| `@inject()`         | поле          | Автоподстановка через DI (работает с @injectable)            |
| `@module()`         | класс         | DI-модуль: методы — провайдеры и сервисы                     |
| `@provide`          | метод         | Регистрирует как DI-провайдер (можно с параметрами)           |
| `@instance`         | метод/класс   | Регистрирует новый экземпляр (на каждый resolve, factory)     |
| `@singleton`        | метод/класс   | Регистрация как синглтон (один экземпляр на скоуп)            |
| `@named`            | поле/параметр | Использование именованных экземпляров для внедрения/resolve   |
| `@scope`            | поле/параметр | Внедрение/resolve из другого (именованного) скоупа            |
| `@params`           | параметр      | Добавляет user-defined параметры во время resolve             |

---

## Пример Field Injection

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class ProfilePage with _\$ProfilePage {
  @inject()
  late final AuthService auth;

  @inject()
  @scope('profile')
  late final ProfileManager manager;

  @inject()
  @named('admin')
  late final UserService adminUserService;
}
```

- После запуска build_runner миксин `_ProfilePage` будет сгенерирован для внедрения.
- Вызовите `myProfilePage.injectFields();` чтобы все зависимости были внедрены автоматически.

## Пример модуля/провайдера

```dart
@module()
abstract class AppModule {
  @singleton
  AuthService provideAuth(Api api) => AuthService(api);

  @named('logging')
  @provide
  Future<Logger> provideLogger(@params Map<String, dynamic> args) async => ...;
}
```

---

## Шаги использования

1. Добавьте зависимости в `pubspec.yaml`.
2. Аннотируйте классы и модули.
3. Генерируйте код командой build_runner.
4. Регистрируйте модули и используйте автосвязь.

---

## Расширенные возможности

- Используйте `@named` для внедрения по ключу.
- Используйте `@scope` для внедрения из разных скоупов.
- Используйте `@params` для передачи runtime-параметров.

---

## Советы и FAQ

- После изменений в DI-коде запускайте build_runner заново.
- Не редактируйте `.g.dart` вручную.
- Ошибки некорректных аннотаций определяются автоматически.

---

## Ссылки

<!--
- [Подробнее про аннотации (en)](doc/annotations_en.md)
- [cherrypick_annotations/README.md](../cherrypick_annotations/README.md)
- [cherrypick_generator/README.md](../cherrypick_generator/README.md)
- Полный пример: [`examples/postly`](../examples/postly)
-->
