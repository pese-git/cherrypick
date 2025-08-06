# benchmark_cherrypick

Бенчмарки производительности и возможностей DI-контейнера cherrypick (core).

Все сценарии используют только публичное API (scope, module, binding, scoping, async).

## Сценарии

- **RegisterAndResolve**: базовая регистрация и разрешение зависимости.
- **ChainSingleton (A->B->C, singleton)**: длинная цепочка зависимостей, все как singleton.
- **ChainFactory (A->B->C, factory)**: цепочка зависимостей через factory (новый объект на каждый запрос).
- **NamedResolve (by name)**: разрешение зависимости по имени среди нескольких реализаций.
- **AsyncChain (A->B->C, async)**: асинхронная цепочка зависимостей.
- **ScopeOverride (child overrides parent)**: перекрытие зависимости в дочернем scope относительно родителя.

## Возможности

- **Унифицированная структура бенчмарков**: Все тесты используют единый миксин для setup/teardown (`BenchmarkWithScope`).
- **Гибкая параметризация CLI**:  
  Любые комбинации параметров chainCount, nestingDepth, сценария и формата вывода.
- **Массовый/матричный запуск**:  
  Перебор всех вариантов комбинаций chainCount и depth одной командой.
- **Машино- и человекочитаемый вывод**:  
  Поддержка pretty-таблицы, CSV, JSON — удобно для анализа результатов.
- **Выбор сценария**:  
  Запуск всех сценариев или только нужного через CLI.

## Как запустить

1. Установить зависимости:
   ```shell
   dart pub get
   ```
2. Запустить все бенчмарки с параметрами по умолчанию:
   ```shell
   dart run bin/main.dart
   ```

### Запуск с параметрами

- Матричный прогон (csv-вывод):
  ```shell
  dart run bin/main.dart --benchmark=chain_singleton --chainCount=10,100 --nestingDepth=5,10 --format=csv
  ```

- Только сценарий разрешения по имени:
  ```shell
  dart run bin/main.dart --benchmark=named
  ```

- Справка по командам:
  ```shell
  dart run bin/main.dart --help
  ```

#### CLI-флаги

- `--benchmark` (или `-b`) — Сценарий:  
  `register`, `chain_singleton`, `chain_factory`, `named`, `override`, `async_chain`, `all` (по умолчанию)
- `--chainCount` (или `-c`) — Через запятую, несколько длин цепочек. Например: `10,100`
- `--nestingDepth` (или `-d`) — Через запятую, глубины цепочек. Например: `5,10`
- `--format` (или `-f`) — Формат вывода: `pretty` (таблица), `csv`, `json`
- `--help` (или `-h`) — Показать справку

#### Пример вывода (`--format=csv`)
```
benchmark,chainCount,nestingDepth,elapsed_us
ChainSingleton,10,5,2450000
ChainSingleton,10,10,2624000
ChainSingleton,100,5,2506300
ChainSingleton,100,10,2856900
```

---

## Добавить свой бенчмарк

1. Создайте Dart-файл с классом, наследующим BenchmarkBase или AsyncBenchmarkBase.
2. Используйте миксин BenchmarkWithScope для автоматического управления Scope.
3. Добавьте его вызов в bin/main.dart для выбора через CLI.

---

## Пример для контрибуторов

```dart
class MyBenchmark extends BenchmarkBase with BenchmarkWithScope {
  MyBenchmark() : super('My custom');
  @override void setup() => setupScope([MyModule()]);
  @override void run() { scope.resolve<MyType>(); }
  @override void teardown() => teardownScope();
}
```

---

## Лицензия

MIT
