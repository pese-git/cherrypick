## Purpose
Зафиксировать фактический контракт DI-ядра CherryPick: публичный API, семантику scope/binding/resolution, lifecycle и диагностические механизмы.

## Requirements

### Requirement: Публичный DI API
Пакет `cherrypick` MUST экспортировать ключевые типы DI-ядра: `CherryPick`, `Scope`, `Module`, `Binding`, `BindingResolver`, `Disposable`, `CherryPickObserver`, `CycleDetector`, `GlobalCycleDetector`.

#### Scenario: Импорт публичного API
- **WHEN** пользователь импортирует `package:cherrypick/cherrypick.dart`
- **THEN** перечисленные сущности доступны для использования

### Requirement: Root scope и иерархия scope
`CherryPick` MUST предоставлять root scope и иерархические sub-scope по строковому пути.

#### Scenario: Root scope singleton
- **WHEN** `CherryPick.openRootScope()` вызывается несколько раз без `closeRootScope()`
- **THEN** возвращается один и тот же экземпляр root scope

#### Scenario: Иерархический путь scope
- **WHEN** вызывается `CherryPick.openScope(scopeName: 'a.b.c', separator: '.')`
- **THEN** создается/возвращается цепочка sub-scope `a -> b -> c`

#### Scenario: Пустое имя scope
- **WHEN** `CherryPick.openScope(scopeName: '')` или `CherryPickProvider.openSubScope(scopeName: '')` вызывается с пустым именем
- **THEN** возвращается root scope

### Requirement: Установка и удаление модулей
`Scope` MUST поддерживать `installModules` и `dropModules`, а bindings установленных модулей MUST участвовать в резолве сразу после установки.

#### Scenario: Установка модулей
- **WHEN** модуль установлен через `installModules`
- **THEN** его bindings доступны через `resolve*`/`tryResolve*`

#### Scenario: Сброс модулей
- **WHEN** вызывается `dropModules()`
- **THEN** bindings из удаленных модулей перестают резолвиться в этом scope

### Requirement: Типы bindings и singleton
`Binding` MUST поддерживать instance, provider, provider-with-params, named binding и singleton-кэширование.

#### Scenario: Named binding
- **WHEN** зарегистрированы bindings одного типа с разными именами
- **THEN** `resolve<T>(named: ...)` возвращает соответствующую реализацию

#### Scenario: Singleton для provider
- **WHEN** binding через `toProvide*` помечен `.singleton()`
- **THEN** экземпляр кэшируется и переиспользуется в рамках scope

#### Scenario: Singleton с params
- **WHEN** `toProvideWithParams(...).singleton()` резолвится с разными `params`
- **THEN** используется первый созданный экземпляр singleton-кэша

### Requirement: Семантика резолва и fallback
Резолв MUST сначала искать binding в текущем scope и MAY fallback в родительский scope.

#### Scenario: Fallback к родителю
- **WHEN** dependency отсутствует в текущем scope и есть в родительском
- **THEN** результат возвращается из родительского scope

### Requirement: Sync/Async резолв и ошибки режима
`Scope` MUST предоставлять `resolve`, `tryResolve`, `resolveAsync`, `tryResolveAsync` и MUST сигнализировать об ошибках несоответствия режима.

#### Scenario: Sync для async binding
- **WHEN** async binding резолвится через sync API
- **THEN** выбрасывается `StateError` с указанием использовать async API

#### Scenario: Async для sync binding
- **WHEN** sync binding резолвится через async API
- **THEN** возвращается `Future<T>` с успешно резолвленным экземпляром

#### Scenario: Отсутствующий binding в tryResolve
- **WHEN** вызывается `tryResolve*` для незарегистрированной зависимости
- **THEN** возвращается `null`

### Requirement: Runtime params
Bindings с params MUST требовать передачу `params` при резолве.

#### Scenario: Отсутствующие params
- **WHEN** binding создан через `toProvideWithParams`, но `resolve*` вызван без `params`
- **THEN** выбрасывается `StateError`

### Requirement: Disposable lifecycle
`Scope` MUST отслеживать уже резолвленные экземпляры `Disposable` и MUST вызывать `dispose()` при закрытии scope.

#### Scenario: Закрытие scope
- **WHEN** вызывается `scope.dispose()` или `CherryPick.closeRootScope()`
- **THEN** освобождаются disposables текущего scope и всех дочерних scope

### Requirement: Детекция циклов
DI-ядро MUST поддерживать локальную и глобальную (cross-scope) детекцию циклов как включаемые режимы.

#### Scenario: Локальный цикл
- **WHEN** включена локальная детекция и обнаружен cycle
- **THEN** выбрасывается `CircularDependencyException`

#### Scenario: Глобальный цикл между scope
- **WHEN** включена глобальная cross-scope детекция и обнаружен cycle между scope
- **THEN** выбрасывается `CircularDependencyException` с цепочкой зависимостей

### Requirement: Observer-события
`CherryPickObserver` MUST получать события регистрации, резолва, lifecycle, cache, циклов, warning/error и diagnostics.

#### Scenario: Интеграция observer
- **WHEN** scope работает с заданным observer
- **THEN** observer получает события по контракту интерфейса `CherryPickObserver`
