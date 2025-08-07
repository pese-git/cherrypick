/// Абстракция для DI-адаптера с использованием функций регистрации.
///
/// Позволяет использовать любые DI-контейнеры: и модульные, и безмодульные.
abstract class DIAdapter {
  /// Устанавливает зависимости с помощью одной функции регистрации.
  ///
  /// Функция принимает выбранный DI-контейнер, задаваемый реализацией.
  void setupDependencies(void Function(dynamic container) registration);

  /// Резолвит (возвращает) экземпляр типа [T] (по имени, если требуется).
  T resolve<T extends Object>({String? named});

  /// Асинхронно резолвит экземпляр типа [T].
  Future<T> resolveAsync<T extends Object>({String? named});

  /// Уничтожает/отчищает DI-контейнер.
  void teardown();

  /// Открывает дочерний под-scope (если применимо).
  DIAdapter openSubScope(String name);

  /// Ожидание готовности DI контейнера (нужно для async DI, например get_it)
  Future<void> waitForAsyncReady();
}
