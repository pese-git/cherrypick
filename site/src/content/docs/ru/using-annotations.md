---
title: "Использование аннотаций и генерация кода"
---

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

Аннотации можно свободно **комбинировать** для сложных сценариев!

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
// app_module.dart
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

part 'app_module.module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @provide()
  @singleton()
  AuthService provideAuth(Api api) => AuthService(api);

  @provide()
  @named('logging')
  Future<Logger> provideLogger(@params() Map<String, dynamic> args) async => ...;
}
```

Три вещи в этом фрагменте не опциональны: part-директива (генератор — это
`PartBuilder`, без неё кодогенерация ничего не пишет), `extends Module`
(сгенерированный part переопределяет `builder()` и вызывает `bind<T>()`) и
`@provide` либо `@instance` на каждом методе — включая приватные и `static`.

- Пометьте класс как `@module` и опишите методы-провайдеры.
- Используйте `@singleton`, `@named`, `@provide`, `@params` для управления жизненным циклом, именами ключей и параметрами.
- Генератор создаст класс вида `$AppModule` с нужными DI-биндингами.

## Шаги использования

1. **Добавьте зависимости в `pubspec.yaml`:**

   ```yaml
   dependencies:
     cherrypick: any
     cherrypick_annotations: any

   dev_dependencies:
     cherrypick_generator: any
     build_runner: any
   ```

2. **Аннотируйте** классы и модули, как показано выше.

3. **Запустите генерацию кода:**

   ```shell
   dart run build_runner build --delete-conflicting-outputs
   # или во Flutter:
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Зарегистрируйте модули и используйте автовнедрение:**

   ```dart
   final scope = CherryPick.openRootScope()
     ..installModules([\$AppModule()]);

   final profile = ProfilePage();
   profile.injectFields(); // внедряет все поля с @inject
   ```

## Расширенные возможности: параметры, именованные экземпляры и скоупы

- Используйте `@named` для внедрения по ключу.
- Используйте `@scope` для внедрения из разных скоупов.
- Используйте `@params` для передачи runtime-параметров.

---

## Советы и FAQ

- После изменений в DI-коде запускайте build_runner заново.
- Не редактируйте `.g.dart` вручную.
- Ошибки в использовании аннотаций (например, `@singleton` не на том элементе) показываются во время сборки.
- Подключите [`cherrypick_lint`](https://github.com/pese-git/cherrypick/tree/master/cherrypick_lint), чтобы ловить многие из тех же ошибок прямо в IDE, ещё до запуска генератора — отсутствие part-директивы, `@module`-класс без `extends Module` или без `abstract`, метод без `@provide`/`@instance` и другие.

---

## Ссылки

- [README lint-плагина](https://github.com/pese-git/cherrypick/blob/master/cherrypick_lint/README.md) · [Гайд по линтингу](/ru/linting/)
