## Purpose
Зафиксировать контракт Flutter-интеграции CherryPick через `CherryPickProvider` для доступа к DI scope из widget tree.

## Requirements

### Requirement: Flutter DI provider
Пакет `cherrypick_flutter` MUST экспортировать `CherryPickProvider` как `InheritedWidget` для доступа к DI scope в дереве Flutter-виджетов.

#### Scenario: Доступность провайдера
- **WHEN** разработчик импортирует `package:cherrypick_flutter/cherrypick_flutter.dart`
- **THEN** `CherryPickProvider` доступен для использования в widget tree

### Requirement: Доступ к scope через provider API
`CherryPickProvider` MUST предоставлять `openRootScope()` и `openSubScope(...)` как обертки над API `CherryPick`.

#### Scenario: Root scope из provider
- **WHEN** вызывается `CherryPickProvider.of(context).openRootScope()`
- **THEN** возвращается root scope от `CherryPick.openRootScope()`

#### Scenario: Sub-scope из provider
- **WHEN** вызывается `CherryPickProvider.of(context).openSubScope(scopeName: 'feature')`
- **THEN** возвращается scope от `CherryPick.openScope(scopeName: 'feature')`

### Requirement: Lookup через BuildContext
`CherryPickProvider.of(context)` MUST искать ближайший provider в дереве `InheritedWidget`.

#### Scenario: Успешный lookup
- **WHEN** вызов происходит внутри поддерева `CherryPickProvider`
- **THEN** возвращается экземпляр `CherryPickProvider`

#### Scenario: Отсутствующий provider
- **WHEN** вызов происходит вне поддерева `CherryPickProvider`
- **THEN** срабатывает assert в debug-режиме, а возврат невозможен из-за null-check

### Requirement: Stateless notifier semantics
`CherryPickProvider` MUST быть ненотифицирующим контейнером и MUST возвращать `false` из `updateShouldNotify`.

#### Scenario: Обновление provider
- **WHEN** Flutter сравнивает старый и новый `CherryPickProvider`
- **THEN** `updateShouldNotify` возвращает `false`
