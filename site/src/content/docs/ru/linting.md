---
title: Линтинг
description: Ловите неверное использование API CherryPick в IDE с помощью cherrypick_lint.
---

[`cherrypick_lint`](https://github.com/pese-git/cherrypick/tree/master/cherrypick_lint) — это плагин
[`custom_lint`](https://pub.dev/packages/custom_lint), который подсвечивает неверное использование
API CherryPick прямо в IDE — без `build_runner`. На этой странице показано, что ловит каждое
правило (пример «плохо → хорошо»), и как подключить и настроить плагин.

> `cherrypick_generator` уже валидирует аннотации, но только при запуске кодогена.
> `cherrypick_lint` показывает те же классы ошибок — плюс несколько рантайм-ловушек, которые
> кодоген не видит, — прямо во время набора кода.

## Установка

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.1
  cherrypick_lint: ^0.1.0
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

После добавления плагина перезапустите analysis server вашей IDE (или выполните
`dart run custom_lint`). `dart analyze` никогда не показывает диагностики `custom_lint` —
используйте `dart run custom_lint`, чтобы увидеть их из командной строки (например, в CI).

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

## Отключение правила

```yaml
# analysis_options.yaml
custom_lint:
  rules:
    - avoid_extends_silent_observer: false
```

## Ссылки

- [README cherrypick_lint](https://github.com/pese-git/cherrypick/blob/master/cherrypick_lint/README.md) — полная таблица правил, совместимость, контрибьютинг
- [Аннотации](/ru/using-annotations/)
- [Ссылки на документацию](/ru/documentation-links/)
