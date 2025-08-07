/// Универсальная абстракция для DI-адаптера с унифицированной функцией регистрации.
/// Теперь для каждого адаптера задаём строгий generic тип контейнера.
abstract class DIAdapter<TContainer> {
  /// Устанавливает зависимости с помощью строго типизированного контейнера.
  void setupDependencies(void Function(TContainer container) registration);

  /// Резолвит (возвращает) экземпляр типа [T] (по имени, если требуется).
  T resolve<T extends Object>({String? named});

  /// Асинхронно резолвит экземпляр типа [T] (если нужно).
  Future<T> resolveAsync<T extends Object>({String? named});

  /// Уничтожает/отчищает DI-контейнер.
  void teardown();

  /// Открывает дочерний scope и возвращает новый адаптер (если поддерживается).
  DIAdapter<TContainer> openSubScope(String name);

  /// Ожидание готовности DI контейнера (если нужно для async DI).
  Future<void> waitForAsyncReady() async {}
}
