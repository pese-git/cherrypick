---
sidebar_position: 2
---

# Логирование

CherryPick позволяет логировать все события и ошибки DI с помощью расширяемого observer-механизма.

## Кастомные Observer'ы

Вы можете передавать свою реализацию `CherryPickObserver` в root- или любой подскоуп.
Это позволяет централизовать и настраивать логирование, направлять логи в консоль, файл, сторонние сервисы или системы как [Talker](https://pub.dev/packages/talker).

### Пример: вывод всех событий в консоль

```dart
import 'package:cherrypick/cherrypick.dart';

void main() {
  // Встроенный PrintCherryPickObserver для консоли
  final observer = PrintCherryPickObserver();
  final scope = CherryPick.openRootScope(observer: observer);
  // Все события и ошибки DI будут выведены!
}
```

### Пример: расширенное логирование через Talker

Для более гибкого логирования или UI-оверлеев можно использовать observer наподобие [talker_cherrypick_logger](../talker_cherrypick_logger):

```dart
import 'package:cherrypick/cherrypick.dart';
import 'package:talker/talker.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';

void main() {
  final talker = Talker();
  final observer = TalkerCherryPickObserver(talker);
  CherryPick.openRootScope(observer: observer);
  // Все события попадают в Talker!
}
```

## Поведение по умолчанию
- По умолчанию логирование "тихое" (SilentCherryPickObserver) для production — нет вывода без observer'а.
- Можно назначить observer для любого скоупа.

## Возможности Observer'а

- Регистрация зависимостей
- Получение/создание/удаление экземпляров
- Установка/удаление модулей
- Открытие/закрытие скоупов
- Кэш-хиты/мимо
- Обнаружение циклов
- Диагностика, предупреждения, ошибки

## Когда применять

- Подробное логирование в dev/test окружениях
- Передача логов в основную систему/аналитику
- Отладка и профилирование DI
