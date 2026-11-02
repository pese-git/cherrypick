---
title: Пакеты и ресурсы
description: Пакеты CherryPick, расширенные руководства и исходный код.
---

## Пакеты

| Пакет | Описание |
|-------|----------|
| [**cherrypick**](https://pub.dev/packages/cherrypick) | Ядро DI: скоупы, модули, биндинги, освобождение ресурсов, обнаружение циклов. |
| [**cherrypick_flutter**](https://pub.dev/packages/cherrypick_flutter) | Интеграция с Flutter: `CherryPickProvider` открывает доступ к DI-скоупам из дерева виджетов. |
| [**cherrypick_annotations**](https://pub.dev/packages/cherrypick_annotations) | Аннотации Dart для лаконичного описания DI и кодогенерации. |
| [**cherrypick_generator**](https://pub.dev/packages/cherrypick_generator) | Генератор для `build_runner`, создающий DI-биндинги по аннотациям. |
| [**talker_cherrypick_logger**](https://pub.dev/packages/talker_cherrypick_logger) | Логирует события, ошибки и диагностику DI через [Talker](https://pub.dev/packages/talker) — в UI и в консоли. |
| [**cherrypick_lint**](https://pub.dev/packages/cherrypick_lint) | Плагин анализатора, который ловит неверное использование API — пропущенный `await` при закрытии скоупа, некорректные аннотации, рантайм-ловушки — в IDE и в `dart analyze`. См. [Линтинг](/ru/linting/). |

## Расширенные руководства в репозитории

- [Полный туториал](https://github.com/pese-git/cherrypick/blob/master/doc/full_tutorial_ru.md)
- [Аннотации и кодогенерация](https://github.com/pese-git/cherrypick/blob/master/doc/annotations_ru.md)
- [Обнаружение циклических зависимостей](https://github.com/pese-git/cherrypick/blob/master/doc/cycle_detection.ru.md)
- [Миграция на 4.0.0](https://github.com/pese-git/cherrypick/blob/master/doc/migration_4.0.0_ru.md)
- [README lint-плагина](https://github.com/pese-git/cherrypick/blob/master/cherrypick_lint/README.md)

## Исходный код

- [Репозиторий на GitHub](https://github.com/pese-git/cherrypick)
- [Список изменений](https://github.com/pese-git/cherrypick/blob/master/CHANGELOG.md)
