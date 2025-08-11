/// Базовый интерфейс для автоматического управления ресурсами в CherryPick.
/// Если объект реализует [Disposable], DI-контейнер вызовет [dispose] при очистке scope.
import 'dart:async';

/// Interface for resources that need to be disposed synchronously or asynchronously.
abstract class Disposable {
  /// Releases all resources held by this object.
  /// For sync disposables, just implement as void; for async ones, return Future.
  FutureOr<void> dispose();
}
