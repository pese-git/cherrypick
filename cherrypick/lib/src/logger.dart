//
// Copyright 2021 Sergey Penkovsky (sergey.penkovsky@gmail.com)
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/// ----------------------------------------------------------------------------
/// CherryPickLogger — интерфейс для логирования событий DI в CherryPick.
///
/// ENGLISH:
/// Interface for dependency injection (DI) logger in CherryPick. Allows you to
/// receive information about the internal events and errors in the DI system.
/// Your implementation can use any logging framework or UI.
///
/// RUSSIAN:
/// Интерфейс логгера для DI-контейнера CherryPick. Позволяет получать
/// сообщения о работе DI-контейнера, его ошибках и событиях, и
/// интегрировать любые готовые решения для логирования/сбора ошибок.
/// ----------------------------------------------------------------------------
abstract class CherryPickLogger {
  /// ----------------------------------------------------------------------------
  /// info — Информационное сообщение.
  ///
  /// ENGLISH:
  /// Logs an informational message about DI operation or state.
  ///
  /// RUSSIAN:
  /// Логирование информационного сообщения о событиях DI.
  /// ----------------------------------------------------------------------------
  void info(String message);

  /// ----------------------------------------------------------------------------
  /// warn — Предупреждение.
  ///
  /// ENGLISH:
  /// Logs a warning related to DI events (for example, possible misconfiguration).
  ///
  /// RUSSIAN:
  /// Логирование предупреждения, связанного с DI (например, возможная ошибка
  /// конфигурации).
  /// ----------------------------------------------------------------------------
  void warn(String message);

  /// ----------------------------------------------------------------------------
  /// error — Ошибка.
  ///
  /// ENGLISH:
  /// Logs an error message, may include error object and stack trace.
  ///
  /// RUSSIAN:
  /// Логирование ошибки, дополнительно может содержать объект ошибки
  /// и StackTrace.
  /// ----------------------------------------------------------------------------
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// ----------------------------------------------------------------------------
/// SilentLogger — «тихий» логгер CherryPick. Сообщения игнорируются.
///
/// ENGLISH:
/// SilentLogger ignores all log messages. Used by default in production to
/// avoid polluting logs with DI events.
///
/// RUSSIAN:
/// SilentLogger игнорирует все события логгирования. Используется по умолчанию
/// на production, чтобы не засорять логи техническими сообщениями DI.
/// ----------------------------------------------------------------------------
class SilentLogger implements CherryPickLogger {
  const SilentLogger();
  @override
  void info(String message) {}
  @override
  void warn(String message) {}
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

/// ----------------------------------------------------------------------------
/// PrintLogger — логгер CherryPick, выводящий все сообщения через print.
///
/// ENGLISH:
/// PrintLogger outputs all log messages to the console using `print()`.
/// Suitable for debugging, prototyping, or simple console applications.
///
/// RUSSIAN:
/// PrintLogger выводит все сообщения (info, warn, error) в консоль через print.
/// Удобен для отладки или консольных приложений.
/// ----------------------------------------------------------------------------
class PrintLogger implements CherryPickLogger {
  const PrintLogger();
  @override
  void info(String message) => print('[info][CherryPick] $message');
  @override
  void warn(String message) => print('[warn][CherryPick] $message');
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[error][CherryPick] $message');
    if (error != null) print('  error: $error');
    if (stackTrace != null) print('  stack: $stackTrace');
  }
}
