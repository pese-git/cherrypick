# benchmark_cherrypick

_Набор бенчмарков для анализа производительности и особенностей DI-контейнера cherrypick._

## Описание

Этот пакет предоставляет комплексные синтетические бенчмарки для DI-контейнера [cherrypick](https://github.com/). CLI-интерфейс позволяет запускать сценарии с разной глубиной, шириной, вариантами разрешения (singletons, factories, named, override, async), снимая статистику по времени и памяти, генерируя отчёты в различных форматах.

**Особенности:**
- Матричный запуск (chain count, nesting depth, сценарий, повторы)
- Гибкая настройка CLI
- Много форматов отчётов: таблица, CSV, JSON, Markdown
- Подсчет времени и памяти (mean, median, stddev, min, max, разница RSS/пик)
- Встроенные и легко расширяемые сценарии (singletons, factories, async, named, override)
- Механизм подключения других DI-контейнеров через адаптеры

---

## Сценарии бенчмарков

- **RegisterSingleton**: Регистрация и разрешение singleton-зависимости
- **ChainSingleton**: Глубокая цепочка singleton-зависимостей (A→B→C...)
- **ChainFactory**: Цепочка с factory (новый объект при каждом разрешении)
- **AsyncChain**: Асинхронная цепочка зависимостей
- **Named**: Разрешение зависимости по имени среди нескольких реализаций
- **Override**: Разрешение зависимости, перекрытой в дочернем scope

---

## Как запустить

1. **Установите зависимости:**
   ```shell
   dart pub get
   ```
2. **Запустите все бенчмарки (по умолчанию: одна комбинация, 2 прогрева, 2 повтора):**
   ```shell
   dart run bin/main.dart
   ```

3. **Показать все CLI-параметры:**
   ```shell
   dart run bin/main.dart --help
   ```

### CLI-параметры

- `--benchmark, -b` — Сценарий:  
  `registerSingleton`, `chainSingleton`, `chainFactory`, `asyncChain`, `named`, `override`, `all` (по умолчанию: all)
- `--chainCount, -c` — Длины цепочек через запятую (`10,100`)
- `--nestingDepth, -d` — Глубины цепочек через запятую (`5,10`)
- `--repeat, -r` — Повторов на сценарий (по умолчанию 2)
- `--warmup, -w` — Прогревов до замера (по умолчанию 1)
- `--format, -f` — Формат отчёта: `pretty`, `csv`, `json`, `markdown` (по умолчанию pretty)
- `--help, -h` — Показать справку

### Примеры запуска

- **Матричный запуск:**
  ```shell
  dart run bin/main.dart --benchmark=chainSingleton --chainCount=10,100 --nestingDepth=5,10 --repeat=5 --warmup=2 --format=markdown
  ```

- **Только сценарий с именованным разрешением:**
  ```shell
  dart run bin/main.dart --benchmark=named --repeat=3
  ```

### Пример вывода (Markdown):

```
| Benchmark         | Chain Count | Depth | Mean (us) | ... | PeakRSS(KB) |
|------------------|-------------|-------|-----------| ... |-------------|
| ChainSingleton   | 10          | 5     | 2450000   | ... | 200064      |
```

---

## Форматы отчёта

- **pretty** — табличный человекочитаемый вывод
- **csv** — удобно для Excel и анализа скриптами
- **json** — для автотестов и аналитики
- **markdown** — Markdown-таблица (в Issues/Wiki)

---

## Как добавить свой бенчмарк

1. Создайте класс на основе `BenchmarkBase` (для sync) или `AsyncBenchmarkBase` (для async)
2. Настройте DI через адаптер, создайте нужный модуль/сценарий
3. Добавьте новый случай в bin/main.dart для CLI
4. Для поддержки других DI-контейнеров реализуйте свой DIAdapter

Пример минимального бенчмарка:
```dart
class MyBenchmark extends BenchmarkBase {
  MyBenchmark() : super('My custom');
  @override void setup() {/* настройка DI, создание цепочки */}
  @override void run()   {/* разрешение/запуск */}
  @override void teardown() {/* очистка, если нужно */}
}
```

---

## Метрики

Бенчмарки собирают:
- **Время** (мкс): среднее, медиана, stddev, min, max, полный лист замеров
- **Память (RSS):**
  - memory_diff_kb — итоговая разница RSS (KB)
  - delta_peak_kb  — разница пикового RSS (KB)
  - peak_rss_kb    — абсолютный пик (KB)

---

## Лицензия

MIT
