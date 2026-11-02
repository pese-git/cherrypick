---
description: Повторить CI CherryPick локально — codegen, analyze, test; с флагом low — ещё и на Flutter 3.38.5
argument-hint: [пакеты через пробел] [low]
---
Запусти **check-runner**. Аргументы: $ARGUMENTS (пакеты — если не указаны, затронутые по `git diff develop...HEAD` и `git status`; `low` — дополнительно прогон на нижней версии матрицы CI).

Покажи пользователю таблицу пакет → версия Flutter → шаг → OK / FAIL / НЕ ЗАПУСКАЛСЯ и ключевые ошибки. Ничего не исправляй без просьбы.
