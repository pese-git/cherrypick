# benchmark_cherrypick

Бенчмарки производительности и возможностей DI-контейнера cherrypick (core).

## Сценарии

- **RegisterAndResolve**: базовая регистрация и разрешение зависимости.
- **ChainSingleton** (A->B->C, singleton): длинная цепочка зависимостей, все как singleton.
- **ChainFactory** (A->B->C, factory): цепочка зависимостей через factory (новый объект на каждый запрос).
- **NamedResolve** (by name): разрешение зависимости по имени среди нескольких реализаций.
- **AsyncChain** (A->B->C, async): асинхронная цепочка зависимостей.
- **ScopeOverride** (child overrides parent): перекрытие зависимости в дочернем scope относительно родителя.

## Возможности

- **Унифицированная структура бенчмарков**
- **Гибкая параметризация CLI (chainCount, nestingDepth, repeats, warmup, сценарий, формат)**
- **Автоматический матричный запуск для наборов параметров**
- **Статистика: среднее, медиана, stddev, min, max для каждого сценария**
- **Память: memory_diff_kb (итоговая разница), delta_peak_kb (максимальный рост), peak_rss_kb (абсолютный пик)**
- **Вывод в таблицу, CSV или JSON**
- **Прогревочные запуски до замера времени для стабильности**

## Как запустить

1. Установить зависимости:
   ```shell
   dart pub get
   ```
2. Запустить все бенчмарки (по умолчанию: одни значения, repeat=5, warmup=2):
   ```shell
   dart run bin/main.dart
   ```

### Пользовательские параметры

- Матричный прогон (csv, 7 повторов, 3 прогрева):
  ```shell
  dart run bin/main.dart --benchmark=chain_singleton --chainCount=10,100 --nestingDepth=5,10 --repeat=7 --warmup=3 --format=csv
  ```

- Только сценарий с именованным разрешением:
  ```shell
  dart run bin/main.dart --benchmark=named --repeat=3 --warmup=1
  ```

- Посмотреть все флаги CLI:
  ```shell
  dart run bin/main.dart --help
  ```

#### Опции CLI

- `--benchmark` (`-b`) — Сценарий:
  `register`, `chain_singleton`, `chain_factory`, `named`, `override`, `async_chain`, `all` (по умолчанию all)
- `--chainCount` (`-c`) — Длины цепочек через запятую. Напр: `10,100`
- `--nestingDepth` (`-d`) — Глубины цепочек через запятую. Напр: `5,10`
- `--repeat` (`-r`) — Сколько раз мерить каждую конфигурацию (`по умолчанию: 5`)
- `--warmup` (`-w`) — Сколько прогревочных запусков до замера времени (`по умолчанию: 2`)
- `--format` (`-f`) — Вывод: `pretty`, `csv`, `json` (по умолчанию pretty)
- `--help` (`-h`) — Показать справку

#### Пример вывода (`--format=csv`)
```
benchmark,chainCount,nestingDepth,mean_us,median_us,stddev_us,min_us,max_us,trials,timings_us,memory_diff_kb,delta_peak_kb,peak_rss_kb
ChainSingleton,10,5,2450000,2440000,78000,2290000,2580000,5,"2440000;2460000;2450000;2580000;2290000",-64,0,200064
```

---

## Как добавить свой бенчмарк

1. Создайте Dart-файл с классом, унаследованным от `BenchmarkBase` или `AsyncBenchmarkBase`.
2. Используйте миксин `BenchmarkWithScope` для управления Scope (если нужно).
3. Добавьте ваш бенчмарк в bin/main.dart для запуска через CLI.

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
