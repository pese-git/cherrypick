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
import 'package:cherrypick/src/scope.dart';
import 'package:cherrypick/src/global_cycle_detector.dart';
import 'package:cherrypick/src/logger.dart';
import 'package:meta/meta.dart';

CherryPickLogger? _globalLogger = const SilentLogger();

Scope? _rootScope;
bool _globalCycleDetectionEnabled = false;
bool _globalCrossScopeCycleDetectionEnabled = false;

class CherryPick {
  /// Позволяет задать глобальный логгер для всей DI-системы.
  /// ----------------------------------------------------------------------------
  /// setGlobalLogger — установка глобального логгера для всей системы CherryPick DI.
  ///
  /// ENGLISH:
  /// Sets the global logger for all CherryPick DI containers and scopes.
  /// All dependency resolution, scope lifecycle, and error events will use
  /// this logger instance for info/warn/error output.
  /// Can be used to connect a custom logger (e.g. to external monitoring or UI).
  ///
  /// Usage example:
  /// ```dart
  /// import 'package:cherrypick/cherrypick.dart';
  ///
  /// void main() {
  ///   CherryPick.setGlobalLogger(PrintLogger()); // Or your custom logger
  ///   final rootScope = CherryPick.openRootScope();
  ///   // DI logs and errors will now go to your logger
  /// }
  /// ```
  ///
  /// RUSSIAN:
  /// Устанавливает глобальный логгер для всей DI-системы CherryPick.
  /// Все операции разрешения зависимостей, жизненного цикла скоупов и ошибки
  /// будут регистрироваться через этот логгер (info/warn/error).
  /// Можно подключить свою реализацию для интеграции со сторонними системами.
  ///
  /// Пример использования:
  /// ```dart
  /// import 'package:cherrypick/cherrypick.dart';
  ///
  /// void main() {
  ///   CherryPick.setGlobalLogger(PrintLogger()); // Или ваш собственный логгер
  ///   final rootScope = CherryPick.openRootScope();
  ///   // Все события DI и ошибки попадут в ваш логгер.
  /// }
  /// ```
  /// ----------------------------------------------------------------------------
  static void setGlobalLogger(CherryPickLogger logger) {
    _globalLogger = logger;
  }

  /// RU: Метод открывает главный [Scope].
  /// ENG: The method opens the main [Scope].
  ///
  /// return
  static Scope openRootScope() {
    _rootScope ??= Scope(null, logger: _globalLogger);
    // Применяем глобальную настройку обнаружения циклических зависимостей
    if (_globalCycleDetectionEnabled && !_rootScope!.isCycleDetectionEnabled) {
      _rootScope!.enableCycleDetection();
    }
    // Применяем глобальную настройку обнаружения между скоупами
    if (_globalCrossScopeCycleDetectionEnabled && !_rootScope!.isGlobalCycleDetectionEnabled) {
      _rootScope!.enableGlobalCycleDetection();
    }
    return _rootScope!;
  }

  /// RU: Метод закрывает главный [Scope].
  /// ENG: The method close the main [Scope].
  ///
  ///
  static void closeRootScope() {
    if (_rootScope != null) {
      _rootScope = null;
    }
  }

  /// RU: Глобально включает обнаружение циклических зависимостей для всех новых скоупов.
  /// ENG: Globally enables circular dependency detection for all new scopes.
  ///
  /// Этот метод влияет на все скоупы, создаваемые через CherryPick.
  /// This method affects all scopes created through CherryPick.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.enableGlobalCycleDetection();
  /// final scope = CherryPick.openRootScope(); // Автоматически включено обнаружение
  /// ```
  static void enableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = true;
    
    // Включаем для уже существующего root scope, если он есть
    if (_rootScope != null) {
      _rootScope!.enableCycleDetection();
    }
  }

  /// RU: Глобально отключает обнаружение циклических зависимостей.
  /// ENG: Globally disables circular dependency detection.
  ///
  /// Рекомендуется использовать в production для максимальной производительности.
  /// Recommended for production use for maximum performance.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.disableGlobalCycleDetection();
  /// ```
  static void disableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = false;
    
    // Отключаем для уже существующего root scope, если он есть
    if (_rootScope != null) {
      _rootScope!.disableCycleDetection();
    }
  }

  /// RU: Проверяет, включено ли глобальное обнаружение циклических зависимостей.
  /// ENG: Checks if global circular dependency detection is enabled.
  ///
  /// return true если включено, false если отключено
  /// return true if enabled, false if disabled
  static bool get isGlobalCycleDetectionEnabled => _globalCycleDetectionEnabled;

  /// RU: Включает обнаружение циклических зависимостей для конкретного скоупа.
  /// ENG: Enables circular dependency detection for a specific scope.
  ///
  /// [scopeName] - имя скоупа (пустая строка для root scope)
  /// [scopeName] - scope name (empty string for root scope)
  ///
  /// Example:
  /// ```dart
  /// CherryPick.enableCycleDetectionForScope(); // Для root scope
  /// CherryPick.enableCycleDetectionForScope(scopeName: 'feature.auth'); // Для конкретного scope
  /// ```
  static void enableCycleDetectionForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    scope.enableCycleDetection();
  }

  /// RU: Отключает обнаружение циклических зависимостей для конкретного скоупа.
  /// ENG: Disables circular dependency detection for a specific scope.
  ///
  /// [scopeName] - имя скоупа (пустая строка для root scope)
  /// [scopeName] - scope name (empty string for root scope)
  static void disableCycleDetectionForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    scope.disableCycleDetection();
  }

  /// RU: Проверяет, включено ли обнаружение циклических зависимостей для конкретного скоупа.
  /// ENG: Checks if circular dependency detection is enabled for a specific scope.
  ///
  /// [scopeName] - имя скоупа (пустая строка для root scope)
  /// [scopeName] - scope name (empty string for root scope)
  ///
  /// return true если включено, false если отключено
  /// return true if enabled, false if disabled
  static bool isCycleDetectionEnabledForScope({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    return scope.isCycleDetectionEnabled;
  }

  /// RU: Возвращает текущую цепочку разрешения зависимостей для конкретного скоупа.
  /// ENG: Returns current dependency resolution chain for a specific scope.
  ///
  /// Полезно для отладки и анализа зависимостей.
  /// Useful for debugging and dependency analysis.
  ///
  /// [scopeName] - имя скоупа (пустая строка для root scope)
  /// [scopeName] - scope name (empty string for root scope)
  ///
  /// return список имен зависимостей в текущей цепочке разрешения
  /// return list of dependency names in current resolution chain
  static List<String> getCurrentResolutionChain({String scopeName = '', String separator = '.'}) {
    final scope = _getScope(scopeName, separator);
    return scope.currentResolutionChain;
  }

  /// RU: Создает новый скоуп с автоматически включенным обнаружением циклических зависимостей.
  /// ENG: Creates a new scope with automatically enabled circular dependency detection.
  ///
  /// Удобный метод для создания безопасных скоупов в development режиме.
  /// Convenient method for creating safe scopes in development mode.
  ///
  /// Example:
  /// ```dart
  /// final scope = CherryPick.openSafeRootScope();
  /// // Обнаружение циклических зависимостей автоматически включено
  /// ```
  static Scope openSafeRootScope() {
    final scope = openRootScope();
    scope.enableCycleDetection();
    return scope;
  }

  /// RU: Создает новый дочерний скоуп с автоматически включенным обнаружением циклических зависимостей.
  /// ENG: Creates a new child scope with automatically enabled circular dependency detection.
  ///
  /// [scopeName] - имя скоупа
  /// [scopeName] - scope name
  ///
  /// Example:
  /// ```dart
  /// final scope = CherryPick.openSafeScope(scopeName: 'feature.auth');
  /// // Обнаружение циклических зависимостей автоматически включено
  /// ```
  static Scope openSafeScope({String scopeName = '', String separator = '.'}) {
    final scope = openScope(scopeName: scopeName, separator: separator);
    scope.enableCycleDetection();
    return scope;
  }

  /// RU: Внутренний метод для получения скоупа по имени.
  /// ENG: Internal method to get scope by name.
  static Scope _getScope(String scopeName, String separator) {
    if (scopeName.isEmpty) {
      return openRootScope();
    }
    return openScope(scopeName: scopeName, separator: separator);
  }

  /// RU: Метод открывает  дочерний [Scope].
  /// ENG: The method open the child [Scope].
  ///
  /// Дочерний [Scope] открывается с [scopeName]
  /// Child [Scope] open with [scopeName]
  ///
  /// Example:
  /// ```
  /// final String scopeName = 'firstScope.secondScope';
  /// final subScope = CherryPick.openScope(scopeName);
  /// ```
  ///
  ///
  @experimental
  static Scope openScope({String scopeName = '', String separator = '.'}) {
    if (scopeName.isEmpty) {
      return openRootScope();
    }

    final nameParts = scopeName.split(separator);
    if (nameParts.isEmpty) {
      throw Exception('Can not open sub scope because scopeName can not split');
    }

    final scope = nameParts.fold(
        openRootScope(),
        (Scope previousValue, String element) =>
            previousValue.openSubScope(element));
    
    // Применяем глобальную настройку обнаружения циклических зависимостей
    if (_globalCycleDetectionEnabled && !scope.isCycleDetectionEnabled) {
      scope.enableCycleDetection();
    }
    
    // Применяем глобальную настройку обнаружения между скоупами
    if (_globalCrossScopeCycleDetectionEnabled && !scope.isGlobalCycleDetectionEnabled) {
      scope.enableGlobalCycleDetection();
    }
    
    return scope;
  }

  /// RU: Метод открывает  дочерний [Scope].
  /// ENG: The method open the child [Scope].
  ///
  /// Дочерний [Scope] открывается с [scopeName]
  /// Child [Scope] open with [scopeName]
  ///
  /// Example:
  /// ```
  /// final String scopeName = 'firstScope.secondScope';
  /// final subScope = CherryPick.closeScope(scopeName);
  /// ```
  ///
  ///
  @experimental
  static void closeScope({String scopeName = '', String separator = '.'}) {
    if (scopeName.isEmpty) {
      closeRootScope();
    }

    final nameParts = scopeName.split(separator);
    if (nameParts.isEmpty) {
      throw Exception(
          'Can not close sub scope because scopeName can not split');
    }

    if (nameParts.length > 1) {
      final lastPart = nameParts.removeLast();

      final scope = nameParts.fold(
          openRootScope(),
          (Scope previousValue, String element) =>
              previousValue.openSubScope(element));
      scope.closeSubScope(lastPart);
    } else {
      openRootScope().closeSubScope(nameParts[0]);
    }
  }

  /// RU: Глобально включает обнаружение циклических зависимостей между скоупами.
  /// ENG: Globally enables cross-scope circular dependency detection.
  ///
  /// Этот режим обнаруживает циклические зависимости во всей иерархии скоупов.
  /// This mode detects circular dependencies across the entire scope hierarchy.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.enableGlobalCrossScopeCycleDetection();
  /// ```
  static void enableGlobalCrossScopeCycleDetection() {
    _globalCrossScopeCycleDetectionEnabled = true;
    
    // Включаем для уже существующего root scope, если он есть
    if (_rootScope != null) {
      _rootScope!.enableGlobalCycleDetection();
    }
  }

  /// RU: Глобально отключает обнаружение циклических зависимостей между скоупами.
  /// ENG: Globally disables cross-scope circular dependency detection.
  ///
  /// Example:
  /// ```dart
  /// CherryPick.disableGlobalCrossScopeCycleDetection();
  /// ```
  static void disableGlobalCrossScopeCycleDetection() {
    _globalCrossScopeCycleDetectionEnabled = false;
    
    // Отключаем для уже существующего root scope, если он есть
    if (_rootScope != null) {
      _rootScope!.disableGlobalCycleDetection();
    }
    
    // Очищаем глобальный детектор
    GlobalCycleDetector.instance.clear();
  }

  /// RU: Проверяет, включено ли глобальное обнаружение циклических зависимостей между скоупами.
  /// ENG: Checks if global cross-scope circular dependency detection is enabled.
  ///
  /// return true если включено, false если отключено
  /// return true if enabled, false if disabled
  static bool get isGlobalCrossScopeCycleDetectionEnabled => _globalCrossScopeCycleDetectionEnabled;

  /// RU: Возвращает глобальную цепочку разрешения зависимостей.
  /// ENG: Returns global dependency resolution chain.
  ///
  /// Полезно для отладки циклических зависимостей между скоупами.
  /// Useful for debugging circular dependencies across scopes.
  ///
  /// return список имен зависимостей в глобальной цепочке разрешения
  /// return list of dependency names in global resolution chain
  static List<String> getGlobalResolutionChain() {
    return GlobalCycleDetector.instance.globalResolutionChain;
  }

  /// RU: Очищает все состояние глобального детектора циклических зависимостей.
  /// ENG: Clears all global circular dependency detector state.
  ///
  /// Полезно для тестов и сброса состояния.
  /// Useful for tests and state reset.
  static void clearGlobalCycleDetector() {
    GlobalCycleDetector.reset();
  }

  /// RU: Создает новый скоуп с автоматически включенным глобальным обнаружением циклических зависимостей.
  /// ENG: Creates a new scope with automatically enabled global circular dependency detection.
  ///
  /// Этот скоуп будет отслеживать циклические зависимости во всей иерархии.
  /// This scope will track circular dependencies across the entire hierarchy.
  ///
  /// Example:
  /// ```dart
  /// final scope = CherryPick.openGlobalSafeRootScope();
  /// // Глобальное обнаружение циклических зависимостей автоматически включено
  /// ```
  static Scope openGlobalSafeRootScope() {
    final scope = openRootScope();
    scope.enableCycleDetection();
    scope.enableGlobalCycleDetection();
    return scope;
  }

  /// RU: Создает новый дочерний скоуп с автоматически включенным глобальным обнаружением циклических зависимостей.
  /// ENG: Creates a new child scope with automatically enabled global circular dependency detection.
  ///
  /// [scopeName] - имя скоупа
  /// [scopeName] - scope name
  ///
  /// Example:
  /// ```dart
  /// final scope = CherryPick.openGlobalSafeScope(scopeName: 'feature.auth');
  /// // Глобальное обнаружение циклических зависимостей автоматически включено
  /// ```
  static Scope openGlobalSafeScope({String scopeName = '', String separator = '.'}) {
    final scope = openScope(scopeName: scopeName, separator: separator);
    scope.enableCycleDetection();
    scope.enableGlobalCycleDetection();
    return scope;
  }
}
