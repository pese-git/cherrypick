# benchmark_cherrypick

_Бенчмаркинговый набор для cherrypick, get_it и других DI-контейнеров._

## Общее описание

benchmark_cherrypick — это современный фреймворк для измерения производительности DI-контейнеров (как cherrypick, так и get_it) на синтетических, сложных и реальных сценариях: цепочки зависимостей, factory, async, именованные биндинги, override и пр.

**Возможности:**
- Универсальный слой регистрации сценариев (работает с любым DI)
- Готовая поддержка [cherrypick](https://github.com/) и [get_it](https://pub.dev/packages/get_it)
- Удобный CLI для запусков по матрице значений параметров и различных форматов вывода (Markdown, CSV, JSON, pretty)
- Сбор и вывод метрик: время, память (RSS, peak), статистика (среднее, медиана, stddev, min/max)
- Легко расширять — создавайте свой DIAdapter и новые сценарии

---

## Сценарии бенчмарков

- **registerSingleton**: Регистрация и резолвинг singleton
- **chainSingleton**: Разрешение длинных singleton-цепочек (A→B→C…)
- **chainFactory**: То же, но с factory (каждый раз — новый объект)
- **asyncChain**: Асинхронная цепочка (async factory/provider)
- **named**: Разрешение по имени (например, из нескольких реализаций)
- **override**: Переопределение зависимостей в subScope

---

## Поддерживаемые DI-контейнеры

- **cherrypick** (по умолчанию)
- **get_it**
- Легко добавить свой DI через DIAdapter

Меняется одной CLI-опцией: `--di`

---

## Как запустить

1. **Установить зависимости:**
   ```shell
   dart pub get
   ```

2. **Запустить все бенчмарки (по умолчанию: все сценарии, 2 прогрева, 2 замера):**
   ```shell
   dart run bin/main.dart --benchmark=all --format=markdown
   ```

3. **Для get_it:**
   ```shell
   dart run bin/main.dart --di=getit --benchmark=all --format=markdown
   ```

4. **Показать все опции CLI:**
   ```shell
   dart run bin/main.dart --help
   ```

### Параметры CLI

- `--di` — Какой DI использовать: `cherrypick` (по умолчанию) или `getit`
- `--benchmark, -b` — Сценарий: `registerSingleton`, `chainSingleton`, `chainFactory`, `asyncChain`, `named`, `override`, `all`
- `--chainCount, -c` — Сколько параллельных цепочек (например, `10,100`)
- `--nestingDepth, -d` — Глубина цепочки (например, `5,10`)
- `--repeat, -r` — Повторов замера (по умолчанию 2)
- `--warmup, -w` — Прогревочных запусков (по умолчанию 1)
- `--format, -f` — Формат отчёта: `pretty`, `csv`, `json`, `markdown`
- `--help, -h` — Справка

### Примеры запуска

- **Все бенчмарки для cherrypick:**
  ```shell
  dart run bin/main.dart --di=cherrypick --benchmark=all --format=markdown
  ```

- **Для get_it (все сценарии):**
  ```shell
  dart run bin/main.dart --di=getit --benchmark=all --format=markdown
  ```

- **Запуск по матрице параметров:**
  ```shell
  dart run bin/main.dart --benchmark=chainSingleton --chainCount=10,100 --nestingDepth=5,10 --repeat=3 --format=csv
  ```

---

## Как добавить свой DI

1. Реализуйте класс-адаптер, реализующий `DIAdapter` (`lib/di_adapters/ваш_adapter.dart`)
2. Зарегистрируйте его в CLI (`cli/benchmark_cli.dart`)
3. Дополните универсальную функцию регистрации (`di_universal_registration.dart`), чтобы строить цепочки для вашего DI

---

## Архитектура

```mermaid
classDiagram
    class BenchmarkCliRunner {
        +run(args)
    }
    class UniversalChainBenchmark {
        +setup()
        +run()
        +teardown()
    }
    class UniversalChainAsyncBenchmark {
        +setup()
        +run()
        +teardown()
    }
    class DIAdapter {
        <<interface>>
        +setupDependencies(cb)
        +resolve<T>(named)
        +resolveAsync<T>(named)
        +teardown()
        +openSubScope(name)
        +waitForAsyncReady()
    }
    class CherrypickDIAdapter
    class GetItAdapter
    class UniversalChainModule {
        +builder(scope)
        +chainCount
        +nestingDepth
        +bindingMode
        +scenario
    }
    class UniversalService {
        <<interface>>
        +value
        +dependency
    }
    class UniversalServiceImpl {
        +UniversalServiceImpl(value, dependency)
    }
    class di_universal_registration {
        +getUniversalRegistration(adapter, ...)
    }
    class Scope
    class UniversalScenario
    class UniversalBindingMode

    %% Relationships
    
    BenchmarkCliRunner --> UniversalChainBenchmark
    BenchmarkCliRunner --> UniversalChainAsyncBenchmark

    UniversalChainBenchmark *-- DIAdapter
    UniversalChainAsyncBenchmark *-- DIAdapter

    DIAdapter <|.. CherrypickDIAdapter
    DIAdapter <|.. GetItAdapter

    CherrypickDIAdapter ..> Scope
    GetItAdapter ..> GetIt: "uses GetIt"

    DIAdapter o--> UniversalChainModule : setupDependencies

    UniversalChainModule ..> UniversalScenario
    UniversalChainModule ..> UniversalBindingMode

    UniversalChainModule o-- UniversalServiceImpl : creates
    UniversalService <|.. UniversalServiceImpl
    UniversalServiceImpl --> UniversalService : dependency

    BenchmarkCliRunner ..> di_universal_registration : uses
    di_universal_registration ..> DIAdapter

    UniversalChainBenchmark ..> di_universal_registration : uses registrar
    UniversalChainAsyncBenchmark ..> di_universal_registration : uses registrar
```

---

## Метрики

Всегда собираются:
- **Время** (мкс): среднее, медиана, stddev, min, max
- **Память**: прирост RSS, пиковое значение RSS

## Лицензия

MIT
