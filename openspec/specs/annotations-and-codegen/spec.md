## Purpose
Зафиксировать контракт аннотаций и генератора CherryPick для module codegen и field injection, включая валидацию и синхронно-асинхронные сценарии.

## Requirements

### Requirement: Публичные аннотации
Пакет `cherrypick_annotations` MUST экспортировать аннотации `@module`, `@provide`, `@instance`, `@singleton`, `@named`, `@params`, `@injectable`, `@inject`, `@scope`.

#### Scenario: Импорт пакета аннотаций
- **WHEN** разработчик импортирует `package:cherrypick_annotations/cherrypick_annotations.dart`
- **THEN** все перечисленные аннотации доступны в коде

### Requirement: Генерация модулей из `@module`
`cherrypick_generator` MUST генерировать класс `$<ModuleName> extends <ModuleName>` и метод `builder(Scope currentScope)` для классов с `@module`.

#### Scenario: Успешная генерация module
- **WHEN** класс помечен `@module` и содержит валидные методы провайдеров
- **THEN** генерируется `.module.cherrypick.g.dart` с регистрацией bind-ов

#### Scenario: Невалидная цель `@module`
- **WHEN** `@module` применен не к классу
- **THEN** генерация завершается ошибкой

### Requirement: Контракт provider-методов модуля
Каждый не-абстрактный метод модуля, участвующий в генерации bind-ов, MUST быть помечен ровно одной из аннотаций `@instance` или `@provide`.

#### Scenario: Одновременные `@instance` и `@provide`
- **WHEN** метод содержит обе аннотации
- **THEN** генерация завершается ошибкой валидации

#### Scenario: Отсутствие `@instance` и `@provide`
- **WHEN** метод не содержит ни одной из аннотаций
- **THEN** генерация завершается ошибкой валидации

### Requirement: Семантика lifecycle и qualifiers
Генератор MUST отражать `@singleton` и `@named` в генерируемом bind-коде.

#### Scenario: Singleton
- **WHEN** метод помечен `@singleton`
- **THEN** генерируется `.singleton()` для соответствующего binding

#### Scenario: Named
- **WHEN** метод помечен `@named('key')`
- **THEN** генерируется `.withName('key')`

### Requirement: Валидация `@named`
Значение `@named` MUST быть непустым и соответствовать идентификаторному шаблону `[a-zA-Z_][a-zA-Z0-9_]*`.

#### Scenario: Пустой `@named`
- **WHEN** передана пустая строка
- **THEN** генерация завершается ошибкой валидации

#### Scenario: Некорректный `@named`
- **WHEN** значение содержит недопустимые символы
- **THEN** генерация завершается ошибкой валидации

### Requirement: Runtime params
Параметры с `@params` MUST генерировать `toProvideWithParams`/`toProvideAsyncWithParams` и MUST NOT использоваться совместно с `@instance`.

#### Scenario: Параметризованный provider
- **WHEN** `@provide`-метод содержит параметр с `@params`
- **THEN** генерируется binding с runtime-аргументом

#### Scenario: `@params` с `@instance`
- **WHEN** `@instance`-метод содержит параметр с `@params`
- **THEN** генерация завершается ошибкой валидации

### Requirement: Async codegen
Генератор MUST различать sync/async return type provider-методов.

#### Scenario: Async return type
- **WHEN** метод возвращает `Future<T>`
- **THEN** генерируется async-вариант bind-а

### Requirement: Field injection из `@injectable`
Для классов с `@injectable` генератор MUST создавать mixin `_$ClassName` с методом `_inject(instance)`, который заполняет поля `@inject`.

#### Scenario: Простая инъекция поля
- **WHEN** поле помечено `@inject` и имеет тип `T`
- **THEN** в `_inject` генерируется `resolve<T>()`

#### Scenario: Nullable поле
- **WHEN** поле имеет nullable-тип
- **THEN** в `_inject` генерируется `tryResolve*`

#### Scenario: Scope и named qualifiers в поле
- **WHEN** поле `@inject` дополнено `@scope` и/или `@named`
- **THEN** в `_inject` используется соответствующий `openScope(...)` и `named: ...`
