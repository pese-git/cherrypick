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

#### Scenario: Future передаётся вызывающему через return
- **WHEN** выражение имеет вид `return scope.closeSubScope(name);` (в блочном или arrow-теле функции)
- **THEN** диагностика не репортируется — future становится ответственностью вызывающей стороны

#### Scenario: Future сохраняется в переменную и awaited позже в том же блоке
- **WHEN** код имеет вид `final job = scope.closeSubScope(name); ... await job;` в пределах одного блока
- **THEN** диагностика не репортируется

#### Scenario: Future сохранён в переменную, но нигде не awaited
- **WHEN** код имеет вид `final job = scope.closeSubScope(name);` и `job` нигде в этом блоке не передаётся в `await`
- **THEN** диагностика репортируется как обычно

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

#### Scenario: Future передаётся вызывающему через return
- **WHEN** выражение имеет вид `return CherryPick.closeScope(...);` (в блочном или arrow-теле функции)
- **THEN** диагностика не репортируется

#### Scenario: Future сохраняется в переменную и awaited позже в том же блоке
- **WHEN** код имеет вид `final job = CherryPick.closeScope(...); ... await job;` в пределах одного блока
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

#### Scenario: Future передаётся вызывающему через return
- **WHEN** выражение имеет вид `return scope.dispose();` (в блочном или arrow-теле функции)
- **THEN** диагностика не репортируется

#### Scenario: Future сохраняется в переменную и awaited позже в том же блоке
- **WHEN** код имеет вид `final job = scope.dispose(); ... await job;` в пределах одного блока
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

### Requirement: avoid_redundant_singleton_on_instance

Вызов `.singleton()`, сцепленный сразу после `.toInstance(...)` или `.toInstanceAsync(...)` на `Binding`, MUST репортить информационное предупреждение.

Согласно doc-комментарию `Binding.singleton()`, такой вызов не имеет эффекта: значение, переданное в `toInstance`, уже является единственным константным экземпляром, который возвращается при каждом resolve. `.singleton()` осмысленен только после провайдера (`toProvide`, `toProvideAsync` и т. д.).

#### Scenario: .singleton() после .toInstance()
- **WHEN** в коде присутствует `bind<T>().toInstance(value).singleton()`
- **THEN** репортируется `avoid_redundant_singleton_on_instance` с severity `info`
- **AND** предлагается quick fix «Remove redundant .singleton()»

#### Scenario: .singleton() после .toInstanceAsync()
- **WHEN** в коде присутствует `bind<T>().toInstanceAsync(value).singleton()`
- **THEN** репортируется `avoid_redundant_singleton_on_instance` с severity `info`

#### Scenario: .singleton() после провайдера
- **WHEN** в коде присутствует `bind<T>().toProvide(() => value).singleton()` (или `toProvideAsync`)
- **THEN** диагностика не репортируется — `.singleton()` здесь осмыслен

#### Scenario: .toInstance() без .singleton()
- **WHEN** в коде присутствует `bind<T>().toInstance(value)` без последующего `.singleton()`
- **THEN** диагностика не репортируется

---

### Requirement: avoid_singleton_on_provide_with_params

Вызов `.singleton()`, сцепленный сразу после `.toProvideWithParams(...)` или `.toProvideAsyncWithParams(...)` на `Binding`, MUST репортить информационное предупреждение без quick fix.

Согласно doc-комментарию `Binding.singleton()`, в этом случае параметры учитываются только при самом первом `resolve<T>(params: ...)` — все последующие resolve, независимо от переданных params, возвращают тот же закэшированный экземпляр. Это иногда осознанный паттерн («master singleton»), поэтому правило только предупреждает, не предлагая автоматическое исправление.

#### Scenario: .singleton() после .toProvideWithParams()
- **WHEN** в коде присутствует `bind<T>().toProvideWithParams(fn).singleton()`
- **THEN** репортируется `avoid_singleton_on_provide_with_params` с severity `info`
- **AND** quick fix не предлагается

#### Scenario: .singleton() после .toProvideAsyncWithParams()
- **WHEN** в коде присутствует `bind<T>().toProvideAsyncWithParams(fn).singleton()`
- **THEN** репортируется `avoid_singleton_on_provide_with_params` с severity `info`

#### Scenario: .toProvideWithParams() без .singleton()
- **WHEN** в коде присутствует `bind<T>().toProvideWithParams(fn)` без последующего `.singleton()`
- **THEN** диагностика не репортируется — новый экземпляр на каждый набор params, как и ожидается

---

### Requirement: avoid_resolve_in_to_instance

Вызов `scope.resolve<T>()` (или `resolveAsync`/`tryResolve`/`tryResolveAsync`) на приёмнике типа `Scope`, найденный где-либо внутри аргументов `.toInstance(...)` или `.toInstanceAsync(...)` на `Binding`, MUST репортить предупреждение без quick fix.

`toInstance`-биндинги внутри `Module.builder` применяются последовательно, поэтому на момент их регистрации соседний биндинг, зарегистрированный позже в том же `builder`, ещё не резолвится — вызов бросает `Can't resolve dependency ...` в рантайме, если резолвимый тип регистрируется позже. Это задокументированное поведение (см. doc-комментарий `Binding.toInstance()`), а не гипотетический риск, поэтому severity `warning`. Правильный фикс (перенос вычисления в `.toProvide(() => ...)` или ручная сборка зависимости заранее) зависит от конкретного кода, поэтому quick fix не предлагается.

#### Scenario: resolve() внутри toInstance()
- **WHEN** в коде присутствует `bind<T>().toInstance(scope.resolve<U>())`
- **THEN** репортируется `avoid_resolve_in_to_instance` с severity `warning`
- **AND** quick fix не предлагается

#### Scenario: tryResolveAsync() внутри toInstanceAsync()
- **WHEN** в коде присутствует `bind<T>().toInstanceAsync(scope.tryResolveAsync<U>())`
- **THEN** репортируется `avoid_resolve_in_to_instance` с severity `warning`

#### Scenario: несколько resolve-вызовов в одном toInstance()
- **WHEN** аргумент `.toInstance(...)` содержит более одного вызова `resolve`/`resolveAsync`/`tryResolve`/`tryResolveAsync` на `Scope`
- **THEN** каждый такой вызов репортируется отдельно

#### Scenario: resolve() отложен через toProvide()
- **WHEN** в коде присутствует `bind<T>().toProvide(() => scope.resolve<U>())`
- **THEN** диагностика не репортируется — резолв выполнится лениво, когда соседние биндинги уже зарегистрированы

#### Scenario: toInstance() без resolve-вызовов
- **WHEN** в коде присутствует `bind<T>().toInstance(value)`, где `value` не содержит вызовов `resolve`/`resolveAsync`/`tryResolve`/`tryResolveAsync` на `Scope`
- **THEN** диагностика не репортируется

---

### Requirement: avoid_precomputed_value_in_provide

Вызов `.toProvide(...)`, `.toProvideAsync(...)`, `.toProvideWithParams(...)` или `.toProvideAsyncWithParams(...)` на `Binding`, чьё замыкание-аргумент целиком состоит из голой ссылки на локальную переменную (`() => x` или `{ return x; }`), MUST репортить предупреждение без quick fix. `.toInstance(...)`/`.toInstanceAsync(...)` этим правилом не проверяются.

Замыкание провайдера существует для того, чтобы выполняться заново при каждом `resolve<T>()` — значение должно строиться внутри него. Если замыкание лишь возвращает переменную, построенную вне его (например, в теле `Module.builder`), значение на самом деле конструируется один раз, в момент регистрации биндинга, и каждый `resolve<T>()` молча возвращает тот же экземпляр — непреднамеренный псевдо-singleton в обход явного `.singleton()`. Это отличается от `.toInstance(...)`, которое конструирует значение сразу в любом случае независимо от того, откуда оно взялось, — поэтому предвычисление для `toInstance()` не является ошибкой и не флагуется.

#### Scenario: toProvide() возвращает предвычисленную переменную
- **WHEN** в коде присутствует `final x = Foo(); bind<T>().toProvide(() => x);`
- **THEN** репортируется `avoid_precomputed_value_in_provide` с severity `warning`
- **AND** quick fix не предлагается

#### Scenario: toProvideAsync()/toProvideWithParams()/toProvideAsyncWithParams() возвращают предвычисленную переменную
- **WHEN** в коде присутствует `final x = Foo(); bind<T>().toProvideAsync(() async => x);` (аналогично для `toProvideWithParams`/`toProvideAsyncWithParams`)
- **THEN** репортируется `avoid_precomputed_value_in_provide` с severity `warning`

#### Scenario: конструктор вызывается внутри замыкания
- **WHEN** в коде присутствует `bind<T>().toProvide(() => Foo())` или `bind<T>().toProvide(() => Foo(capturedArg))`, где `capturedArg` — переменная, используемая как аргумент конструктора внутри замыкания
- **THEN** диагностика не репортируется — конструктор выполняется заново при каждом вызове замыкания

#### Scenario: toInstance() с предвычисленной переменной
- **WHEN** в коде присутствует `final x = Foo(); bind<T>().toInstance(x);`
- **THEN** диагностика не репортируется — `toInstance()` конструирует значение сразу в любом случае
