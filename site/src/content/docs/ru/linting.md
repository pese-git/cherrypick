---
title: Линтинг
description: Ловите неверное использование API CherryPick в IDE с помощью cherrypick_lint.
---

[`cherrypick_lint`](https://github.com/pese-git/cherrypick/tree/master/cherrypick_lint) — это плагин
[анализатора](https://pub.dev/packages/analysis_server_plugin), который подсвечивает неверное
использование API CherryPick в IDE и в `dart analyze` — без `build_runner`. На этой странице показано, что ловит каждое
правило (пример «плохо → хорошо»), и как подключить и настроить плагин.

> `cherrypick_generator` уже валидирует аннотации, но только при запуске кодогена.
> `cherrypick_lint` показывает те же классы ошибок — плюс несколько рантайм-ловушек, которые
> кодоген не видит, — прямо во время набора кода.

## Установка

Плагин не является зависимостью проекта — analysis server резолвит его сам.
Достаточно назвать его в top-level секции `plugins` файла `analysis_options.yaml`:

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint: ^1.0.0
```

Требуется Dart >=3.11 (Flutter >=3.41).

После этого перезапустите Dart Analysis Server (в VS Code: *Dart: Restart Analysis Server*) —
плагины анализатора подхватываются только при старте. Дальше правила видны и в IDE, и в
`dart analyze` / `flutter analyze`, так что отдельного шага в CI не нужно.

## await-rules

Пропущенный `await` на закрытии скоупа означает, что ресурсы могут быть ещё не освобождены к
следующей строке кода. Оборачивание вызова в `unawaited(...)` считается осознанным
fire-and-forget и не вызывает срабатывание этих правил.

### `avoid_unawaited_close_sub_scope`

```dart
// ❌ avoid_unawaited_close_sub_scope
scope.closeSubScope('feature');

// ✅
await scope.closeSubScope('feature');
```

### `avoid_unawaited_close_scope`

```dart
// ❌ avoid_unawaited_close_scope
CherryPick.closeScope(scopeName: 'feature');

// ✅
await CherryPick.closeScope(scopeName: 'feature');
```

### `avoid_unawaited_scope_dispose`

```dart
// ❌ avoid_unawaited_scope_dispose
scope.dispose();

// ✅
await scope.dispose();
```

## annotation-rules

Те же классы ошибок, на которых `AnnotationValidator` генератора бросает исключение во время
сборки — только теперь они видны в IDE ещё до запуска генератора.

### `module_must_be_abstract`

```dart
// ❌ module_must_be_abstract
@module()
class AppModule {
  @provide()
  Api api() => Api();
}

// ✅
@module()
abstract class AppModule {
  @provide()
  Api api() => Api();
}
```

### `module_method_missing_binding`

```dart
@module()
abstract class AppModule {
  // ❌ module_method_missing_binding — нет @provide/@instance
  Api api() => Api();

  // ✅
  @provide()
  Api api() => Api();
}
```

### `inject_field_must_be_late_final`

```dart
class ProfileScreen with _$ProfileScreen {
  // ❌ inject_field_must_be_late_final
  @inject()
  UserManager manager;

  // ✅
  @inject()
  late final UserManager manager;
}
```

### `named_value_must_not_be_empty`

```dart
// ❌ named_value_must_not_be_empty
@named('')
ApiClient mockApi() => MockApiClient();

// ✅
@named('mock')
ApiClient mockApi() => MockApiClient();
```

### `params_requires_provide`

```dart
@module()
abstract class FeatureModule {
  // ❌ params_requires_provide
  @params()
  UserManager createManager(Map<String, dynamic> args) => ...;

  // ✅
  @provide()
  @params()
  UserManager createManager(Map<String, dynamic> args) => ...;
}
```

## runtime-trap-rules

Ловушки, которые проявляются только в рантайме — `cherrypick_generator` их не видит, потому что
это не неверное использование аннотаций.

### `avoid_extends_silent_observer`

`Scope` содержит fast-path `if (_observer is SilentCherryPickObserver)`, поэтому наследник через
`extends` молча не получает **ни одного** из 14 колбэков наблюдателя.

```dart
// ❌ avoid_extends_silent_observer
class MyObserver extends SilentCherryPickObserver {}

// ✅
class MyObserver implements CherryPickObserver {
  // ... реализовать все 14 методов
}
```

### `avoid_redundant_singleton_on_instance` (info)

Согласно doc-комментарию `Binding.singleton()`, вызов после `.toInstance()`/`.toInstanceAsync()`
не имеет эффекта — переданное значение уже единственный константный экземпляр. `.singleton()`
осмыслен только после провайдера.

```dart
// ℹ️ avoid_redundant_singleton_on_instance
bind<Api>().toInstance(ApiMock()).singleton();

// ✅
bind<Api>().toInstance(ApiMock());
// либо, если действительно нужно ленивое создание единственного экземпляра:
bind<Api>().toProvide(() => ApiMock()).singleton();
```

### `avoid_singleton_on_provide_with_params` (info, без quick fix)

`.singleton()` после `.toProvideWithParams()`/`.toProvideAsyncWithParams()` превращает биндинг в
«master singleton»: параметры учитываются только при самом первом `resolve<T>(params: ...)`, все
последующие resolve возвращают тот же закэшированный экземпляр независимо от params. Иногда это
именно то, что нужно, поэтому у правила нет quick fix — только напоминание проверить намерение.

```dart
// ℹ️ avoid_singleton_on_provide_with_params
bind<Service>().toProvideWithParams((params) => Service(params)).singleton();

// нормально, если нужен новый экземпляр на каждый набор params — просто уберите .singleton()
bind<Service>().toProvideWithParams((params) => Service(params));
```

### `avoid_resolve_in_to_instance` (warning, без quick fix)

`.toInstance(...)`-биндинги внутри `Module.builder` применяются последовательно, поэтому вызов
`scope.resolve<T>()` (или `resolveAsync`/`tryResolve`/`tryResolveAsync`) для построения значения
может бросить `Can't resolve dependency ...`, если `T` регистрируется позже в том же builder'е.
Отложите резолв через `.toProvide(() => ...)` — он выполнится лениво, когда все соседние биндинги
уже зарегистрированы.

```dart
// ❌ avoid_resolve_in_to_instance
bind<int>().toInstance(scope.resolve<String>().length);

// ✅
bind<int>().toProvide(() => scope.resolve<String>().length);
```

### `avoid_precomputed_value_in_provide` (warning, без quick fix)

Замыкание провайдера существует для того, чтобы выполняться заново при каждом `resolve<T>()` —
значение должно строиться внутри него. Если замыкание просто возвращает переменную, построенную
ранее в том же методе, значение на самом деле создаётся один раз, в момент `Module.builder()`, и
каждый `resolve<T>()` молча возвращает тот же экземпляр — непреднамеренный псевдо-singleton в обход
явного `.singleton()`. На `.toInstance(...)` это не влияет: он всегда конструирует значение сразу
независимо от того, откуда оно взялось, поэтому предвычисление для него безопасно.

```dart
// ❌ avoid_precomputed_value_in_provide
final api = ApiMock();
bind<Api>().toProvide(() => api);

// ✅
bind<Api>().toProvide(() => ApiMock());
```

## Отключение правила

```yaml
# analysis_options.yaml
plugins:
  cherrypick_lint:
    version: ^1.0.0
    diagnostics:
      avoid_extends_silent_observer: false
```

Отдельную строку или файл можно исключить комментарием в форме `<плагин>/<правило>`:

```dart
// ignore: cherrypick_lint/avoid_unawaited_scope_dispose
scope.dispose();
```

## Ссылки

- [README cherrypick_lint](https://github.com/pese-git/cherrypick/blob/master/cherrypick_lint/README.md) — полная таблица правил, совместимость, контрибьютинг
- [Аннотации](/ru/using-annotations/)
- [Ссылки на документацию](/ru/documentation-links/)
