# benchmark_cherrypick

Бенчмарки производительности и функциональности DI-контейнера cherrypick (core).

Все сценарии используют реальные возможности public API cherrypick (scope, module, binding, scoping и асинхронность).

## Сценарии

- **RegisterAndResolve**: базовая операция регистрации и разрешения зависимости.
- **ChainSingleton (A->B->C, singleton)**: цепочка зависимостей, все singletons.
- **ChainFactory (A->B->C, factory)**: цепочка зависимостей с factory биндингами, новые объекты на каждый запрос.
- **NamedResolve (by name)**: разрешение именованной зависимости среди нескольких реализаций.
- **AsyncChain (A->B->C, async)**: асинхронная цепочка зависимостей.
- **ScopeOverride (child overrides parent)**: переопределение зависимости в дочернем scope над родительским.

## Результаты исследования

| Сценарий                                           | RunTime (мкс) |
|----------------------------------------------------|--------------|
| RegisterAndResolve                                 | 0.3407        |
| ChainSingleton (A->B->C, singleton)                | 0.3777        |
| ChainFactory (A->B->C, factory)                    | 0.9688        |
| NamedResolve (by name)                             | 0.3878        |
| AsyncChain (A->B->C, async)                        | 1.8006        |
| ScopeOverride (child overrides parent)             | 0.3477        |

## Как запускать

1. Получить зависимости:
   ```shell
   dart pub get
   ```
2. Запустить бенчмарк:
   ```shell
   dart run bin/main.dart
   ```

Будет показан текстовый отчёт по всем метрикам.

---

Если хотите добавить свой сценарий — создайте отдельный Dart-файл и объявите новый BenchmarkBase/AsyncBenchmarkBase, не забудьте вставить его вызов в main.
