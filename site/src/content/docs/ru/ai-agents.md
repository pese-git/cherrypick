---
title: ИИ-агенты для кода
description: Скилл cherrypick-di знакомит агентов с API CherryPick 4.x.
---

Агенты для написания кода часто знают более старый API CherryPick, чем тот, что у вас: в 4.0.0
изменились typedef'ы провайдеров и `toProvideAsync`, а у генератора есть правила, которые легко
упустить. Скилл [`cherrypick-di`](https://github.com/pese-git/cherrypick/tree/master/skills/cherrypick-di)
даёт агенту актуальное и проверенное описание CherryPick — код, который он пишет, компилируется,
правильно резолвится и проходит [`cherrypick_lint`](/ru/linting/).

Скилл оформлен в открытом формате [Agent Skills](https://agentskills.io): файл `SKILL.md` с
короткими правилами и файлы `references/`, которые агент открывает, только когда они нужны для задачи.

## Что входит в скилл

| Файл | Тема |
|------|------|
| `SKILL.md` | Когда применять, пакеты и версии, десять основных правил, минимальный пример |
| `references/runtime.md` | Скоупы, виды биндингов, async, params, именованные биндинги, порядок освобождения, обнаружение циклов, наблюдатели, тесты |
| `references/codegen.md` | `@module`, `@provide`, `@instance`, `@injectable`, `@inject`, что генерирует генератор, его ошибки |
| `references/flutter.md` | `CherryPickProvider`, скоуп на экран или фичу, логирование через Talker |
| `references/pitfalls.md` | Все правила `cherrypick_lint` и другие ошибки, которые стоит искать на ревью |
| `references/migration-4.md` | Переход с 3.x на 4.0.0 |

Агент подключает скилл сам, когда проект зависит от пакета `cherrypick*` или в задаче упоминаются
CherryPick, скоупы, модули или аннотации CherryPick.

## Claude Code

Репозиторий CherryPick — это ещё и маркетплейс плагинов Claude Code. Выполните в Claude Code:

```text
/plugin marketplace add pese-git/cherrypick
/plugin install cherrypick-di@cherrypick
```

После этого скилл появится как `cherrypick-di:cherrypick-di`. Чтобы позже получить новую версию,
обновите маркетплейс и плагин в меню `/plugin` или из терминала:

```bash
claude plugin marketplace update cherrypick
claude plugin update cherrypick-di@cherrypick
```

Без системы плагинов можно просто скопировать папку:

- для одного проекта — в `.claude/skills/cherrypick-di/` этого проекта (закоммитьте её, чтобы скилл был у всей команды);
- для всех своих проектов — в `~/.claude/skills/cherrypick-di/`.

## Другие агенты

Любой агент с поддержкой Agent Skills может использовать ту же папку. Скопируйте
[`skills/cherrypick-di`](https://github.com/pese-git/cherrypick/tree/master/skills/cherrypick-di)
в каталог скиллов, который читает ваш агент, — где он находится, смотрите в документации агента.

Агенты без поддержки скиллов тоже могут пользоваться этими файлами: сошлитесь на `SKILL.md` в файле
инструкций (например, `AGENTS.md`), и агент сам прочитает нужные справочники.

## Как проверить, что скилл работает

Попросите агента о том, на что отвечает скилл, например: *«Добавь скоуп фичи с асинхронным
биндингом базы данных и правильно закрой его»*. Ответ с `toProvideAsync`, `resolveAsync<T>()` и
`await CherryPick.closeScope(...)` — это скилл; синхронное замыкание в `toProvideAsync` или
пропущенный `await` — признак, что скилл не подключился.

## Вместе с линтером

Скилл помогает агенту писать правильный код, а [`cherrypick_lint`](/ru/linting/) проверяет
результат в IDE и в `dart analyze`. Включите оба: `references/pitfalls.md` в скилле повторяет
правила линта, так что агент сможет и объяснить любое предупреждение.
