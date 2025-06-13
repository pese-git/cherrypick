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

/// RU: Исключение, выбрасываемое при обнаружении циклической зависимости.
/// ENG: Exception thrown when a circular dependency is detected.
class CircularDependencyException implements Exception {
  final String message;
  final List<String> dependencyChain;

  const CircularDependencyException(this.message, this.dependencyChain);

  @override
  String toString() {
    final chain = dependencyChain.join(' -> ');
    return 'CircularDependencyException: $message\nDependency chain: $chain';
  }
}

/// RU: Детектор циклических зависимостей для CherryPick DI контейнера.
/// ENG: Circular dependency detector for CherryPick DI container.
class CycleDetector {
  // Стек текущих разрешаемых зависимостей
  final Set<String> _resolutionStack = HashSet<String>();
  
  // История разрешения для построения цепочки зависимостей
  final List<String> _resolutionHistory = [];

  /// RU: Начинает отслеживание разрешения зависимости.
  /// ENG: Starts tracking dependency resolution.
  /// 
  /// Throws [CircularDependencyException] if circular dependency is detected.
  void startResolving<T>({String? named}) {
    final dependencyKey = _createDependencyKey<T>(named);
    
    if (_resolutionStack.contains(dependencyKey)) {
      // Найдена циклическая зависимость
      final cycleStartIndex = _resolutionHistory.indexOf(dependencyKey);
      final cycle = _resolutionHistory.sublist(cycleStartIndex)..add(dependencyKey);
      
      throw CircularDependencyException(
        'Circular dependency detected for $dependencyKey',
        cycle,
      );
    }
    
    _resolutionStack.add(dependencyKey);
    _resolutionHistory.add(dependencyKey);
  }

  /// RU: Завершает отслеживание разрешения зависимости.
  /// ENG: Finishes tracking dependency resolution.
  void finishResolving<T>({String? named}) {
    final dependencyKey = _createDependencyKey<T>(named);
    _resolutionStack.remove(dependencyKey);
    
    // Удаляем из истории только если это последний элемент
    if (_resolutionHistory.isNotEmpty && 
        _resolutionHistory.last == dependencyKey) {
      _resolutionHistory.removeLast();
    }
  }

  /// RU: Очищает все состояние детектора.
  /// ENG: Clears all detector state.
  void clear() {
    _resolutionStack.clear();
    _resolutionHistory.clear();
  }

  /// RU: Проверяет, находится ли зависимость в процессе разрешения.
  /// ENG: Checks if dependency is currently being resolved.
  bool isResolving<T>({String? named}) {
    final dependencyKey = _createDependencyKey<T>(named);
    return _resolutionStack.contains(dependencyKey);
  }

  /// RU: Возвращает текущую цепочку разрешения зависимостей.
  /// ENG: Returns current dependency resolution chain.
  List<String> get currentResolutionChain => List.unmodifiable(_resolutionHistory);

  /// RU: Создает уникальный ключ для зависимости.
  /// ENG: Creates unique key for dependency.
  String _createDependencyKey<T>(String? named) {
    final typeName = T.toString();
    return named != null ? '$typeName@$named' : typeName;
  }
}

/// RU: Миксин для добавления поддержки обнаружения циклических зависимостей.
/// ENG: Mixin for adding circular dependency detection support.
mixin CycleDetectionMixin {
  CycleDetector? _cycleDetector;

  /// RU: Включает обнаружение циклических зависимостей.
  /// ENG: Enables circular dependency detection.
  void enableCycleDetection() {
    _cycleDetector = CycleDetector();
  }

  /// RU: Отключает обнаружение циклических зависимостей.
  /// ENG: Disables circular dependency detection.
  void disableCycleDetection() {
    _cycleDetector?.clear();
    _cycleDetector = null;
  }

  /// RU: Проверяет, включено ли обнаружение циклических зависимостей.
  /// ENG: Checks if circular dependency detection is enabled.
  bool get isCycleDetectionEnabled => _cycleDetector != null;

  /// RU: Выполняет действие с отслеживанием циклических зависимостей.
  /// ENG: Executes action with circular dependency tracking.
  T withCycleDetection<T>(
    Type dependencyType,
    String? named,
    T Function() action,
  ) {
    if (_cycleDetector == null) {
      return action();
    }

    final dependencyKey = named != null 
        ? '${dependencyType.toString()}@$named' 
        : dependencyType.toString();

    if (_cycleDetector!._resolutionStack.contains(dependencyKey)) {
      final cycleStartIndex = _cycleDetector!._resolutionHistory.indexOf(dependencyKey);
      final cycle = _cycleDetector!._resolutionHistory.sublist(cycleStartIndex)
        ..add(dependencyKey);
      
      throw CircularDependencyException(
        'Circular dependency detected for $dependencyKey',
        cycle,
      );
    }

    _cycleDetector!._resolutionStack.add(dependencyKey);
    _cycleDetector!._resolutionHistory.add(dependencyKey);

    try {
      return action();
    } finally {
      _cycleDetector!._resolutionStack.remove(dependencyKey);
      if (_cycleDetector!._resolutionHistory.isNotEmpty && 
          _cycleDetector!._resolutionHistory.last == dependencyKey) {
        _cycleDetector!._resolutionHistory.removeLast();
      }
    }
  }

  /// RU: Возвращает текущую цепочку разрешения зависимостей.
  /// ENG: Returns current dependency resolution chain.
  List<String> get currentResolutionChain => 
      _cycleDetector?.currentResolutionChain ?? [];
}
