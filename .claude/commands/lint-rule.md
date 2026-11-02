---
description: Новое или изменённое правило cherrypick_lint — подтверждение поведения генератора и рантайма прогоном, правило, quick fix, тесты, пример и все руководства по линту
argument-hint: <что должно ловить правило>
---
Правило: $ARGUMENTS

Это `/change` для частого случая. Выполни шаги команды `/change` со следующими уточнениями.

На шаге 1 **di-architect** обязан:
- найти, нет ли уже правила, которое ловит это (`cherrypick_lint/lib/src/rules/`);
- подтвердить прогоном, что происходит без правила: `build_test` с `moduleBuilder`/`injectBuilder` для ошибок модулей и аннотаций, тест на `cherrypick` для ловушек рантайма; записать точный вывод;
- определить имя (`snake_case`), severity, сообщение и `correctionMessage` по реальной причине, нужен ли quick fix и однозначен ли он, на каком допустимом коде правило **не** должно срабатывать;
- решить, нужен ли парный `[codegen]` (генератор принимает то, что не должен, или падает непонятно).

Обязательный состав результата (проверь в итоге):
- `lib/src/rules/<name>.dart`, регистрация в `lib/main.dart`, экспорт в `lib/cherrypick_lint.dart`, при необходимости `lib/src/fixes/<name>_fix.dart`;
- `test/rules/<name>_test.dart` — срабатывание, несрабатывание на допустимом коде, граничные случаи, quick fix;
- пример нарушения в `cherrypick_lint/example/`, `fvm dart analyze` в нём показывает правило;
- документация: `cherrypick_lint/README.md`, `doc/lint_en.md`, `doc/lint_ru.md`, `site/src/content/docs/linting.md`, `site/src/content/docs/ru/linting.md`;
- проверка на нижней версии матрицы (Flutter 3.38.5 / analyzer 12.1.0) через check-runner.
