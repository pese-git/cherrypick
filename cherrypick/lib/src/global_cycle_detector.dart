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

import 'dart:collection';
import 'dart:math';
import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick/src/cycle_detector.dart';
import 'package:cherrypick/src/log_format.dart';


/// RU: Глобальный детектор циклических зависимостей для всей иерархии скоупов.
/// ENG: Global circular dependency detector for entire scope hierarchy.
class GlobalCycleDetector {
  static GlobalCycleDetector? _instance;

  final CherryPickLogger _logger;
  
  // Глобальный стек разрешения зависимостей
  final Set<String> _globalResolutionStack = HashSet<String>();
  
  // История разрешения для построения цепочки зависимостей
  final List<String> _globalResolutionHistory = [];
  
  // Карта активных детекторов по скоупам
  final Map<String, CycleDetector> _scopeDetectors = HashMap<String, CycleDetector>();

  GlobalCycleDetector._internal({required CherryPickLogger logger}): _logger = logger;

  /// RU: Получить единственный экземпляр глобального детектора.
  /// ENG: Get singleton instance of global detector.
  static GlobalCycleDetector get instance {
    _instance ??= GlobalCycleDetector._internal(logger:  CherryPick.globalLogger);
    return _instance!;
  }

  /// RU: Сбросить глобальный детектор (полезно для тестов).
  /// ENG: Reset global detector (useful for tests).
  static void reset() {
    _instance?._globalResolutionStack.clear();
    _instance?._globalResolutionHistory.clear();
    _instance?._scopeDetectors.clear();
    _instance = null;
  }

  /// RU: Начать отслеживание разрешения зависимости в глобальном контексте.
  /// ENG: Start tracking dependency resolution in global context.
  void startGlobalResolving<T>({String? named, String? scopeId}) {
    final dependencyKey = _createDependencyKeyFromType(T, named, scopeId);
    
    if (_globalResolutionStack.contains(dependencyKey)) {
      // Найдена глобальная циклическая зависимость
      final cycleStartIndex = _globalResolutionHistory.indexOf(dependencyKey);
      final cycle = _globalResolutionHistory.sublist(cycleStartIndex)..add(dependencyKey);
      _logger.error(formatLogMessage(
        type: 'CycleDetector',
        name: dependencyKey.toString(),
        params: {'chain': cycle.join('->')},
        description: 'cycle detected',
      ));
      throw CircularDependencyException(
        'Global circular dependency detected for $dependencyKey',
        cycle,
      );
    }
    
    _globalResolutionStack.add(dependencyKey);
    _globalResolutionHistory.add(dependencyKey);
  }

  /// RU: Завершить отслеживание разрешения зависимости в глобальном контексте.
  /// ENG: Finish tracking dependency resolution in global context.
  void finishGlobalResolving<T>({String? named, String? scopeId}) {
    final dependencyKey = _createDependencyKeyFromType(T, named, scopeId);
    _globalResolutionStack.remove(dependencyKey);
    
    // Удаляем из истории только если это последний элемент
    if (_globalResolutionHistory.isNotEmpty && 
        _globalResolutionHistory.last == dependencyKey) {
      _globalResolutionHistory.removeLast();
    }
  }

  /// RU: Выполнить действие с глобальным отслеживанием циклических зависимостей.
  /// ENG: Execute action with global circular dependency tracking.
  T withGlobalCycleDetection<T>(
    Type dependencyType,
    String? named,
    String? scopeId,
    T Function() action,
  ) {
    final dependencyKey = _createDependencyKeyFromType(dependencyType, named, scopeId);
    
    if (_globalResolutionStack.contains(dependencyKey)) {
      final cycleStartIndex = _globalResolutionHistory.indexOf(dependencyKey);
      final cycle = _globalResolutionHistory.sublist(cycleStartIndex)
        ..add(dependencyKey);
      _logger.error(formatLogMessage(
        type: 'CycleDetector',
        name: dependencyKey.toString(),
        params: {'chain': cycle.join('->')},
        description: 'cycle detected',
      ));
      throw CircularDependencyException(
        'Global circular dependency detected for $dependencyKey',
        cycle,
      );
    }

    _globalResolutionStack.add(dependencyKey);
    _globalResolutionHistory.add(dependencyKey);

    try {
      return action();
    } finally {
      _globalResolutionStack.remove(dependencyKey);
      if (_globalResolutionHistory.isNotEmpty && 
          _globalResolutionHistory.last == dependencyKey) {
        _globalResolutionHistory.removeLast();
      }
    }
  }

  /// RU: Получить детектор для конкретного скоупа.
  /// ENG: Get detector for specific scope.
  CycleDetector getScopeDetector(String scopeId) {
    return _scopeDetectors.putIfAbsent(scopeId, () => CycleDetector(logger: CherryPick.globalLogger));
  }

  /// RU: Удалить детектор для скоупа.
  /// ENG: Remove detector for scope.
  void removeScopeDetector(String scopeId) {
    _scopeDetectors.remove(scopeId);
  }

  /// RU: Проверить, находится ли зависимость в процессе глобального разрешения.
  /// ENG: Check if dependency is currently being resolved globally.
  bool isGloballyResolving<T>({String? named, String? scopeId}) {
    final dependencyKey = _createDependencyKeyFromType(T, named, scopeId);
    return _globalResolutionStack.contains(dependencyKey);
  }

  /// RU: Получить текущую глобальную цепочку разрешения зависимостей.
  /// ENG: Get current global dependency resolution chain.
  List<String> get globalResolutionChain => List.unmodifiable(_globalResolutionHistory);

  /// RU: Очистить все состояние детектора.
  /// ENG: Clear all detector state.
  void clear() {
    _globalResolutionStack.clear();
    _globalResolutionHistory.clear();
    _scopeDetectors.values.forEach(_detectorClear);
    _scopeDetectors.clear();
  }

  void _detectorClear(detector) => detector.clear();

  /// RU: Создать уникальный ключ для зависимости с учетом скоупа.
  /// ENG: Create unique key for dependency including scope.
  //String _createDependencyKey<T>(String? named, String? scopeId) {
  //  return _createDependencyKeyFromType(T, named, scopeId);
  //}

  /// RU: Создать уникальный ключ для зависимости по типу с учетом скоупа.
  /// ENG: Create unique key for dependency by type including scope.
  String _createDependencyKeyFromType(Type type, String? named, String? scopeId) {
    final typeName = type.toString();
    final namePrefix = named != null ? '@$named' : '';
    final scopePrefix = scopeId != null ? '[$scopeId]' : '';
    return '$scopePrefix$typeName$namePrefix';
  }
}

/// RU: Улучшенный миксин для глобального обнаружения циклических зависимостей.
/// ENG: Enhanced mixin for global circular dependency detection.
mixin GlobalCycleDetectionMixin {
  String? _scopeId;
  bool _globalCycleDetectionEnabled = false;

  /// RU: Установить идентификатор скоупа для глобального отслеживания.
  /// ENG: Set scope identifier for global tracking.
  void setScopeId(String scopeId) {
    _scopeId = scopeId;
  }

  /// RU: Получить идентификатор скоупа.
  /// ENG: Get scope identifier.
  String? get scopeId => _scopeId;

  /// RU: Включить глобальное обнаружение циклических зависимостей.
  /// ENG: Enable global circular dependency detection.
  void enableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = true;
  }

  /// RU: Отключить глобальное обнаружение циклических зависимостей.
  /// ENG: Disable global circular dependency detection.
  void disableGlobalCycleDetection() {
    _globalCycleDetectionEnabled = false;
  }

  /// RU: Проверить, включено ли глобальное обнаружение циклических зависимостей.
  /// ENG: Check if global circular dependency detection is enabled.
  bool get isGlobalCycleDetectionEnabled => _globalCycleDetectionEnabled;

  /// RU: Выполнить действие с глобальным отслеживанием циклических зависимостей.
  /// ENG: Execute action with global circular dependency tracking.
  T withGlobalCycleDetection<T>(
    Type dependencyType,
    String? named,
    T Function() action,
  ) {
    if (!_globalCycleDetectionEnabled) {
      return action();
    }

    return GlobalCycleDetector.instance.withGlobalCycleDetection<T>(
      dependencyType,
      named,
      _scopeId,
      action,
    );
  }

  /// RU: Получить текущую глобальную цепочку разрешения зависимостей.
  /// ENG: Get current global dependency resolution chain.
  List<String> get globalResolutionChain => 
      GlobalCycleDetector.instance.globalResolutionChain;
}
