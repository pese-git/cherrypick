# Как воспроизвести замеры

Все таблицы в [REPORT_v2.md](REPORT_v2.md) и
[REPORT_BENCHMARK_COMPARISON.md](REPORT_BENCHMARK_COMPARISON.md) получены
командами из этого документа. Ничего не сводилось вручную.

Почему аппарат устроен именно так — [METHODOLOGY.md](METHODOLOGY.md). Здесь
только процедура.

---

## 1. Окружение

```shell
dart --version
```

Опубликованные числа сняты на Dart 3.11.5 (stable), macOS arm64, локальная
машина без нагрузки. Версия SDK влияет на абсолютные значения; относительный
порядок контейнеров устойчив.

Измеряется локальный пакет cherrypick по `path: ../cherrypick`, а не версия с
pub.dev. Проверьте, какое состояние вы меряете:

```shell
git -C .. log --oneline -1 -- cherrypick/lib
```

Установка зависимостей:

```shell
cd benchmark_di
dart pub get
```

Перед прогоном закройте то, что грузит процессор. Замеры идут в наносекундах,
и фоновая сборка в соседнем окне видна в результатах.

---

## 2. Сначала проверьте, что аппарат исправен

```shell
dart test
```

Ожидается 55 зелёных тестов. Это не формальность — три из них защищают
результаты от типовых искажений:

- `equivalence_test.dart` — все контейнеры строят одинаковое число экземпляров
  при первом резолве. Если он красный, любое сравнение времени недействительно:
  контейнеры решают разные задачи.
- `scope_hierarchy_test.dart` — контейнеры без иерархии scope отказываются от
  сценария `override`, а не подменяют его плоским резолвом.
- `runner_resolution_test.dart` — быстрая операция не измеряется нулями.

Красный `equivalence_test` — стоп. Не публикуйте числа, пока он не зелёный.

---

## 3. Полный прогон

Одна команда даёт обе таблицы первого резолва — JIT и AOT:

```shell
./tool/run_matrix.sh
```

Занимает около 51 секунды: 40 пар (DI, сценарий) в каждом режиме, каждая —
отдельный процесс. Компиляция AOT-бинаря входит в это время.

Вывод — готовый markdown. Хвост «Не измерено» перечисляет пропуски с причиной:
kiwi и yx_scope не поддерживают асинхронные привязки и иерархию scope, поэтому
`chainAsync` и `override` для них отсутствуют. Пустая ячейка в таблице всегда
объясняется в этом разделе; молча ничего не исчезает.

---

## 4. Остальные таблицы отчёта

Скрипт покрывает только первый резолв. Три оставшиеся таблицы снимаются
отдельно — все на AOT-бинаре, собранном на шаге 3.

**Память** (пик RSS над baseline процесса):

```shell
dart run bin/matrix.dart --chainCount=100 --nestingDepth=100 \
  --repeat=31 --warmup=5 --resolvePhase=first \
  --metric=rss_over_baseline_kb --exe=build/benchmark_di_aot
```

**Установившийся режим** (наносекунды на один резолв, пачками по 1000):

```shell
dart run bin/matrix.dart --chainCount=100 --nestingDepth=100 \
  --repeat=31 --warmup=5 --resolvePhase=steady \
  --metric=median_ns --exe=build/benchmark_di_aot
```

**Цена детектора циклов** — по одному прогону на сценарий, с флагом и без:

```shell
for b in registerLazySingleton chainSingleton chainLazySingleton \
         chainFactory chainAsync named override; do
  printf "%-22s " $b
  ./build/benchmark_di_aot --di=cherrypick --benchmark=$b \
    --chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5 \
    --resolvePhase=first --format=json |
    python3 -c "import sys,json;print(json.load(sys.stdin)[0]['median_ns'])"
done
```

Повторите с `--cycleDetection`, чтобы получить вторую колонку.

---

## 5. Как читать одну строку результата

```shell
dart run bin/main.dart --di=cherrypick --benchmark=chainLazySingleton \
  --chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5 \
  --resolvePhase=first --format=json
```

| Поле | Что означает |
|---|---|
| `median_ns` | Основная метрика. Медиана по 31 сэмплу |
| `min_ns` | Самый быстрый сэмпл — ближе всего к стоимости без шума планировщика |
| `p95_ns` | 95-й перцентиль |
| `mad_ns` | Медианное абсолютное отклонение. Растёт от реального разброса, а не от одного промаха |
| `ops_per_sample` | Резолвов в одном замере: 1 в фазе first, 1000 в steady |
| `rss_over_baseline_kb` | Пик RSS минус baseline процесса |
| `runtime_mode` | `jit` или `aot` |
| `cycle_detection` | `on` или `off` |

Среднего и stddev в выводе нет намеренно — в этих распределениях они описывают
самый неудачный замер.

Строка без `runtime_mode` и `cycle_detection` считается недействительной: без
них неизвестно, что именно измерено. `test/reports_test.dart` требует, чтобы
отчёты объявляли оба.

---

## 6. Какой разброс считать нормальным

Сверка независимого прогона с опубликованными числами (JIT, медиана, нс):

| Сценарий | контейнер | опубликовано | повтор | расхождение |
|---|---|---|---|---|
| chainLazySingleton | kiwi | 30334 | 30416 | 0.3% |
| chainLazySingleton | riverpod | 215959 | 219833 | 1.8% |
| chainLazySingleton | yx_scope | 69875 | 67875 | 2.9% |
| chainLazySingleton | getit | 103041 | 96625 | 6.2% |
| chainLazySingleton | cherrypick | 29083 | 27000 | 7.2% |
| named | cherrypick | 833 | 791 | 5.0% |
| named | yx_scope | 1917 | 1375 | 28% |
| chainSingleton | cherrypick | 4792 | 1792 | 2.7× |

Правило: **чем дешевле сценарий, тем шире разброс.** Глубокие цепочки
(десятки микросекунд) воспроизводятся в пределах 10%. Сценарии дешевле
нескольких микросекунд — `chainSingleton`, `named`, `register*` — могут
разойтись в разы между прогонами, потому что там мерится один резолв на сэмпл.

Отсюда практическое следствие: выводы стройте на `chainLazySingleton`,
`chainFactory` и `chainAsync`. Дешёвые сценарии смотрите в фазе steady-state,
где считается пачка из 1000 резолвов и разброс на порядок меньше.

Разница в 2× на дешёвом сценарии между двумя прогонами — это шум, а не
регрессия. Разница в 2× на `chainLazySingleton` — уже сигнал.

---

## 7. Сравнить две версии cherrypick

Так получена таблица в REPORT_BENCHMARK_COMPARISON.md. Меняется только
`cherrypick/lib`, бенчмарк остаётся тем же.

```shell
cd ..                       # корень репозитория
git status --short          # рабочее дерево должно быть чистым

# состояние "после"
cd benchmark_di
dart compile exe bin/main.dart -o build/after

# состояние "до"
cd ..
git checkout <sha-до> -- cherrypick/lib
cd benchmark_di
dart compile exe bin/main.dart -o build/before

# вернуть исходники немедленно, до замеров
cd ..
git checkout HEAD -- cherrypick/lib
git status --short cherrypick    # должно быть пусто
cd benchmark_di
```

Оба бинаря собраны — исходники можно возвращать сразу, AOT-сборка уже не
зависит от рабочего дерева. Дальше меряйте:

```shell
for exe in before after; do
  printf "%-8s " $exe
  ./build/$exe --di=cherrypick --benchmark=chainLazySingleton \
    --chainCount=100 --nestingDepth=100 --repeat=31 --warmup=5 \
    --resolvePhase=first --format=json |
    python3 -c "import sys,json;print(json.load(sys.stdin)[0]['median_ns'])"
done
```

Коммит до оптимизаций резолвера — `f82b96c` (родитель `d61ff7c`, где появился
`_canUseDirectResolvePath`).

---

## 8. Частые ошибки

**Короткие флаги через знак равенства.** `-c=100` пакет `args` разбирает как
значение `"=100"`. Раньше это давало пустую таблицу и код возврата 0; теперь —
ошибку и `exit 64`. Пишите `-c 100` или `--chainCount=100`.

**Сведение таблиц из `--benchmark=all`.** Так делать нельзя: все сценарии идут
в одном процессе, RSS монотонно растёт, и память сценария наследует пик
соседнего. Именно отсюда взялась цифра «cherrypick экономнее на 210 MB» в
прежней редакции отчёта. Для публикуемых чисел — только `matrix.dart`.

**Сравнение JIT-чисел с AOT-числами.** Режим переставляет контейнеры местами:
riverpod под JIT последний на всех цепочках, под AOT обгоняет get_it. Сравнивать
можно только внутри одного режима.

**Сравнение между машинами и публикациями.** Числа сопоставимы внутри одного
прогона. Для сравнения с чужим результатом воспроизведите обе стороны у себя.

**Один прогон как основание для вывода.** Прогоните дважды. Если расхождение
на глубоких цепочках больше 10%, машина занята чем-то ещё.

---

## 9. Если числа не сходятся с отчётом

По порядку:

1. `dart test` — зелёный? Красный `equivalence_test` объясняет почти любое
   расхождение: контейнеры строят разные графы.
2. Тот же ли режим компиляции? Сверьте `runtime_mode` в JSON с заголовком
   таблицы в отчёте.
3. То же ли состояние детектора циклов? `cycle_detection` в JSON против
   заголовка таблицы.
4. Та же ли версия cherrypick? `git -C .. log --oneline -1 -- cherrypick/lib`.
5. Дешёвый ли это сценарий? Смотрите таблицу разброса в разделе 6 — на
   `chainSingleton` и `named` расхождение в разы ожидаемо.
6. Занята ли машина? Повторите прогон.

Если после этого расхождение на `chainLazySingleton` остаётся больше 10% —
это находка, а не шум. Приложите вывод `--format=json` целиком: в нём есть все
сэмплы (`timings_ns`), по которым видно, выброс это или сдвиг распределения.
