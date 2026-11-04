# CherryPick — инструкции для Claude Code

Monorepo DI-экосистемы для Dart и Flutter на Melos 6 + FVM. Пакеты публикуются на pub.dev и используются другими проектами (например, `structured_log_cherrypick` и Electro), поэтому изменение публичного API ломает не только этот репозиторий.

## Пакеты
| Пакет | Что это | SDK |
|---|---|---|
| `cherrypick` | рантайм DI: скоупы, модули, биндинги, sync/async резолв, детекция циклов, `Disposable`, наблюдатель | `>=3.2.0` |
| `cherrypick_annotations` | `@module`, `@singleton`, `@instance`, `@provide`, `@named`, `@params`, `@inject`… | `>=3.9.0` |
| `cherrypick_generator` | `source_gen`/`build`, пишет `*.module.cherrypick.g.dart`; `analyzer: >=9.0.0 <16.0.0` | `>=3.9.0` |
| `cherrypick_lint` | плагин `analysis_server_plugin`: правила и quick fix'ы; `analyzer: >=12.1.0 <15.0.0` | `>=3.10.0` |
| `cherrypick_flutter` | `CherryPickProvider` | `>=3.2.0`, Flutter `>=3.16.0` |
| `talker_cherrypick_logger` | наблюдатель → Talker | `>=3.2.0` |
| `benchmark_di` | сравнение с get_it, riverpod, kiwi, yx_scope; `publish_to: none` | |
| `examples/*` | `client_app`, `postly`, `market_pulse` | |

Документация: README пакетов, `doc/*_en.md` + `*_ru.md`, сайт `site/` (Astro + Starlight, en в корне, ru в `ru/`, архивные версии через `starlight-versions`). OpenSpec: `openspec/changes/`.

## Правила
- SDK — только через FVM (`.fvmrc`, сейчас 3.47.4). CI гоняет **две** версии Flutter — 3.38.5 и 3.47.4 (`.github/workflows/pipeline.yml`): пакеты заявляют совместимость со старыми SDK, и это проверяется. Не используй языковые возможности новее нижней границы `environment.sdk` пакета; диапазоны `analyzer` у генератора и линта — намеренно широкие, код обязан собираться на обеих границах.
- Melos: `fvm dart run melos bootstrap`, затем `fvm dart run melos run codegen`, `analyze`, `test` (так же, как CI).
- `*.g.dart` не правятся руками и не коммитятся — генерируются `build_runner`.
- Утверждения о поведении генератора, анализатора или чужой библиотеки проверяются прогоном (`build_test`, пробная программа), а не выводятся из документации — так написаны changes `cherrypick-lint-*`.
- Правила `cherrypick_lint` должны совпадать с тем, что реально делает `cherrypick_generator`.
- Документация двуязычная: правка в `*_en.md` — и в `*_ru.md`; страницы сайта — en и `ru/`.
- Скилл для агентов-потребителей — `skills/cherrypick-di/` (`SKILL.md` + `references/`), распространяется плагином через `.claude-plugin/marketplace.json` и `plugin.json`. Пишется **только на английском** (исключение из правила двуязычия). Изменение публичного API, поведения рантайма, вывода генератора или правил линта — обновить и скилл; примеры в нём проверяются прогоном (пробный проект с `build_runner`), а не выводятся из документации. Проверка манифестов: `claude plugin validate .`.
- `CHANGELOG.md` пишет `melos version` по коммитам; руками не править без явного решения.
- Коммиты — Conventional Commits, `scope` — имя пакета (`feat(cherrypick_generator): …`), описание по-русски, как в истории. Теги — `<package>-v<version>`.
- Ветки — **git flow**: `master` — только выпущенное, `develop` — интеграционная.
  - `feature/<имя>` (любая задача: фичи, документация, chore) и `bugfix/<имя>` — от `develop`, PR в `develop`.
  - `release/<версия>` (например, `release/4.1.0` по версии `cherrypick`) — от `develop`; в ней только `melos version`, исправления к релизу и документация. PR в `master` **merge-коммитом** (без squash/rebase — теги `melos version` должны остаться достижимыми из `master`), затем `master` вливается обратно в `develop`.
  - `hotfix/<версия>` — от `master`, PR в `master` merge-коммитом, затем обратно в `develop`.
  - Базовая ветка для diff/ревью: `develop`, для `hotfix/*` — `master`. Напрямую в `develop`/`master` не коммитить.
- Без явной просьбы: не делать `git commit`/`push`, не открывать PR, не запускать `melos version` и `pub publish`.

## Команда субагентов (`.claude/agents/`)
| Агент | Зона | Пишет код |
|---|---|---|
| `di-architect` | OpenSpec change, проверочные прогоны | `openspec/` |
| `core-engineer` | `cherrypick` | да |
| `codegen-engineer` | `cherrypick_annotations`, `cherrypick_generator` | да |
| `lint-engineer` | `cherrypick_lint` | да |
| `integrations-engineer` | `cherrypick_flutter`, `talker_cherrypick_logger`, `examples/*` | да |
| `benchmark-engineer` | `benchmark_di` | да |
| `docs-engineer` | README, `doc/`, `site/`, руководства по миграции, скилл `skills/cherrypick-di/` | документы |
| `check-runner` | codegen, analyze, test на одной или двух версиях Flutter | нет |
| `code-reviewer` | семантика DI, паритет линта и генератора, тесты | нет |
| `api-reviewer` | публичный API, semver, совместимость SDK и analyzer, потребители | нет |
| `release-manager` | версии, теги, порядок публикации | после подтверждения |

Команды: `/change`, `/implement <change-id>`, `/lint-rule`, `/review`, `/check`, `/release`.
