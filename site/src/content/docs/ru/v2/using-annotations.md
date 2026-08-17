---
title: Аннотации
description: Декларативный DI через аннотации и кодогенерацию — модули, провайдеры и field injection.
---

CherryPick 2.x поддерживает DI через аннотации, что избавляет от ручного
связывания. Вы размечаете модули, провайдеры и поля; `cherrypick_generator`
обрабатывает их и генерирует код регистрации и внедрения.

Запускайте генератор при каждом изменении DI-кода:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Поддерживаемые аннотации

| Аннотация | Где | Назначение |
| --------- | --- | ---------- |
| `@module()` | класс | Помечает DI-модуль (методы становятся провайдерами) |
| `@provide()` | метод | Регистрирует тип через метод-провайдер |
| `@instance()` | метод | Регистрирует готовый экземпляр |
| `@singleton()` | метод / класс | Цель является singleton |
| `@named()` | метод / поле | Привязка или получение именованной реализации |
| `@params()` | параметр | Принимает runtime-параметры для провайдеров |
| `@injectable()` | класс | Включает field injection; генерируется миксин |
| `@inject()` | поле | Поле внедряется автоматически |
| `@scope()` | поле | Получать это поле из именованного скоупа |

## Связывание в модуле

```dart
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

@module()
abstract class AppModule extends Module {
  @singleton()
  @provide()
  ApiClient apiClient() => ApiClient();

  @provide()
  UserService userService(ApiClient api) => UserService(api);

  @singleton()
  @provide()
  @named('mock')
  ApiClient mockApiClient() => ApiClientMock();
}
```

Генератор создаёт класс `$AppModule`, реализующий `builder`:

```dart
class $AppModule extends AppModule {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().toProvide(() => apiClient()).singleton();
    bind<UserService>()
        .toProvide(() => userService(currentScope.resolve<ApiClient>()));
    bind<ApiClient>()
        .toProvide(() => mockApiClient())
        .withName('mock')
        .singleton();
  }
}
```

## Field injection

Разметьте класс аннотацией `@injectable()`, а его поля — `@inject()`. Генератор
создаёт миксин, который получает и присваивает поля.

```dart
@injectable()
class ProfileBloc with _$ProfileBloc {
  @inject()
  late final AuthService auth;

  @inject()
  @named('admin')
  late final UserService adminUser;

  ProfileBloc() {
    _inject(this); // сгенерированный инжектор
  }
}
```

Сгенерированный миксин (иллюстративно):

```dart
mixin _$ProfileBloc {
  void _inject(ProfileBloc instance) {
    instance.auth = CherryPick.openRootScope().resolve<AuthService>();
    instance.adminUser =
        CherryPick.openRootScope().resolve<UserService>(named: 'admin');
  }
}
```

## Подключение

```dart
void main() {
  final scope = CherryPick.openRootScope()
    ..installModules([
      $AppModule(),
    ]);

  final bloc = ProfileBloc(); // поля внедрены в конструкторе
  runApp(MyApp(bloc: bloc));
}
```

## Примечания

- Провайдеры могут возвращать `Future<T>` (async) или обычное значение (sync).
- Комбинируйте `@named` и `@scope` на полях/методах для именованных реализаций
  или именованных скоупов.
- Не редактируйте сгенерированные `.g.dart` файлы вручную.
- Неверное использование аннотаций сообщается на этапе сборки, а не в рантайме.
