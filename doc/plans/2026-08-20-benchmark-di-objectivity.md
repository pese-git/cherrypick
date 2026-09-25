# benchmark_di: приведение к объективным измерениям — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Сделать так, чтобы каждое число, публикуемое benchmark_di, было воспроизводимым, семантически сопоставимым между DI-контейнерами и не могло быть получено вручную.

**Architecture:** Три слоя правок. Внизу — измерительный аппарат: наносекундное разрешение, батчи для steady-state, изоляция процесса на сценарий, робастная статистика. В середине — слой честности сценариев: тест на равенство объёма выполненной работы между адаптерами, который падает до тех пор, пока сценарий у разных DI строит разные графы. Наверху — генерация отчётов исключительно инструментом, без ручного редактирования таблиц.

**Tech Stack:** Dart 3.11.5, пакет `test`, `args`, `dart:io` (`Process`, `ProcessInfo`), melos-workspace cherrypick.

**Spec:** [doc/plans/2026-08-20-benchmark-di-audit.md](2026-08-20-benchmark-di-audit.md)

## Global Constraints

- Dart SDK: `>=3.2.0 <4.0.0`, фактический тулчейн 3.11.5.
- Измеряемая версия cherrypick — локальная по `path: ../cherrypick` (сейчас 4.0.0-dev.3). Не заменять на pub-версию.
- Новые зависимости разрешены только в `dev_dependencies` и только `test: ^1.25.0`. Прод-зависимости не добавлять.
- Ни один адаптер не получает преимущества за счёт другого: если сценарий у двух контейнеров строит разное число экземпляров, это ошибка сценария.
- Все таблицы в `REPORT*.md` генерируются командой и вставляются целиком. Ручная правка чисел запрещена.
- В каждом отчёте обязательна строка с режимом компиляции (JIT/AOT) и состоянием детектора циклов cherrypick.
- Формулировки в отчётах: «median», «min», «p95». Слово «mean» из главных таблиц убрать — оно неустойчиво к выбросам, которыми полны эти замеры.
- Комментарии и документация — на языке, уже принятом в файле (в `benchmark_di` смешанный ru/en; новые файлы — на русском, как `di_adapter.dart`).

---

### Task 1: Тестовая инфраструктура и строгий разбор CLI

Сейчас `-c=100` даёт пустую таблицу и код возврата 0. Пока CLI может молча ничего не измерить, ни одному последующему тесту нельзя верить.

**Files:**
- Modify: `benchmark_di/pubspec.yaml`
- Modify: `benchmark_di/lib/cli/parser.dart`
- Modify: `benchmark_di/README.md`
- Create: `benchmark_di/test/cli/parser_test.dart`

**Interfaces:**
- Consumes: ничего.
- Produces: `class BenchmarkCliException implements Exception { final String message; BenchmarkCliException(this.message); }` и `BenchmarkCliConfig parseBenchmarkCli(List<String> args)`, который бросает `BenchmarkCliException` вместо возврата пустых списков.

- [ ] **Step 1: Добавить пакет test**

В `benchmark_di/pubspec.yaml`, секция `dev_dependencies`:

```yaml
dev_dependencies:
  lints: ^5.0.0
  benchmark_harness: ^2.2.2
  benchmark_runner: ^0.0.2
  test: ^1.25.0
```

Run: `cd benchmark_di && dart pub get`

- [ ] **Step 2: Написать падающий тест**

Создать `benchmark_di/test/cli/parser_test.dart`:

```dart
import 'package:benchmark_di/cli/parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseBenchmarkCli', () {
    test('пустой список chainCount — ошибка, а не тихий пропуск', () {
      expect(
        () => parseBenchmarkCli(['--chainCount=0']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('короткий флаг со знаком равенства не молчит', () {
      // args трактует "-c=100" как значение "=100"
      expect(
        () => parseBenchmarkCli(['-c=100']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('короткий флаг через пробел работает', () {
      final config = parseBenchmarkCli(['-c', '100', '-d', '50']);
      expect(config.chainCounts, [100]);
      expect(config.nestDepths, [50]);
    });

    test('неизвестное имя сценария — ошибка, а не подмена на chainSingleton', () {
      expect(
        () => parseBenchmarkCli(['--benchmark=chainSinglton']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('неизвестный DI — ошибка', () {
      expect(
        () => parseBenchmarkCli(['--di=getit2']),
        throwsA(isA<BenchmarkCliException>()),
      );
    });

    test('корректная конфигурация разбирается', () {
      final config = parseBenchmarkCli([
        '--di=getit',
        '--benchmark=chainLazySingleton',
        '--chainCount=1,10',
        '--nestingDepth=100',
      ]);
      expect(config.di, 'getit');
      expect(config.chainCounts, [1, 10]);
      expect(config.nestDepths, [100]);
      expect(config.benchesToRun, [UniversalBenchmark.chainLazySingleton]);
    });
  });
}
```

- [ ] **Step 3: Убедиться, что тест падает**

Run: `cd benchmark_di && dart test test/cli/parser_test.dart`
Expected: FAIL — `BenchmarkCliException` не определён (ошибка компиляции).

- [ ] **Step 4: Реализовать строгий разбор**

В `benchmark_di/lib/cli/parser.dart` добавить класс исключения перед `parseEnum`:

```dart
/// Ошибка конфигурации командной строки. Бросается вместо тихого возврата
/// пустого списка — пустая матрица означала бы отчёт без единого замера.
class BenchmarkCliException implements Exception {
  final String message;
  BenchmarkCliException(this.message);
  @override
  String toString() => 'BenchmarkCliException: $message';
}
```

Заменить `parseIntList` на строгую версию:

```dart
/// Разбирает список положительных целых из [s]. Любой невалидный элемент —
/// ошибка: "-c=100" приходит сюда как "=100", и молчаливый пропуск такого
/// значения оставлял бы пользователя с пустой таблицей и кодом возврата 0.
List<int> parseIntList(String s, String optionName) {
  final parts = s.split(',').map((e) => e.trim()).toList();
  final result = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value <= 0) {
      throw BenchmarkCliException(
          'Опция --$optionName: "$part" не является положительным целым. '
          'Короткие флаги пишутся через пробел: -c 100, а не -c=100.');
    }
    result.add(value);
  }
  if (result.isEmpty) {
    throw BenchmarkCliException('Опция --$optionName не может быть пустой.');
  }
  return result;
}
```

Заменить `parseEnum` на версию без «тихого» значения по умолчанию:

```dart
/// Строго разбирает значение перечисления [T]. Без fallback: подмена опечатки
/// на chainSingleton давала бы отчёт с чужими числами под чужим именем.
T parseEnumStrict<T>(String value, List<T> values, String optionName) {
  for (final v in values) {
    if (v.toString().split('.').last.toLowerCase() == value.toLowerCase()) {
      return v;
    }
  }
  final known = values.map((v) => v.toString().split('.').last).join(', ');
  throw BenchmarkCliException(
      'Опция --$optionName: неизвестное значение "$value". Допустимые: $known.');
}
```

В теле `parseBenchmarkCli` заменить вызовы и добавить проверку `--di`:

```dart
  const knownDi = {'cherrypick', 'getit', 'riverpod', 'kiwi', 'yx_scope'};
  final di = result['di'] as String? ?? 'cherrypick';
  if (!knownDi.contains(di)) {
    throw BenchmarkCliException(
        'Опция --di: неизвестное значение "$di". Допустимые: ${knownDi.join(', ')}.');
  }

  final benchesToRun = isAll
      ? allBenches
      : benchNameInput
          .split(',')
          .map((n) => parseEnumStrict(
              normalizeBenchName(n), allBenches, 'benchmark'))
          .toSet()
          .toList();

  return BenchmarkCliConfig(
    benchesToRun: benchesToRun,
    chainCounts: parseIntList(result['chainCount'] as String, 'chainCount'),
    nestDepths: parseIntList(result['nestingDepth'] as String, 'nestingDepth'),
    repeats: int.tryParse(result['repeat'] as String? ?? '') ?? 2,
    warmups: int.tryParse(result['warmup'] as String? ?? '') ?? 1,
    format: result['format'] as String,
    di: di,
    phases: phases,
  );
```

Также в `normalizeBenchName` строку `_ => n,` оставить как есть — неизвестное имя теперь отсеется в `parseEnumStrict`.

- [ ] **Step 5: Убедиться, что тест проходит**

Run: `cd benchmark_di && dart test test/cli/parser_test.dart`
Expected: PASS, 6 тестов.

- [ ] **Step 6: Прокинуть ошибку до кода возврата**

В `benchmark_di/bin/main.dart`:

```dart
import 'dart:io';

import 'package:benchmark_di/cli/benchmark_cli.dart';
import 'package:benchmark_di/cli/parser.dart';

Future<void> main(List<String> args) async {
  try {
    await BenchmarkCliRunner().run(args);
  } on BenchmarkCliException catch (e) {
    stderr.writeln(e.message);
    exit(64); // EX_USAGE
  }
}
```

- [ ] **Step 7: Проверить поведение вручную**

Run: `cd benchmark_di && dart run bin/main.dart -c=100 ; echo "exit=$?"`
Expected: сообщение об ошибке в stderr и `exit=64`.

- [ ] **Step 8: Исправить примеры в README**

В `benchmark_di/README.md` заменить все вхождения коротких флагов со знаком равенства на длинные формы. Конкретно строку раздела «Specify chains/depth matrix»:

```shell
dart run bin/main.dart --benchmark=chainSingleton --chainCount=10,100 --nestingDepth=5,10 --repeat=3 --format=csv
```

и добавить сразу под списком параметров:

```markdown
> Короткие флаги пишутся через пробел (`-c 100`), не через знак равенства (`-c=100`).
```

- [ ] **Step 9: Commit**

```bash
git add benchmark_di/pubspec.yaml benchmark_di/lib/cli/parser.dart benchmark_di/bin/main.dart benchmark_di/test/cli/parser_test.dart benchmark_di/README.md
git commit -m "fix(benchmark_di): строгий разбор CLI вместо тихой пустой матрицы"
```

---

### Task 2: Валидный JSON-отчёт

`JsonReport` печатает `Map.toString()`. Агрегатор из Task 8 будет читать вывод дочерних процессов, поэтому формат обязан парситься.

**Files:**
- Modify: `benchmark_di/lib/cli/report/json_report.dart`
- Create: `benchmark_di/test/cli/report/json_report_test.dart`

**Interfaces:**
- Consumes: `ReportGenerator.render(List<Map<String, dynamic>> results) -> String` из `report_generator.dart`.
- Produces: вывод `JsonReport().render(...)`, проходящий `jsonDecode`.

- [ ] **Step 1: Написать падающий тест**

Создать `benchmark_di/test/cli/report/json_report_test.dart`:

```dart
import 'dart:convert';

import 'package:benchmark_di/cli/report/json_report.dart';
import 'package:test/test.dart';

void main() {
  test('вывод JsonReport парсится jsonDecode', () {
    final rendered = JsonReport().render([
      {
        'benchmark': 'Universal_chainLazySingleton',
        'phase': 'firstResolve',
        'chainCount': 100,
        'nestingDepth': 100,
        'median_ns': '35200.00',
        'trials': 5,
        'timings_ns': ['33000.00', '35200.00'],
        'peak_rss_kb': 294000,
      }
    ]);

    final decoded = jsonDecode(rendered);
    expect(decoded, isA<List>());
    expect(decoded[0]['benchmark'], 'Universal_chainLazySingleton');
    expect(decoded[0]['chainCount'], 100);
    expect(decoded[0]['timings_ns'], hasLength(2));
  });

  test('пустой список результатов даёт валидный пустой JSON', () {
    expect(jsonDecode(JsonReport().render([])), isEmpty);
  });
}
```

- [ ] **Step 2: Запустить и убедиться, что падает**

Run: `cd benchmark_di && dart test test/cli/report/json_report_test.dart`
Expected: FAIL — `FormatException` на `jsonDecode`.

- [ ] **Step 3: Реализовать через dart:convert**

Заменить содержимое `benchmark_di/lib/cli/report/json_report.dart`:

```dart
import 'dart:convert';

import 'report_generator.dart';

/// Отчёт в машинночитаемом JSON. Используется агрегатором матрицы,
/// поэтому формат обязан проходить jsonDecode без предобработки.
class JsonReport implements ReportGenerator {
  @override
  String render(List<Map<String, dynamic>> results) =>
      const JsonEncoder.withIndent('  ').convert(results);
}
```

Если сигнатура `ReportGenerator` отличается — привести к той, что объявлена в `report_generator.dart`, не меняя её.

- [ ] **Step 4: Убедиться, что тест проходит**

Run: `cd benchmark_di && dart test test/cli/report/json_report_test.dart`
Expected: PASS, 2 теста.

- [ ] **Step 5: Commit**

```bash
git add benchmark_di/lib/cli/report/json_report.dart benchmark_di/test/cli/report/json_report_test.dart
git commit -m "fix(benchmark_di): JSON-отчёт через dart:convert"
```

---

### Task 3: Счётчик экземпляров и тест равного объёма работы

Это центральная защита от Д1. Тест намеренно останется красным по `asyncChain` до Task 4 — он и есть формулировка бага.

**Files:**
- Modify: `benchmark_di/lib/scenarios/universal_service.dart`
- Create: `benchmark_di/test/support/adapters.dart`
- Create: `benchmark_di/test/equivalence_test.dart`

**Interfaces:**
- Consumes: `DIAdapter<T>`, `UniversalScenario`, `UniversalBindingMode` из `lib/`.
- Produces:
  - `UniversalServiceImpl.countingEnabled` (bool, static), `UniversalServiceImpl.createdCount` (int, static), `UniversalServiceImpl.resetCounter()`.
  - `Map<String, DIAdapter Function()> allAdapters` в `test/support/adapters.dart`.

- [ ] **Step 1: Добавить счётчик в UniversalServiceImpl**

Заменить класс в `benchmark_di/lib/scenarios/universal_service.dart`:

```dart
/// Default implementation for [UniversalService] used in service chains.
///
/// Считает созданные экземпляры, когда включён [countingEnabled]. Счётчик
/// нужен тесту равного объёма работы: если один DI при первом резолве строит
/// 100 объектов, а другой 10 000, сравнивать их время бессмысленно.
/// В измерительном прогоне флаг выключен, и цена — одна проверка bool,
/// одинаковая для всех адаптеров.
class UniversalServiceImpl extends UniversalService {
  static bool countingEnabled = false;
  static int createdCount = 0;

  static void resetCounter() {
    createdCount = 0;
  }

  UniversalServiceImpl({required super.value, super.dependency}) {
    if (countingEnabled) createdCount++;
  }
}
```

- [ ] **Step 2: Создать общую фабрику адаптеров для тестов**

Создать `benchmark_di/test/support/adapters.dart`:

```dart
import 'package:benchmark_di/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/di_adapters/get_it_adapter.dart';
import 'package:benchmark_di/di_adapters/kiwi_adapter.dart';
import 'package:benchmark_di/di_adapters/riverpod_adapter.dart';
import 'package:benchmark_di/di_adapters/yx_scope_adapter.dart';

/// Все адаптеры под тестом. Ключ совпадает со значением опции --di.
final Map<String, DIAdapter Function()> allAdapters = {
  'cherrypick': () => CherrypickDIAdapter(),
  'getit': () => GetItAdapter(),
  'riverpod': () => RiverpodAdapter(),
  'kiwi': () => KiwiAdapter(),
  'yx_scope': () => YxScopeAdapter(),
};

/// Адаптеры, поддерживающие асинхронные привязки.
const asyncCapable = {'cherrypick', 'getit', 'riverpod'};
```

- [ ] **Step 3: Написать падающий тест равного объёма работы**

Создать `benchmark_di/test/equivalence_test.dart`:

```dart
import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:test/test.dart';

import 'support/adapters.dart';

const chainCount = 5;
const nestingDepth = 10;

Future<int> instancesCreatedOnFirstResolve(
  DIAdapter adapter, {
  required UniversalScenario scenario,
  required UniversalBindingMode mode,
  required bool isAsync,
}) async {
  UniversalServiceImpl.countingEnabled = true;
  UniversalServiceImpl.resetCounter();
  adapter.setupDependencies(adapter.universalRegistration(
    scenario: scenario,
    chainCount: chainCount,
    nestingDepth: nestingDepth,
    bindingMode: mode,
  ));
  final name = '${chainCount}_$nestingDepth';
  if (isAsync) {
    await adapter.resolveAsync<UniversalService>(named: name);
  } else {
    adapter.resolve<UniversalService>(named: name);
  }
  final count = UniversalServiceImpl.createdCount;
  UniversalServiceImpl.countingEnabled = false;
  return count;
}

void main() {
  group('первый резолв строит одинаковый граф во всех DI', () {
    test('chainLazySingleton: ровно nestingDepth экземпляров', () async {
      for (final entry in allAdapters.entries) {
        final count = await instancesCreatedOnFirstResolve(
          entry.value(),
          scenario: UniversalScenario.chain,
          mode: UniversalBindingMode.lazySingletonStrategy,
          isAsync: false,
        );
        expect(count, nestingDepth,
            reason: '${entry.key} построил $count экземпляров вместо '
                '$nestingDepth — сценарии не эквивалентны');
      }
    });

    test('asyncChain: ровно nestingDepth экземпляров', () async {
      for (final name in asyncCapable) {
        final count = await instancesCreatedOnFirstResolve(
          allAdapters[name]!(),
          scenario: UniversalScenario.asyncChain,
          mode: UniversalBindingMode.asyncStrategy,
          isAsync: true,
        );
        expect(count, nestingDepth,
            reason: '$name построил $count экземпляров вместо $nestingDepth — '
                'сравнение времени между DI недействительно');
      }
    });
  });
}
```

- [ ] **Step 4: Запустить и зафиксировать ожидаемое падение**

Run: `cd benchmark_di && dart test test/equivalence_test.dart`
Expected: тест `chainLazySingleton` — PASS. Тест `asyncChain` — FAIL: `getit построил 50 экземпляров вместо 10`. Это подтверждение Д1 в форме автотеста; чинится в Task 4.

- [ ] **Step 5: Commit (красный тест фиксирует баг)**

```bash
git add benchmark_di/lib/scenarios/universal_service.dart benchmark_di/test/support/adapters.dart benchmark_di/test/equivalence_test.dart
git commit -m "test(benchmark_di): тест равного объёма работы, красный на asyncChain"
```

---

### Task 4: Выравнивание async-сценария

**Files:**
- Modify: `benchmark_di/lib/di_adapters/get_it_adapter.dart:74-90` (ветка `asyncChain`) и ветка `asyncStrategy` внутри `chain`
- Test: `benchmark_di/test/equivalence_test.dart` (уже написан)

**Interfaces:**
- Consumes: `UniversalServiceImpl.createdCount` из Task 3.
- Produces: async-регистрация get_it с ленивой семантикой, эквивалентной `toProvideAsync().singleton()` у cherrypick.

- [ ] **Step 1: Заменить registerSingletonAsync на ленивый вариант**

В `benchmark_di/lib/di_adapters/get_it_adapter.dart`, ветка `case UniversalScenario.asyncChain:`:

```dart
          case UniversalScenario.asyncChain:
            // registerSingletonAsync инициализирует ВСЕ зарегистрированные
            // async-синглтоны сразу, независимо от того, что резолвит бенчмарк.
            // При chainCount=100/depth=100 это 10 000 объектов против 100 у
            // ленивых контейнеров. registerLazySingletonAsync строит только
            // запрошенную цепочку — та же семантика, что toProvideAsync().singleton().
            for (int chain = 1; chain <= chainCount; chain++) {
              for (int level = 1; level <= nestingDepth; level++) {
                final prevDepName = '${chain}_${level - 1}';
                final depName = '${chain}_$level';
                getIt.registerLazySingletonAsync<UniversalService>(
                  () async {
                    final prev = level > 1
                        ? await getIt.getAsync<UniversalService>(
                            instanceName: prevDepName)
                        : null;
                    return UniversalServiceImpl(
                        value: depName, dependency: prev);
                  },
                  instanceName: depName,
                );
              }
            }
            break;
```

Ту же замену сделать в ветке `case UniversalBindingMode.asyncStrategy:` внутри `case UniversalScenario.chain:`.

- [ ] **Step 2: Запустить тест эквивалентности**

Run: `cd benchmark_di && dart test test/equivalence_test.dart`
Expected: PASS, оба теста.

- [ ] **Step 3: Убедиться, что waitForAsyncReady всё ещё осмыслен**

`GetItAdapter.waitForAsyncReady` вызывает `allReady()`, на который `registerLazySingletonAsync` не влияет (документация get_it). Для фазы steady-state прогрев теперь обеспечивается вызовом `prewarm()` в раннере, а не `allReady()`. Заменить тело:

```dart
  @override
  Future<void> waitForAsyncReady() async {
    // registerLazySingletonAsync не участвует в allReady: прогрев делает
    // prewarm() в раннере, одинаково для всех адаптеров.
    await _getIt.allReady();
  }
```

Оставить `allReady()` — он безвреден и остаётся корректным, если в сценарии появятся eager-async привязки.

- [ ] **Step 4: Замерить и записать новое соотношение**

Run:
```bash
cd benchmark_di
dart run bin/main.dart --di=cherrypick --benchmark=chainAsync --chainCount=100 --nestingDepth=100 --repeat=5 --warmup=2 --resolvePhase=first --format=pretty
dart run bin/main.dart --di=getit --benchmark=chainAsync --chainCount=100 --nestingDepth=100 --repeat=5 --warmup=2 --resolvePhase=first --format=pretty
```
Expected: разрыв сокращается с ~60× до величины, отражающей стоимость резолва, а не количество объектов. Записать полученные числа в тело коммита.

- [ ] **Step 5: Commit**

```bash
git add benchmark_di/lib/di_adapters/get_it_adapter.dart
git commit -m "fix(benchmark_di): ленивая async-регистрация get_it для равного объёма работы"
```

---

### Task 5: Асинхронный teardown по всей цепочке

**Files:**
- Modify: `benchmark_di/lib/di_adapters/di_adapter.dart:24`
- Modify: `benchmark_di/lib/di_adapters/get_it_adapter.dart`, `kiwi_adapter.dart`, `riverpod_adapter.dart`, `yx_scope_adapter.dart`, `cherrypick_adapter.dart`
- Modify: `benchmark_di/lib/benchmarks/universal_chain_benchmark.dart`
- Modify: `benchmark_di/lib/cli/runner.dart`
- Create: `benchmark_di/test/teardown_test.dart`

**Interfaces:**
- Consumes: `allAdapters` из Task 3.
- Produces: `Future<void> DIAdapter.teardown()`; `Future<void> UniversalChainBenchmark.teardownAsync()`; `BenchmarkRunner.runSync` становится `Future`-совместимым по teardown.

- [ ] **Step 1: Написать падающий тест**

Создать `benchmark_di/test/teardown_test.dart`:

```dart
import 'package:benchmark_di/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

void main() {
  test('после teardown cherrypick получает свежий root scope', () async {
    final scopes = <Scope>[];
    for (var i = 0; i < 3; i++) {
      final adapter = CherrypickDIAdapter();
      adapter.setupDependencies(adapter.universalRegistration(
        scenario: UniversalScenario.chain,
        chainCount: 2,
        nestingDepth: 3,
        bindingMode: UniversalBindingMode.lazySingletonStrategy,
      ));
      adapter.resolve<UniversalService>(named: '2_3');
      scopes.add(CherryPick.openRootScope());
      await adapter.teardown();
    }
    expect(identical(scopes[0], scopes[1]), isFalse,
        reason: 'root scope переиспользован между итерациями: '
            'модули накапливаются, состояние контейнера невоспроизводимо');
    expect(identical(scopes[1], scopes[2]), isFalse);
  });
}
```

- [ ] **Step 2: Запустить и убедиться, что падает**

Run: `cd benchmark_di && dart test test/teardown_test.dart`
Expected: FAIL — `root scope переиспользован между итерациями`.

- [ ] **Step 3: Сделать teardown асинхронным в интерфейсе**

В `benchmark_di/lib/di_adapters/di_adapter.dart`:

```dart
  /// Уничтожает/отчищает DI-контейнер. Асинхронный: cherrypick освобождает
  /// Disposable-зависимости через await, и синхронный вызов оставлял бы
  /// контейнер частично живым к следующей итерации.
  Future<void> teardown();
```

- [ ] **Step 4: Привести адаптеры к новой сигнатуре**

`get_it_adapter.dart`:

```dart
  @override
  Future<void> teardown() async {
    if (_isSubScope && _scopePushed) {
      await _getIt.popScope();
      _scopePushed = false;
    } else {
      await _getIt.reset();
    }
  }
```

`kiwi_adapter.dart`:

```dart
  @override
  Future<void> teardown() async {
    _container.clear();
  }
```

`riverpod_adapter.dart`:

```dart
  @override
  Future<void> teardown() async {
    _container?.dispose();
    _container = null;
    _namedProviders.clear();
  }
```

`yx_scope_adapter.dart`:

```dart
  @override
  Future<void> teardown() async {
    _scope = UniversalYxScopeContainer();
  }
```

`cherrypick_adapter.dart` уже возвращает `Future<void>` — оставить как есть.

- [ ] **Step 5: Прокинуть await через бенчмарк и раннер**

В `benchmark_di/lib/benchmarks/universal_chain_benchmark.dart` заменить `teardown`:

```dart
  @override
  void teardown() {
    // BenchmarkBase требует синхронную сигнатуру. Раннер её не использует —
    // он вызывает teardownAsync, чтобы дождаться освобождения контейнера.
    // Пустое тело оставлено, чтобы наследуемый measure() из benchmark_harness
    // не падал, если его когда-нибудь вызовут.
  }

  Future<void> teardownAsync() async {
    await _childDi?.teardown();
    await _di.teardown();
  }
```

В `benchmark_di/lib/cli/runner.dart`, в обоих циклах `runSync`, заменить `benchmark.teardown();` на `await benchmark.teardownAsync();`. В `runAsync` — `await benchmark.teardownAsync();` вместо `await benchmark.teardown();`, а в `UniversalChainAsyncBenchmark` добавить такой же метод:

```dart
  Future<void> teardownAsync() async {
    await di.teardown();
  }
```

Оставить наследуемый `Future<void> teardown()` в асинхронном бенчмарке делегирующим:

```dart
  @override
  Future<void> teardown() => teardownAsync();
```

- [ ] **Step 6: Убедиться, что тест проходит**

Run: `cd benchmark_di && dart test test/teardown_test.dart test/equivalence_test.dart`
Expected: PASS.

- [ ] **Step 7: Проверить, что CLI не сломался**

Run: `cd benchmark_di && dart run bin/main.dart --di=cherrypick --benchmark=chainLazySingleton --chainCount=10 --nestingDepth=10 --repeat=3 --warmup=1 --format=pretty`
Expected: одна строка результата, без исключений.

- [ ] **Step 8: Commit**

```bash
git add benchmark_di/lib benchmark_di/test/teardown_test.dart
git commit -m "fix(benchmark_di): асинхронный teardown, свежий контейнер на каждую итерацию"
```

---

### Task 6: Наносекундное разрешение и батчи для steady-state

**Files:**
- Modify: `benchmark_di/lib/cli/runner.dart`
- Modify: `benchmark_di/lib/cli/parser.dart` (опция `--opsPerSample`)
- Modify: `benchmark_di/lib/cli/benchmark_cli.dart` (ключи результата `*_ns`)
- Modify: `benchmark_di/lib/cli/report/pretty_report.dart`, `csv_report.dart`, `markdown_report.dart`
- Create: `benchmark_di/test/cli/runner_resolution_test.dart`

**Interfaces:**
- Consumes: `UniversalChainBenchmark`, `ResolvePhase` из предыдущих задач.
- Produces: `BenchmarkResult.timings` в наносекундах (`List<double>`); поле `BenchmarkCliConfig.opsPerSample` (int, по умолчанию 1000); ключи результата `median_ns`, `min_ns`, `p95_ns`, `mad_ns`, `timings_ns`.

- [ ] **Step 1: Написать падающий тест на разрешение**

Создать `benchmark_di/test/cli/runner_resolution_test.dart`:

```dart
import 'package:benchmark_di/benchmarks/universal_chain_benchmark.dart';
import 'package:benchmark_di/cli/parser.dart';
import 'package:benchmark_di/cli/runner.dart';
import 'package:benchmark_di/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

void main() {
  test('быстрая операция не измеряется нулями', () async {
    final benchmark = UniversalChainBenchmark<Scope>(
      CherrypickDIAdapter(),
      chainCount: 1,
      nestingDepth: 1,
      mode: UniversalBindingMode.singletonStrategy,
      scenario: UniversalScenario.named,
    );
    final result = await BenchmarkRunner.runSync(
      benchmark: benchmark,
      warmups: 2,
      repeats: 20,
      phase: ResolvePhase.steadyStateResolve,
      opsPerSample: 1000,
    );

    expect(result.timings, hasLength(20));
    expect(result.timings.where((t) => t == 0), isEmpty,
        reason: 'нулевые замеры означают, что разрешение таймера крупнее '
            'измеряемой величины — числа в отчёте были бы шумом');
  });
}
```

- [ ] **Step 2: Запустить и убедиться, что падает**

Run: `cd benchmark_di && dart test test/cli/runner_resolution_test.dart`
Expected: FAIL — у `runSync` нет параметра `opsPerSample` (ошибка компиляции).

- [ ] **Step 3: Переписать раннер**

Заменить класс `BenchmarkRunner` в `benchmark_di/lib/cli/runner.dart`:

```dart
/// Static methods to execute and time benchmarks for DI containers.
class BenchmarkRunner {
  /// Синхронный прогон.
  ///
  /// [opsPerSample] действует только в фазе steady-state: там один резолв
  /// стоит десятки наносекунд, и единичный замер тонет в разрешении таймера,
  /// поэтому меряется пачка и делится на размер пачки. В фазе first-resolve
  /// пачка невозможна по определению — второй вызов уже попадёт в кеш, —
  /// поэтому там меряется один вызов, но в тиках (наносекундах).
  static Future<BenchmarkResult> runSync({
    required UniversalChainBenchmark benchmark,
    required int warmups,
    required int repeats,
    required ResolvePhase phase,
    required int opsPerSample,
  }) async {
    final steady = phase == ResolvePhase.steadyStateResolve;
    final ops = steady ? opsPerSample : 1;
    final timings = <double>[];
    final rssValues = <int>[];

    for (int i = 0; i < warmups; i++) {
      benchmark.setup();
      if (steady) benchmark.prewarm();
      for (int k = 0; k < ops; k++) {
        benchmark.run();
      }
      await benchmark.teardownAsync();
    }

    final memBefore = ProcessInfo.currentRss;
    for (int i = 0; i < repeats; i++) {
      benchmark.setup();
      if (steady) benchmark.prewarm();
      final sw = Stopwatch()..start();
      for (int k = 0; k < ops; k++) {
        benchmark.run();
      }
      sw.stop();
      timings.add(_nanosPerOp(sw, ops));
      rssValues.add(ProcessInfo.currentRss);
      await benchmark.teardownAsync();
    }
    return BenchmarkResult.collect(
        timings: timings, rssValues: rssValues, memBefore: memBefore);
  }

  /// Асинхронный прогон. Смысл [opsPerSample] тот же.
  static Future<BenchmarkResult> runAsync({
    required UniversalChainAsyncBenchmark benchmark,
    required int warmups,
    required int repeats,
    required ResolvePhase phase,
    required int opsPerSample,
  }) async {
    final steady = phase == ResolvePhase.steadyStateResolve;
    final ops = steady ? opsPerSample : 1;
    final timings = <double>[];
    final rssValues = <int>[];

    for (int i = 0; i < warmups; i++) {
      await benchmark.setup();
      if (steady) await benchmark.prewarm();
      for (int k = 0; k < ops; k++) {
        await benchmark.run();
      }
      await benchmark.teardownAsync();
    }

    final memBefore = ProcessInfo.currentRss;
    for (int i = 0; i < repeats; i++) {
      await benchmark.setup();
      if (steady) await benchmark.prewarm();
      final sw = Stopwatch()..start();
      for (int k = 0; k < ops; k++) {
        await benchmark.run();
      }
      sw.stop();
      timings.add(_nanosPerOp(sw, ops));
      rssValues.add(ProcessInfo.currentRss);
      await benchmark.teardownAsync();
    }
    return BenchmarkResult.collect(
        timings: timings, rssValues: rssValues, memBefore: memBefore);
  }

  /// Наносекунды на одну операцию. elapsedTicks на поддерживаемых платформах
  /// имеет наносекундную частоту; пересчёт через frequency делает это явным.
  static double _nanosPerOp(Stopwatch sw, int ops) =>
      sw.elapsedTicks * 1e9 / sw.frequency / ops;
}
```

В `BenchmarkResult` заменить тип поля:

```dart
  /// List of timings for each sample, наносекунды на одну операцию.
  final List<double> timings;
```

и в `BenchmarkResult.collect` заменить `required List<num> timings` на `required List<double> timings`.

- [ ] **Step 4: Добавить опцию --opsPerSample**

В `benchmark_di/lib/cli/parser.dart` в `BenchmarkCliConfig` добавить поле `final int opsPerSample;` (и в конструктор, как `required this.opsPerSample`), в `ArgParser`:

```dart
    ..addOption('opsPerSample',
        defaultsTo: '1000',
        help: 'Сколько резолвов в одном замере фазы steady (first — всегда 1)')
```

и в возвращаемую конфигурацию:

```dart
    opsPerSample: parseIntList(result['opsPerSample'] as String, 'opsPerSample').first,
```

- [ ] **Step 5: Прокинуть параметр в вызовы**

В `benchmark_di/lib/cli/benchmark_cli.dart` во все десять вызовов `BenchmarkRunner.runSync`/`runAsync` добавить `opsPerSample: config.opsPerSample,`.

- [ ] **Step 6: Обновить формирование результата**

В `benchmark_di/lib/cli/benchmark_cli.dart` заменить блок статистики:

```dart
            final timings = benchResult.timings;
            if (timings.isEmpty) continue;
            final sorted = [...timings]..sort();
            final count = sorted.length;
            final median = count.isOdd
                ? sorted[count ~/ 2]
                : (sorted[count ~/ 2 - 1] + sorted[count ~/ 2]) / 2;
            final p95 = sorted[((count - 1) * 0.95).round()];
            // Медианное абсолютное отклонение: устойчиво к выбросам, которых
            // в этих замерах больше, чем полезного сигнала.
            final deviations = sorted.map((x) => (x - median).abs()).toList()
              ..sort();
            final mad = deviations.length.isOdd
                ? deviations[deviations.length ~/ 2]
                : (deviations[deviations.length ~/ 2 - 1] +
                        deviations[deviations.length ~/ 2]) /
                    2;

            results.add({
              'benchmark': 'Universal_$bench',
              'di': config.di,
              'phase': phase.name,
              'chainCount': c,
              'nestingDepth': d,
              'median_ns': median.toStringAsFixed(1),
              'min_ns': sorted.first.toStringAsFixed(1),
              'p95_ns': p95.toStringAsFixed(1),
              'mad_ns': mad.toStringAsFixed(1),
              'ops_per_sample':
                  phase == ResolvePhase.steadyStateResolve ? config.opsPerSample : 1,
              'trials': count,
              'timings_ns': sorted.map((t) => t.toStringAsFixed(1)).toList(),
              'memory_diff_kb': benchResult.memoryDiffKb,
              'delta_peak_kb': benchResult.deltaPeakKb,
              'peak_rss_kb': benchResult.peakRssKb,
            });
```

- [ ] **Step 7: Обновить заголовки отчётов**

В `pretty_report.dart`, `csv_report.dart`, `markdown_report.dart` заменить колонки `Mean (us) / Median / Stddev / Min / Max` на `Median (ns) / Min (ns) / p95 (ns) / MAD (ns) / Ops`, читая соответственно ключи `median_ns`, `min_ns`, `p95_ns`, `mad_ns`, `ops_per_sample`. Добавить колонку `DI`, читающую ключ `di`.

- [ ] **Step 8: Убедиться, что тесты проходят**

Run: `cd benchmark_di && dart test`
Expected: PASS во всех файлах.

- [ ] **Step 9: Проверить, что нули ушли**

Run: `cd benchmark_di && dart run bin/main.dart --di=cherrypick --benchmark=named --chainCount=10 --nestingDepth=5 --repeat=20 --warmup=2 --resolvePhase=steady --format=json`
Expected: в `timings_ns` нет нулей, значения порядка десятков-сотен наносекунд.

- [ ] **Step 10: Commit**

```bash
git add benchmark_di/lib benchmark_di/test/cli/runner_resolution_test.dart
git commit -m "feat(benchmark_di): наносекундное разрешение и батчи для steady-state"
```

---

### Task 7: Честный сценарий override

**Files:**
- Modify: `benchmark_di/lib/benchmarks/universal_chain_benchmark.dart:28-45`
- Modify: `benchmark_di/lib/di_adapters/kiwi_adapter.dart`, `yx_scope_adapter.dart`
- Modify: `benchmark_di/lib/cli/benchmark_cli.dart` (список неподдерживающих)
- Create: `benchmark_di/test/scope_hierarchy_test.dart`

**Interfaces:**
- Consumes: `allAdapters` из Task 3.
- Produces: константа `const hierarchyUnsupported = {'kiwi', 'yx_scope'};` в `benchmark_di/lib/cli/parser.dart`; ветка `UniversalScenario.override` в адаптерах становится достижимой.

- [ ] **Step 1: Написать тест на иерархию**

Создать `benchmark_di/test/scope_hierarchy_test.dart`:

```dart
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:test/test.dart';

import 'support/adapters.dart';

/// Контейнеры, у которых дочерний scope видит регистрации родителя.
const hierarchical = {'cherrypick', 'getit', 'riverpod'};

void main() {
  group('дочерний scope', () {
    for (final name in hierarchical) {
      test('$name: резолвит из родителя без собственных регистраций', () {
        final parent = allAdapters[name]!();
        parent.setupDependencies(parent.universalRegistration(
          scenario: UniversalScenario.chain,
          chainCount: 1,
          nestingDepth: 3,
          bindingMode: UniversalBindingMode.singletonStrategy,
        ));
        final child = parent.openSubScope('child');
        expect(child.resolve<UniversalService>().value, '1_3');
      });
    }

    for (final name in {'kiwi', 'yx_scope'}) {
      test('$name: сценарий override объявлен неподдерживаемым', () {
        final adapter = allAdapters[name]!();
        expect(
          () => adapter.universalRegistration(
            scenario: UniversalScenario.override,
            chainCount: 1,
            nestingDepth: 3,
            bindingMode: UniversalBindingMode.singletonStrategy,
          ),
          throwsUnsupportedError,
          reason: 'контейнер без иерархии обязан отказываться от сценария, '
              'а не подменять его плоским резолвом',
        );
      });
    }
  });
}
```

- [ ] **Step 2: Запустить и убедиться, что падает**

Run: `cd benchmark_di && dart test test/scope_hierarchy_test.dart`
Expected: FAIL на kiwi и yx_scope — они возвращают регистрацию вместо `UnsupportedError`.

- [ ] **Step 3: Заставить kiwi и yx_scope отказываться от override**

В `benchmark_di/lib/di_adapters/kiwi_adapter.dart`, в начало `universalRegistration`, рядом с проверкой async:

```dart
      if (scenario == UniversalScenario.override) {
        throw UnsupportedError(
            'Kiwi не поддерживает иерархию scope: KiwiContainer.scoped() '
            'создаёт независимый контейнер, поэтому сценарий override был бы '
            'плоским резолвом под чужим именем.');
      }
```

В `benchmark_di/lib/di_adapters/yx_scope_adapter.dart` — аналогично:

```dart
      if (scenario == UniversalScenario.override) {
        throw UnsupportedError(
            'yx_scope-адаптер не реализует дочерние scope: openSubScope '
            'возвращает независимый контейнер, сценарий override был бы '
            'плоским резолвом под чужим именем.');
      }
```

- [ ] **Step 4: Сделать override реальным переопределением**

В `benchmark_di/lib/benchmarks/universal_chain_benchmark.dart` заменить ветку `override` в `setup()`:

```dart
      case UniversalScenario.override:
        // Родитель держит всю цепочку; ребёнок переопределяет только
        // последнее звено. Так резолв проходит через границу scope, а не
        // остаётся внутри полной копии графа, как было раньше.
        _di.setupDependencies(_di.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.chain,
        ));
        _childDi = _di.openSubScope('child');
        _childDi!.setupDependencies(_childDi!.universalRegistration(
          chainCount: chainCount,
          nestingDepth: nestingDepth,
          bindingMode: UniversalBindingMode.singletonStrategy,
          scenario: UniversalScenario.override,
        ));
        break;
```

Ветка `case UniversalScenario.override:` в `cherrypick_adapter.dart` уже регистрирует только алиас последнего звена — оставить. В `get_it_adapter.dart` заменить `// handled at benchmark level` на регистрацию алиаса:

```dart
          case UniversalScenario.override:
            final depName = '${chainCount}_$nestingDepth';
            getIt.registerLazySingleton<UniversalService>(
              () => getIt<UniversalService>(instanceName: depName),
            );
            break;
```

и убрать `scenario == UniversalScenario.override` из условия хвостового блока, чтобы алиас не регистрировался дважды. В `riverpod_adapter.dart` аналогично:

```dart
          case UniversalScenario.override:
            final depName = '${chainCount}_$nestingDepth';
            providers['UniversalService'] = rp.Provider<UniversalService>(
                (ref) => ref.watch(
                    providers[depName] as rp.ProviderBase<UniversalService>));
            break;
```

- [ ] **Step 5: Исключить неподдерживающих на уровне CLI**

В `benchmark_di/lib/cli/parser.dart` добавить рядом с существующими константами:

```dart
/// Контейнеры без иерархии scope: сценарий override для них не запускается.
const hierarchyUnsupported = {'kiwi', 'yx_scope'};
```

В `benchmark_di/lib/cli/benchmark_cli.dart` рядом с проверкой `asyncUnsupported`:

```dart
        if (hierarchyUnsupported.contains(config.di) &&
            scenario == UniversalScenario.override) {
          continue;
        }
```

- [ ] **Step 6: Убедиться, что тесты проходят**

Run: `cd benchmark_di && dart test`
Expected: PASS во всех файлах.

- [ ] **Step 7: Проверить, что override теперь идёт через границу scope**

Run: `cd benchmark_di && dart run bin/main.dart --di=cherrypick --benchmark=override --chainCount=10 --nestingDepth=10 --repeat=5 --warmup=2 --resolvePhase=first --format=pretty`
Expected: результат отличается от `chainSingleton` при тех же параметрах — раньше они совпадали.

- [ ] **Step 8: Commit**

```bash
git add benchmark_di/lib benchmark_di/test/scope_hierarchy_test.dart
git commit -m "fix(benchmark_di): override резолвит через границу scope, kiwi/yx_scope отказываются"
```

---

### Task 8: Изоляция процесса на сценарий и честная память

**Files:**
- Modify: `benchmark_di/lib/cli/runner.dart` (baseline RSS)
- Create: `benchmark_di/bin/matrix.dart`
- Create: `benchmark_di/lib/cli/matrix_aggregator.dart`
- Create: `benchmark_di/test/cli/matrix_aggregator_test.dart`

**Interfaces:**
- Consumes: JSON-вывод `bin/main.dart` из Task 2, ключи результата из Task 6.
- Produces:
  - `String aggregateMatrix(List<Map<String, dynamic>> rows, {required String metric})` в `matrix_aggregator.dart` — markdown-таблица «сценарий × DI».
  - Ключ результата `rss_over_baseline_kb`.

- [ ] **Step 1: Написать падающий тест агрегатора**

Создать `benchmark_di/test/cli/matrix_aggregator_test.dart`:

```dart
import 'package:benchmark_di/cli/matrix_aggregator.dart';
import 'package:test/test.dart';

void main() {
  test('строит таблицу сценарий × DI по указанной метрике', () {
    final table = aggregateMatrix([
      {
        'benchmark': 'Universal_chainLazySingleton',
        'di': 'cherrypick',
        'median_ns': '35200.0',
      },
      {
        'benchmark': 'Universal_chainLazySingleton',
        'di': 'getit',
        'median_ns': '116400.0',
      },
      {
        'benchmark': 'Universal_named',
        'di': 'cherrypick',
        'median_ns': '120.0',
      },
    ], metric: 'median_ns');

    expect(table, contains('| Universal_chainLazySingleton | 35200.0 | 116400.0 |'));
    // Отсутствующее измерение помечается прочерком, а не пропускается молча.
    expect(table, contains('| Universal_named | 120.0 | – |'));
  });
}
```

- [ ] **Step 2: Запустить и убедиться, что падает**

Run: `cd benchmark_di && dart test test/cli/matrix_aggregator_test.dart`
Expected: FAIL — файл `matrix_aggregator.dart` не существует.

- [ ] **Step 3: Реализовать агрегатор**

Создать `benchmark_di/lib/cli/matrix_aggregator.dart`:

```dart
/// Сводит результаты отдельных процессов в markdown-таблицу «сценарий × DI».
///
/// Отсутствующие измерения помечаются прочерком: молчаливый пропуск строки
/// однажды уже привёл к публикации числа для сценария, который инструмент
/// выполнить не может.
String aggregateMatrix(
  List<Map<String, dynamic>> rows, {
  required String metric,
}) {
  final scenarios = <String>[];
  final dis = <String>[];
  final cells = <String, String>{};

  for (final row in rows) {
    final scenario = row['benchmark'] as String;
    final di = row['di'] as String;
    if (!scenarios.contains(scenario)) scenarios.add(scenario);
    if (!dis.contains(di)) dis.add(di);
    cells['$scenario|$di'] = row[metric]?.toString() ?? '–';
  }

  final buffer = StringBuffer()
    ..writeln('| Scenario | ${dis.join(' | ')} |')
    ..writeln('|---|${dis.map((_) => '---').join('|')}|');
  for (final scenario in scenarios) {
    final values = dis.map((di) => cells['$scenario|$di'] ?? '–').join(' | ');
    buffer.writeln('| $scenario | $values |');
  }
  return buffer.toString();
}
```

- [ ] **Step 4: Убедиться, что тест проходит**

Run: `cd benchmark_di && dart test test/cli/matrix_aggregator_test.dart`
Expected: PASS.

- [ ] **Step 5: Добавить baseline RSS в результат**

В `benchmark_di/lib/cli/runner.dart`, в `BenchmarkResult`, добавить поле и заполнение:

```dart
  /// RSS процесса до первой регистрации. Пустой Dart-процесс занимает
  /// ~169 MB под VM и JIT-код; без вычитания baseline таблицы памяти
  /// показывают рантайм, а не контейнер.
  final int baselineRssKb;
```

Зафиксировать baseline один раз при старте процесса:

```dart
/// Снимается один раз, до любых регистраций.
final int processBaselineRssKb = (ProcessInfo.currentRss / 1024).round();
```

и в `BenchmarkResult.collect` добавить `baselineRssKb: processBaselineRssKb`.

В `benchmark_di/lib/cli/benchmark_cli.dart` добавить в результат:

```dart
              'baseline_rss_kb': benchResult.baselineRssKb,
              'rss_over_baseline_kb':
                  benchResult.peakRssKb - benchResult.baselineRssKb,
```

- [ ] **Step 6: Написать оркестратор матрицы**

Создать `benchmark_di/bin/matrix.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:benchmark_di/cli/matrix_aggregator.dart';

/// Запускает каждую пару (DI, сценарий) отдельным процессом.
///
/// Изоляция обязательна для памяти: RSS процесса монотонно растёт, поэтому
/// в общем прогоне сценарий наследует пик соседа. Побочно она же снимает
/// зависимость от прогрева JIT предыдущими сценариями.
const dis = ['cherrypick', 'getit', 'riverpod', 'kiwi', 'yx_scope'];
const scenarios = [
  'registerSingleton',
  'registerLazySingleton',
  'chainSingleton',
  'chainLazySingleton',
  'chainFactory',
  'chainAsync',
  'named',
  'override',
];

Future<void> main(List<String> args) async {
  final chainCount = _optionOr(args, '--chainCount', '100');
  final nestingDepth = _optionOr(args, '--nestingDepth', '100');
  final repeat = _optionOr(args, '--repeat', '31');
  final warmup = _optionOr(args, '--warmup', '5');
  final phase = _optionOr(args, '--resolvePhase', 'first');
  final metric = _optionOr(args, '--metric', 'median_ns');
  final executable = _optionOr(args, '--exe', 'dart');

  final rows = <Map<String, dynamic>>[];
  final skipped = <String>[];

  for (final di in dis) {
    for (final scenario in scenarios) {
      final invocation = executable == 'dart'
          ? ['run', 'bin/main.dart']
          : <String>[];
      final result = await Process.run(executable, [
        ...invocation,
        '--di=$di',
        '--benchmark=$scenario',
        '--chainCount=$chainCount',
        '--nestingDepth=$nestingDepth',
        '--repeat=$repeat',
        '--warmup=$warmup',
        '--resolvePhase=$phase',
        '--format=json',
      ]);
      if (result.exitCode != 0) {
        skipped.add('$di/$scenario: exit ${result.exitCode} ${result.stderr}');
        continue;
      }
      final decoded = jsonDecode(result.stdout as String) as List;
      if (decoded.isEmpty) {
        skipped.add('$di/$scenario: сценарий не поддерживается');
        continue;
      }
      rows.addAll(decoded.cast<Map<String, dynamic>>());
    }
  }

  stdout.writeln('# Матрица: $phase, метрика $metric');
  stdout.writeln();
  stdout.writeln('- chainCount=$chainCount, nestingDepth=$nestingDepth, '
      'repeat=$repeat, warmup=$warmup');
  stdout.writeln('- режим: ${executable == 'dart' ? 'JIT' : 'AOT ($executable)'}');
  stdout.writeln('- каждая пара (DI, сценарий) — отдельный процесс');
  stdout.writeln();
  stdout.writeln(aggregateMatrix(rows, metric: metric));
  if (skipped.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('## Не измерено');
    stdout.writeln();
    for (final s in skipped) {
      stdout.writeln('- $s');
    }
  }
}

String _optionOr(List<String> args, String name, String fallback) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return fallback;
}
```

- [ ] **Step 7: Прогнать матрицу**

Run: `cd benchmark_di && dart run bin/matrix.dart --chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5 --resolvePhase=first --metric=median_ns`
Expected: markdown-таблица; в разделе «Не измерено» — `kiwi/chainAsync`, `yx_scope/chainAsync`, `kiwi/override`, `yx_scope/override`.

- [ ] **Step 8: Сверить память отдельным процессом**

Run: `cd benchmark_di && dart run bin/matrix.dart --chainCount=100 --nestingDepth=100 --resolvePhase=first --metric=rss_over_baseline_kb`
Expected: значения на порядок меньше прежних сотен мегабайт; `named` у cherrypick и get_it различаются в пределах единиц процентов, а не на 43%.

- [ ] **Step 9: Commit**

```bash
git add benchmark_di/bin/matrix.dart benchmark_di/lib/cli/matrix_aggregator.dart benchmark_di/lib/cli/runner.dart benchmark_di/lib/cli/benchmark_cli.dart benchmark_di/test/cli/matrix_aggregator_test.dart
git commit -m "feat(benchmark_di): изоляция процесса на сценарий и RSS над baseline"
```

---

### Task 9: Прогон под AOT и фиксация конфигурации cherrypick

Все опубликованные числа сняты под JIT. Целевой рантайм Flutter-приложений — AOT, и переносить одни на другой нельзя.

**Files:**
- Create: `benchmark_di/tool/run_matrix.sh`
- Modify: `benchmark_di/lib/cli/benchmark_cli.dart` (строка окружения в результате)
- Modify: `benchmark_di/README.md`

**Interfaces:**
- Consumes: `bin/matrix.dart` из Task 8.
- Produces: ключи результата `runtime_mode` (`jit`/`aot`) и `cycle_detection` (`on`/`off`); скрипт `tool/run_matrix.sh`, печатающий обе матрицы.

- [ ] **Step 1: Добавить в результат режим исполнения и настройку детектора циклов**

В `benchmark_di/lib/cli/benchmark_cli.dart`, перед циклом, определить:

```dart
    // Фаст-путь cherrypick включается только при silent observer и выключенном
    // детекторе циклов. Это значения по умолчанию, но документация советует
    // детектор включать, поэтому конфигурация обязана попадать в отчёт — и
    // должна управляться флагом, чтобы можно было снять вторую колонку.
    // Читать состояние через CherryPick.openRootScope() нельзя: это создало бы
    // root scope до первого setup() и исказило бы первый замер.
    if (config.cycleDetection) {
      CherryPick.enableGlobalCycleDetection();
    }
    final cycleDetection = config.cycleDetection ? 'on' : 'off';
    // dart compile exe собирает в product-режиме; JIT-прогон через dart run —
    // нет. Для наших целей это и есть различение AOT/JIT.
    const runtimeMode =
        bool.fromEnvironment('dart.vm.product') ? 'aot' : 'jit';
```

и добавить в `results.add({...})`:

```dart
              'runtime_mode': runtimeMode,
              'cycle_detection': cycleDetection,
```

- [ ] **Step 1b: Добавить флаг --cycleDetection**

В `benchmark_di/lib/cli/parser.dart` добавить в `BenchmarkCliConfig` поле
`final bool cycleDetection;` (и `required this.cycleDetection` в конструктор), в `ArgParser`:

```dart
    ..addFlag('cycleDetection',
        defaultsTo: false,
        help: 'Включить глобальный детектор циклов cherrypick перед замером')
```

и в возвращаемую конфигурацию: `cycleDetection: result['cycleDetection'] as bool,`.

Проверить обе колонки:

```bash
cd benchmark_di
dart run bin/main.dart --di=cherrypick --benchmark=chainLazySingleton --chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5 --resolvePhase=first --format=pretty
dart run bin/main.dart --di=cherrypick --benchmark=chainLazySingleton --chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5 --resolvePhase=first --cycleDetection --format=pretty
```

Expected: с включённым детектором медиана заметно выше — это и есть вторая колонка отчёта.

- [ ] **Step 2: Написать скрипт прогона**

Создать `benchmark_di/tool/run_matrix.sh`:

```bash
#!/usr/bin/env bash
# Полный прогон матрицы в обоих режимах компиляции.
# JIT и AOT дают разные числа; публиковать один режим под видом другого нельзя.
set -euo pipefail
cd "$(dirname "$0")/.."

ARGS="--chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5"

echo "## JIT"
dart run bin/matrix.dart $ARGS --resolvePhase=first --metric=median_ns

echo
echo "## AOT"
dart compile exe bin/main.dart -o build/benchmark_di_aot
dart run bin/matrix.dart $ARGS --resolvePhase=first --metric=median_ns \
  --exe=build/benchmark_di_aot
```

Run: `cd benchmark_di && chmod +x tool/run_matrix.sh`

- [ ] **Step 3: Прогнать и сравнить режимы**

Run: `cd benchmark_di && ./tool/run_matrix.sh`
Expected: две таблицы. Записать, сохраняется ли порядок контейнеров при переходе на AOT — если нет, это отдельная находка для отчёта.

- [ ] **Step 4: Задокументировать в README**

Добавить в `benchmark_di/README.md` раздел:

```markdown
## Как получать публикуемые числа

```shell
./tool/run_matrix.sh
```

Скрипт прогоняет каждую пару (DI, сценарий) отдельным процессом в режимах JIT и
AOT. Не сводите таблицы вручную: числа из `--benchmark=all` непригодны для
сравнения памяти, потому что RSS процесса наследуется между сценариями.

Каждая строка результата несёт `runtime_mode` и `cycle_detection`. Отчёт без
этих полей считается недействительным.
```

- [ ] **Step 5: Commit**

```bash
git add benchmark_di/tool/run_matrix.sh benchmark_di/lib/cli/benchmark_cli.dart benchmark_di/README.md
git commit -m "feat(benchmark_di): прогон под AOT и фиксация конфигурации в результате"
```

---

### Task 10: Перегенерация отчётов и снятие недействительных

**Files:**
- Delete: `benchmark_di/REPORT.md`, `benchmark_di/REPORT.ru.md`
- Modify: `benchmark_di/REPORT_v2.md`, `benchmark_di/REPORT_v2.ru.md`
- Modify: `benchmark_di/REPORT_BENCHMARK_COMPARISON.md`
- Create: `benchmark_di/test/reports_test.dart`

**Interfaces:**
- Consumes: вывод `tool/run_matrix.sh` из Task 9.
- Produces: отчёты, содержащие только сгенерированные таблицы плюс обязательный блок методологии.

- [ ] **Step 1: Написать тест на структуру отчётов**

Создать `benchmark_di/test/reports_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final reports = [
    'REPORT_v2.md',
    'REPORT_v2.ru.md',
    'REPORT_BENCHMARK_COMPARISON.md',
  ];

  for (final name in reports) {
    group(name, () {
      final content = File(name).readAsStringSync();

      test('объявляет режим компиляции', () {
        expect(content.toLowerCase(), anyOf(contains('jit'), contains('aot')));
      });

      test('объявляет состояние детектора циклов', () {
        expect(content.toLowerCase(), contains('cycle detection'));
      });

      test('не содержит времён в микросекундах как основной метрики', () {
        expect(content, isNot(contains('Mean time, µs')),
            reason: 'mean неустойчив к выбросам; основная метрика — median в нс');
      });
    });
  }

  test('устаревший REPORT.md удалён', () {
    expect(File('REPORT.md').existsSync(), isFalse,
        reason: 'REPORT.md содержал yx_scope/chainAsync = 87.2 µs — сценарий, '
            'который инструмент выполнить не может');
  });
}
```

- [ ] **Step 2: Запустить и убедиться, что падает**

Run: `cd benchmark_di && dart test test/reports_test.dart`
Expected: FAIL по всем группам.

- [ ] **Step 3: Удалить недействительные отчёты**

```bash
cd benchmark_di && git rm REPORT.md REPORT.ru.md
```

- [ ] **Step 4: Перегенерировать таблицы**

Run: `cd benchmark_di && ./tool/run_matrix.sh > /tmp/matrix.md && cat /tmp/matrix.md`

Полученные таблицы вставить в `REPORT_v2.md` целиком, заменив существующие. Удалить раздел «Peak Memory Usage» в прежнем виде и заменить на таблицу по метрике `rss_over_baseline_kb`, полученную вторым прогоном:

Run: `cd benchmark_di && dart run bin/matrix.dart --chainCount=100 --nestingDepth=100 --resolvePhase=first --metric=rss_over_baseline_kb`

- [ ] **Step 5: Переписать раздел методологии**

Заменить блок «## Methodology» в `REPORT_v2.md`:

```markdown
## Methodology

- **Runtime:** JIT and AOT, reported separately. Numbers from one mode do not
  transfer to the other.
- **cherrypick cycle detection:** off (library default). The `_canUseDirectResolvePath`
  fast path requires a silent observer and disabled cycle detection. With
  `enableGlobalCycleDetection()` the lazy-chain figure roughly doubles.
- **Process isolation:** every (DI, scenario) pair runs in its own process.
  Sharing a process makes RSS of a scenario inherit its neighbour's peak.
- **Timing:** `Stopwatch.elapsedTicks` (nanoseconds). First-resolve measures a
  single resolve per sample; steady-state measures a batch of N resolves and
  divides.
- **Statistics:** median, min, p95 and MAD over 31 samples. Mean is not reported —
  these distributions carry outliers an order of magnitude above the median.
- **Memory:** peak RSS minus the process baseline captured before any
  registration. An empty Dart process occupies ~169 MB.
- **Work equivalence:** `test/equivalence_test.dart` asserts that every container
  constructs the same number of instances on first resolve. A scenario where the
  counts differ is a broken scenario, not a result.
```

Те же правки внести в `REPORT_v2.ru.md`.

- [ ] **Step 6: Пересчитать сравнение веток**

`REPORT_BENCHMARK_COMPARISON.md` сравнивает `BR-improvements` с `develop` числами, снятыми старым аппаратом. Перемерить обе ветки новым инструментом:

```bash
cd benchmark_di
git stash
git checkout develop -- ../cherrypick
./tool/run_matrix.sh > /tmp/develop.md
git checkout HEAD -- ../cherrypick
./tool/run_matrix.sh > /tmp/current.md
git stash pop
```

Заменить таблицы в отчёте полученными. Строки `Named` и `RegisterLazySingleton` из раздела сравнения удалить либо пересчитать в steady-state: под старым аппаратом это были нули, а «18× faster» сравнивало два выброса.

- [ ] **Step 7: Убедиться, что тесты проходят**

Run: `cd benchmark_di && dart test`
Expected: PASS во всех файлах, включая `reports_test.dart`.

- [ ] **Step 8: Прогнать анализатор и форматирование**

Run: `cd benchmark_di && dart analyze && dart format --set-exit-if-changed lib bin test`
Expected: без замечаний.

- [ ] **Step 9: Commit**

```bash
git add -A benchmark_di
git commit -m "docs(benchmark_di): отчёты перегенерированы инструментом, недействительные сняты"
```

---

### Task 11: Документ мотивации изменений

Отдельное требование заказчика: документация бенчмарка должна объяснять, **почему** аппарат
устроен именно так. Без этого следующий человек «упростит» батчи обратно в один вызов и
вернёт таблицу нулей.

**Files:**
- Create: `benchmark_di/METHODOLOGY.md`
- Modify: `benchmark_di/README.md`, `benchmark_di/README.ru.md`
- Create: `benchmark_di/test/methodology_doc_test.dart`

**Interfaces:**
- Consumes: все изменения Task 1–10.
- Produces: `benchmark_di/METHODOLOGY.md` — по разделу на каждое решение, каждый с блоком
  «Что было», «Почему это давало неверный результат», «Как стало».

- [ ] **Step 1: Написать тест на полноту документа**

Создать `benchmark_di/test/methodology_doc_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final doc = File('METHODOLOGY.md');

  test('METHODOLOGY.md существует', () {
    expect(doc.existsSync(), isTrue);
  });

  group('объясняет каждое решение аппарата', () {
    final content = doc.readAsStringSync();

    final requiredTopics = {
      'равный объём работы': 'equivalence_test',
      'разрешение таймера': 'elapsedTicks',
      'батчи steady-state': 'opsPerSample',
      'изоляция процессов': 'matrix.dart',
      'baseline памяти': 'baseline',
      'робастная статистика': 'MAD',
      'иерархия scope': 'override',
      'режим компиляции': 'AOT',
      'детектор циклов': 'cycleDetection',
    };

    requiredTopics.forEach((topic, marker) {
      test('$topic упомянут через $marker', () {
        expect(content, contains(marker),
            reason: 'решение "$topic" не объяснено — следующий читатель '
                'откатит его как усложнение');
      });
    });
  });
}
```

- [ ] **Step 2: Запустить и убедиться, что падает**

Run: `cd benchmark_di && dart test test/methodology_doc_test.dart`
Expected: FAIL — файла нет.

- [ ] **Step 3: Написать METHODOLOGY.md**

Создать `benchmark_di/METHODOLOGY.md` со структурой: вводный абзац о том, что документ
описывает мотивацию, ссылка на аудит `doc/plans/2026-08-20-benchmark-di-audit.md`, затем по
разделу на каждое решение. Каждый раздел строго в три блока:

```markdown
## <Решение>

**Что было.** <прежнее устройство, с указанием файла и строки>

**Почему это давало неверный результат.** <измеренное доказательство: конкретные числа
из аудита>

**Как стало.** <текущее устройство и что сломается, если это откатить>
```

Разделы, обязательные к включению (маркеры проверяет тест из шага 1):
равный объём работы (`equivalence_test`), разрешение таймера (`elapsedTicks`),
батчи steady-state (`opsPerSample`), изоляция процессов (`matrix.dart`),
baseline памяти (`baseline`), робастная статистика (`MAD`), иерархия scope (`override`),
режим компиляции (`AOT`), детектор циклов (`cycleDetection`).

Числа брать из аудита, а не выдумывать: 100 против 10 000 экземпляров, `[0,0,…,0,1,30]`,
494 928 KB у двух соседних сценариев, baseline 169 168 KB, 36.4 против 91.8 µs.

- [ ] **Step 4: Связать с README**

Добавить в `benchmark_di/README.md` сразу после раздела «Overview»:

```markdown
> **Прежде чем менять измерительный аппарат** прочитайте
> [METHODOLOGY.md](METHODOLOGY.md). Каждое решение там объяснено вместе с измерением,
> которое его вызвало. Несколько из них выглядят как усложнение и были откачены бы
> без этого документа.
```

То же самое добавить в `benchmark_di/README.ru.md`.

- [ ] **Step 5: Убедиться, что тесты проходят**

Run: `cd benchmark_di && dart test test/methodology_doc_test.dart`
Expected: PASS, 10 тестов.

- [ ] **Step 6: Полный прогон**

Run: `cd benchmark_di && dart test && dart analyze`
Expected: PASS, без замечаний анализатора.

- [ ] **Step 7: Commit**

```bash
git add benchmark_di/METHODOLOGY.md benchmark_di/README.md benchmark_di/README.ru.md benchmark_di/test/methodology_doc_test.dart
git commit -m "docs(benchmark_di): мотивация каждого решения измерительного аппарата"
```

---

## Что этот план сознательно не чинит

**yx_scope измеряется через динамическую обёртку** (Д7). Штатный API yx_scope требует
статически объявленных полей `Dep<T>`, что несовместимо с параметризацией по chainCount и
nestingDepth. Переписать адаптер под кодогенерацию сценариев — отдельная работа
сопоставимого объёма. До тех пор строки yx_scope во всех таблицах помечаются сноской
«через динамическую обёртку `UniversalYxScopeContainer`, не штатный API». Пометку добавить
в Task 10, шаг 5.

**Абсолютные значения между публикациями.** Даже после всех правок числа сопоставимы только
внутри одного прогона на одной машине. Раздел «Hardware» в отчёте остаётся обязательным.
