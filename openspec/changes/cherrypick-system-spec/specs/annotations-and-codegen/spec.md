## ADDED Requirements

### Requirement: Сущности аннотаций
Пакет аннотаций MUST предоставлять аннотации `@module`, `@provide`, `@instance`, `@singleton`, `@named`, `@params`, `@inject`, `@injectable`, `@scope`.

#### Scenario: Наличие аннотаций
- **WHEN** разработчик импортирует пакет аннотаций
- **THEN** все перечисленные аннотации доступны для использования

### Requirement: Семантика module/provide/instance/singleton
Генератор MUST трактовать аннотации `@module`, `@provide`, `@instance`, `@singleton` как источники bindings и жизненного цикла.

#### Scenario: Генерация bindings для @module
- **WHEN** класс помечен `@module` и содержит методы с `@provide`
- **THEN** сгенерированный модуль регистрирует эти методы как DI‑bindings

#### Scenario: Singleton vs Instance
- **WHEN** метод помечен `@singleton`
- **THEN** binding создается как singleton
- **WHEN** метод помечен `@instance` или не имеет lifecycle‑аннотации
- **THEN** binding создается как factory/instance

#### Scenario: Обязательность provide/instance
- **WHEN** публичный метод в `@module` не помечен `@instance` или `@provide`
- **THEN** генератор завершает сборку с ошибкой валидации

### Requirement: Инъекция полей
Генератор MUST создавать миксин для класса с `@injectable` и инъектировать все поля, помеченные `@inject`.

#### Scenario: Инъекция полей без квалификаторов
- **WHEN** поле помечено `@inject`
- **THEN** миксин вызывает resolve для типа поля

#### Scenario: Инъекция с @named и @scope
- **WHEN** поле помечено `@inject` и `@named` или `@scope`
- **THEN** миксин использует соответствующий named/scope при резолве

### Requirement: Параметры выполнения
`@params` MUST обозначать runtime‑параметры, которые передаются при резолве.

#### Scenario: Параметризованный provider
- **WHEN** provider‑метод имеет параметр с `@params`
- **THEN** генерируется binding с параметрами и соответствующий API резолва

#### Scenario: Запрет @params с @instance
- **WHEN** `@params` используется вместе с `@instance`
- **THEN** генератор завершает сборку с ошибкой валидации

### Requirement: Поддержка async
Генератор MUST корректно обрабатывать `Future<T>` и асинхронные зависимости.

#### Scenario: Async provider
- **WHEN** provider возвращает `Future<T>`
- **THEN** генерируется async‑binding и используется `resolveAsync`

### Requirement: Обработка ошибок и валидация
Генератор MUST валидировать корректность применения аннотаций и сообщать об ошибках на стадии build.

#### Scenario: Некорректная цель аннотации
- **WHEN** аннотация применена к неподдерживаемому элементу
- **THEN** генератор завершает сборку с понятной ошибкой

#### Scenario: Взаимоисключающие аннотации
- **WHEN** метод помечен одновременно `@instance` и `@provide`
- **THEN** генератор завершает сборку с ошибкой валидации

#### Scenario: Требования к @named на provider-методе
- **WHEN** `@named` на provider-методе использует пустую строку или некорректный идентификатор
- **THEN** генератор завершает сборку с ошибкой валидации

#### Scenario: Пустой @named на inject-поле
- **WHEN** `@named('')` указан на поле с `@inject`
- **THEN** генератор трактует поле как безымянный резолв (без параметра `named`)

#### Scenario: Валидность @module
- **WHEN** класс с `@module` не имеет публичных методов
- **THEN** генератор завершает сборку с ошибкой валидации

#### Scenario: Валидность @injectable полей
- **WHEN** поле с `@inject` не является `final`
- **THEN** генератор завершает сборку с ошибкой валидации

### Requirement: Точки расширения
Система MUST позволять расширять DI‑контракт через новые модули/классы без изменения генератора, используя стандартные аннотации.

#### Scenario: Новый модуль
- **WHEN** разработчик добавляет новый класс `@module`
- **THEN** генератор автоматически включает его в DI‑регистрации
