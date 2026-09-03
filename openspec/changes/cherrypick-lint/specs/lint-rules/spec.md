## ADDED Requirements

---

### Requirement: Структура и регистрация плагина

`cherrypick_lint` MUST реализовывать `PluginBase` из `custom_lint_builder` и регистрировать все правила через `getLintRules()` и `getFixes()`.

#### Scenario: Плагин подключается без build_runner
- **WHEN** пользователь добавляет `custom_lint` и `cherrypick_lint` в `dev_dependencies` и указывает `custom_lint` в `analyzer.plugins`
- **THEN** правила активируются в IDE без запуска `build_runner`

#### Scenario: Отключение отдельного правила
- **WHEN** пользователь добавляет правило в `custom_lint: rules:` с `enabled: false`
- **THEN** правило не репортит диагностику

---

### Requirement: avoid_unawaited_close_sub_scope

Вызов `Scope.closeSubScope(name)` без `await` MUST репортить предупреждение `avoid_unawaited_close_sub_scope`.

`closeSubScope` возвращает `Future<void>` и вызывает `dispose()` на дочернем скоупе и его `Disposable`-зависимостях. Пропущенный `await` означает, что ресурсы могут быть ещё не освобождены к следующей строке кода.

#### Scenario: Вызов без await
- **WHEN** в коде присутствует выражение `scope.closeSubScope(name)` и оно не обёрнуто в `await`
- **THEN** репортируется `avoid_unawaited_close_sub_scope` с severity `warning`
- **AND** предлагается quick fix «Add await»

#### Scenario: Корректный вызов с await
- **WHEN** выражение имеет вид `await scope.closeSubScope(name)`
- **THEN** диагностика не репортируется

#### Scenario: Корректная передача в unawaited()
- **WHEN** выражение имеет вид `unawaited(scope.closeSubScope(name))`
- **THEN** диагностика не репортируется (намеренный fire-and-forget явно выражен)

---

### Requirement: avoid_unawaited_close_scope

Вызов `CherryPick.closeScope(...)` без `await` MUST репортить предупреждение `avoid_unawaited_close_scope`.

#### Scenario: Статический вызов без await
- **WHEN** в коде присутствует выражение `CherryPick.closeScope(...)` без `await`
- **THEN** репортируется `avoid_unawaited_close_scope` с severity `warning`
- **AND** предлагается quick fix «Add await»

#### Scenario: Корректный вызов
- **WHEN** выражение имеет вид `await CherryPick.closeScope(...)`
- **THEN** диагностика не репортируется

---

### Requirement: avoid_unawaited_scope_dispose

Вызов `dispose()` на приёмнике типа `Scope` без `await` MUST репортить предупреждение `avoid_unawaited_scope_dispose`.

Правило проверяет только `Scope.dispose()` (статический тип приёмника должен быть `Scope`), чтобы не конфликтовать с синхронными `Disposable`-реализациями.

#### Scenario: dispose() без await на Scope
- **WHEN** в коде присутствует `scope.dispose()` где статический тип `scope` — `Scope`, и вызов не обёрнут в `await`
- **THEN** репортируется `avoid_unawaited_scope_dispose` с severity `warning`
- **AND** предлагается quick fix «Add await»

#### Scenario: dispose() на пользовательском Disposable
- **WHEN** вызывается `myService.dispose()` где `myService` не имеет статического типа `Scope`
- **THEN** диагностика не репортируется

#### Scenario: Корректный вызов
- **WHEN** выражение имеет вид `await scope.dispose()`
- **THEN** диагностика не репортируется

---

### Requirement: module_must_be_abstract

Класс, аннотированный `@module`, MUST быть объявлен как `abstract`.

Кодогенератор создаёт конкретный `final class $Foo extends Foo`; если `Foo` не `abstract` — генерируется код, который может не компилироваться или работать некорректно.

#### Scenario: @module на конкретном классе
- **WHEN** класс аннотирован `@module()` и не имеет модификатора `abstract`
- **THEN** репортируется `module_must_be_abstract` с severity `error`
- **AND** предлагается quick fix «Make class abstract»

#### Scenario: @module на abstract классе
- **WHEN** класс аннотирован `@module()` и объявлен как `abstract class`
- **THEN** диагностика не репортируется

---

### Requirement: module_method_missing_binding

Каждый публичный метод в классе, аннотированном `@module`, MUST иметь аннотацию `@provide` или `@instance`.

#### Scenario: Публичный метод без DI-аннотации
- **WHEN** `@module`-класс содержит публичный метод без `@provide` и без `@instance`
- **THEN** репортируется `module_method_missing_binding` с severity `error` на этом методе

#### Scenario: Приватный метод без DI-аннотации
- **WHEN** `@module`-класс содержит приватный метод (имя начинается с `_`)
- **THEN** диагностика не репортируется

#### Scenario: Корректный модуль
- **WHEN** все публичные методы `@module`-класса имеют `@provide` или `@instance`
- **THEN** диагностика не репортируется

---

### Requirement: inject_field_must_be_late_final

Поле, аннотированное `@inject`, MUST быть объявлено как `late final`.

Поле без `late` не может быть инициализировано после конструктора; поле без `final` допускает повторную запись после инъекции.

#### Scenario: @inject поле без late final
- **WHEN** поле аннотировано `@inject()` и не является одновременно `late` и `final`
- **THEN** репортируется `inject_field_must_be_late_final` с severity `error`
- **AND** предлагается quick fix «Add late final»

#### Scenario: Корректное поле
- **WHEN** поле аннотировано `@inject()` и объявлено как `late final`
- **THEN** диагностика не репортируется

---

### Requirement: named_value_must_not_be_empty

Аннотация `@named` MUST содержать непустую строку.

Пустая строка неотличима от отсутствия имени и ведёт к непредсказуемому резолву.

#### Scenario: @named с пустой строкой
- **WHEN** используется `@named('')` или `@named("")`
- **THEN** репортируется `named_value_must_not_be_empty` с severity `error`

#### Scenario: @named с непустой строкой
- **WHEN** используется `@named('api')` или любая непустая строка
- **THEN** диагностика не репортируется

---

### Requirement: params_requires_provide

Аннотация `@params` на методе MUST сопровождаться аннотацией `@provide`.

`@params` указывает генератору использовать `toProvideWithParams`; без `@provide` генерируемый код будет некорректным.

#### Scenario: @params без @provide
- **WHEN** метод в `@module`-классе аннотирован `@params()` без `@provide`
- **THEN** репортируется `params_requires_provide` с severity `error`

#### Scenario: @params вместе с @provide
- **WHEN** метод аннотирован `@provide` и `@params`
- **THEN** диагностика не репортируется

---

### Requirement: avoid_extends_silent_observer

Наследование от `SilentCherryPickObserver` через `extends` MUST репортить предупреждение.

`Scope` содержит fast-path: `if (_observer is SilentCherryPickObserver)` — наследник проходит эту проверку и не получает ни одного колбэка. Правильный способ — `implements CherryPickObserver` со всеми 14 методами.

#### Scenario: extends SilentCherryPickObserver
- **WHEN** класс объявлен как `class Foo extends SilentCherryPickObserver`
- **THEN** репортируется `avoid_extends_silent_observer` с severity `warning`
- **AND** предлагается quick fix «Replace with implements CherryPickObserver»

#### Scenario: implements CherryPickObserver
- **WHEN** класс объявлен как `class Foo implements CherryPickObserver`
- **THEN** диагностика не репортируется

---

### Requirement: avoid_experimental_scope_api

Вызовы `CherryPick.openScope` и `CherryPick.closeScope` MUST репортить информационное предупреждение.

Оба метода помечены `@experimental`. Для продакшн-кода предпочтительны `openSubScope`/`closeSubScope` напрямую через ссылку на `Scope`; при строгих линтах `@experimental`-вызовы дают предупреждение на каждой строке.

#### Scenario: Вызов CherryPick.openScope
- **WHEN** в коде присутствует `CherryPick.openScope(...)`
- **THEN** репортируется `avoid_experimental_scope_api` с severity `info`
- **AND** сообщение MUST содержать ссылку на альтернативу: `openSubScope`

#### Scenario: Вызов CherryPick.closeScope
- **WHEN** в коде присутствует `CherryPick.closeScope(...)`
- **THEN** репортируется `avoid_experimental_scope_api` с severity `info`
- **AND** сообщение MUST содержать ссылку на альтернативу: `closeSubScope`

#### Scenario: Прямое использование Scope
- **WHEN** используется `scope.openSubScope(name)` или `scope.closeSubScope(name)`
- **THEN** диагностика не репортируется
