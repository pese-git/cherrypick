## Purpose
Зафиксировать контракт адаптера `TalkerCherryPickObserver`, который проксирует события DI-контейнера CherryPick в Talker.

## Requirements

### Requirement: Observer-адаптер для Talker
Пакет `talker_cherrypick_logger` MUST экспортировать `TalkerCherryPickObserver`, реализующий `CherryPickObserver`.

#### Scenario: Публичный экспорт
- **WHEN** разработчик импортирует `package:talker_cherrypick_logger/talker_cherrypick_logger.dart`
- **THEN** `TalkerCherryPickObserver` доступен для подключения к CherryPick

### Requirement: Маршрутизация событий в Talker
Адаптер MUST проксировать события `CherryPickObserver` в методы `Talker`.

#### Scenario: Стандартные DI события
- **WHEN** приходят события регистрации, запроса, создания, удаления, модулей, scope и cache
- **THEN** адаптер логирует их через `talker.info(...)`

#### Scenario: Диагностика
- **WHEN** приходит `onDiagnostic`
- **THEN** адаптер логирует через `talker.verbose(...)`

#### Scenario: Предупреждения и циклы
- **WHEN** приходят `onWarning` или `onCycleDetected`
- **THEN** адаптер логирует через `talker.warning(...)`

#### Scenario: Ошибки
- **WHEN** приходит `onError(message, error, stackTrace)`
- **THEN** адаптер вызывает `talker.handle(error ?? fallback, stackTrace, prefixedMessage)`

### Requirement: Ненавязчивость адаптера
Адаптер MUST не изменять DI-поведение контейнера и использоваться только как observer.

#### Scenario: Работа контейнера с адаптером
- **WHEN** `TalkerCherryPickObserver` подключен к CherryPick
- **THEN** логирование добавляется, но семантика резолва/кэширования/жизненного цикла DI остается прежней

### Requirement: Поведение при ошибках Talker
Адаптер MUST не перехватывать исключения, возникающие внутри вызовов `Talker`.

#### Scenario: Исключение на логировании
- **WHEN** метод `Talker` выбрасывает исключение
- **THEN** исключение пробрасывается вызывающему коду
