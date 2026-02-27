## ADDED Requirements

### Requirement: Сущности Flutter‑интеграции
Flutter‑интеграция MUST предоставлять `CherryPickProvider` как `InheritedWidget` для доступа к DI‑scope в дереве виджетов.

#### Scenario: Публичная сущность провайдера
- **WHEN** разработчик импортирует Flutter‑пакет
- **THEN** `CherryPickProvider` доступен и может быть помещен в дерево виджетов

### Requirement: Жизненный цикл провайдера
`CherryPickProvider` MUST быть статическим проводником к scope и не владеть их жизненным циклом.

#### Scenario: Stateless поведение
- **WHEN** `CherryPickProvider` пересоздается с тем же child
- **THEN** он не инициирует изменения DI‑состояния и не уведомляет зависимые виджеты

### Requirement: Доступ к root scope
Провайдер MUST предоставлять доступ к root scope через `openRootScope`.

#### Scenario: Открытие root scope
- **WHEN** вызывается `openRootScope`
- **THEN** возвращается root scope DI‑контейнера

### Requirement: Доступ к subscope
Провайдер MUST предоставлять доступ к subscope через `openSubScope` с именем и разделителем.

#### Scenario: Открытие named subscope
- **WHEN** вызывается `openSubScope` с именем
- **THEN** возвращается subscope с указанным именем

#### Scenario: Пустое имя scope
- **WHEN** вызывается `openSubScope` без имени
- **THEN** возвращается root scope

### Requirement: Доступ через BuildContext
`CherryPickProvider.of(context)` MUST возвращать провайдер из ближайшего ancestor.

#### Scenario: Успешный lookup
- **WHEN** вызов происходит внутри поддерева провайдера
- **THEN** возвращается экземпляр провайдера

#### Scenario: Ошибка lookup
- **WHEN** вызов происходит вне поддерева провайдера
- **THEN** происходит assertion‑ошибка

### Requirement: Ошибки и сообщения
При отсутствии провайдера в дереве MUST быть диагностируемая ошибка.

#### Scenario: Диагностика отсутствия провайдера
- **WHEN** `CherryPickProvider.of(context)` не находит провайдер
- **THEN** сообщение об ошибке указывает на отсутствие провайдера

### Requirement: Точки расширения
Flutter‑интеграция MUST позволять использовать собственные DI‑scope стратегии поверх `CherryPickProvider`.

#### Scenario: Кастомная организация scope
- **WHEN** приложение использует собственные правила создания subscope
- **THEN** провайдер остается совместимым и не ограничивает стратегию
