# Генерация DI-кода через аннотации (CherryPick)

CherryPick позволяет получить умный и полностью автоматизированный DI для Dart/Flutter на основе аннотаций и генерации кода.
Это убирает boilerplate — просто ставьте аннотации, запускайте генератор и используйте результат!

---

## 1. Как это работает?

Вы размечаете классы, поля и модули с помощью [cherrypick_annotations].  
[cherrypick_generator] анализирует их и создаёт код для регистрации зависимостей и подстановки полей или модулей.

Далее — запускайте:
```sh
dart run build_runner build --delete-conflicting-outputs
```
— и используйте сгенерированные файлы в проекте.

---

## 2. Поддерживаемые аннотации

| Аннотация          | Где применить    | Значение                                                   |
|--------------------|------------------|------------------------------------------------------------|
| `@injectable()`    | класс            | Включает автоподстановку полей, генерируется mixin         |
| `@inject()`        | поле             | Поле будет автоматически подставлено DI                    |
| `@scope()`         | поле/параметр    | Использовать определённый scope при разрешении             |
| `@named()`         | поле/параметр    | Именованный биндинг для интерфейсов/реализаций             |
| `@module()`        | класс            | Класс как DI-модуль (методы — провайдеры)                  |
| `@provide`         | метод            | Регистрирует тип через этот метод-провайдер                |
| `@instance`        | метод            | Регистрирует как прямой инстанс (singleton/factory, как есть)|
| `@singleton`       | метод/класс      | Синглтон (один экземпляр на scope)                         |
| `@params`          | параметр         | Пробрасывает параметры рантайм/конструктора в DI           |

Миксуйте аннотации для сложных сценариев!

---

## 3. Примеры использования

### A. Field Injection (рекомендуется для виджетов/классов)

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@injectable()
class MyWidget with _$MyWidget {
  @inject()
  late final AuthService auth;

  @inject()
  @scope('profile')
  late final ProfileManager profile;

  @inject()
  @named('special')
  late final ApiClient specialApi;
}
```
- После build_runner появится mixin _$MyWidget.
- Вызовите `MyWidget().injectFields();` (или соответствующий метод из mixin), чтобы заполнить поля.

### B. Binding через модуль (вариант для глобальных сервисов)

```dart
@module()
abstract class AppModule extends Module {
  @singleton
  AuthService provideAuth(Api api) => AuthService(api);

  @provide
  @named('logging')
  Future<Logger> provideLogger(@params Map<String, dynamic> args) async => ...
}
```
- Методы-провайдеры поддерживают async (Future<T>) и singleton.

---

## 4. Использование сгенерированного кода

1. В `pubspec.yaml`:

   ```yaml
   dependencies:
     cherrypick: any
     cherrypick_annotations: any

   dev_dependencies:
     cherrypick_generator: any
     build_runner: any
   ```

2. Импортируйте сгенерированные файлы (`app_module.module.cherrypick.g.dart`, `your_class.inject.cherrypick.g.dart`).

3. Регистрируйте модули так:

   ```dart
   final scope = openRootScope()
     ..installModules([$AppModule()]);
   ```

4. Для классов с автоподстановкой полей (field injection): используйте mixin и вызовите injector:

   ```dart
   final widget = MyWidget();
   widget.injectFields(); // или эквивалентный метод из mixin
   ```

5. Все зависимости готовы к использованию!

---

## 5. Расширенные возможности

- **Именованные и scope-зависимости:** используйте `@named`, `@scope` в полях/методах/resolve.
- **Async:** Провайдеры и поля могут быть Future<T> (resolveAsync).
- **Параметры рантайм:** через `@params` прямо к провайдеру: `resolve<T>(params: ...)`.
- **Комбинированная стратегия:** можно смешивать field injection и модульные провайдеры в одном проекте.

---

## 6. Советы и FAQ

- Проверьте аннотации, пути import и запускайте build_runner после каждого изменения DI/кода.
- Ошибки применения аннотаций появляются на этапе генерации.
- Никогда не редактируйте .g.dart файлы вручную.

---

## 7. Полезные ссылки

- [README по генератору](../cherrypick_generator/README.md)
- Пример интеграции: `examples/postly`
- [API Reference](../cherrypick/doc/api/)

---
