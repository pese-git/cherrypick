import 'package:benchmark_di/scenarios/universal_binding_mode.dart';

/// Универсальная абстракция для DI-адаптера с унифицированной функцией регистрации.
/// Теперь для каждого адаптера задаём строгий generic тип контейнера.
typedef Registration<TContainer> = void Function(TContainer);

abstract class DIAdapter<TContainer> {
  /// Устанавливает зависимости с помощью строго типизированного контейнера.
  void setupDependencies(void Function(TContainer container) registration);

  /// Возвращает типобезопасную функцию регистрации зависимостей под конкретный сценарий.
  Registration<TContainer> universalRegistration<S extends Enum>({
    required S scenario,
    required int chainCount,
    required int nestingDepth,
    required UniversalBindingMode bindingMode,
  });

  /// Резолвит (возвращает) экземпляр типа [T] (по имени, если требуется).
  T resolve<T extends Object>({String? named});

  /// Возвращает хендл нативного биндинга контейнера для [named]
  /// (или безымянного биндинга, если [named] null), либо null.
  ///
  /// У handle-ориентированных контейнеров (yx_scope — `Dep`, riverpod —
  /// `ProviderBase`) нативный потребительский путь — разыменование хендла,
  /// а не поиск по строке. Для них адаптер возвращает хендл, и бенчмарк
  /// измеряет [resolveNative]. У service locator'ов (cherrypick, get_it,
  /// kiwi) строковый/типовой поиск — сам нативный API, хендлов нет, и
  /// дефолтный null оставляет бенчмарк на [resolve].
  ///
  /// Вызывать вне секундомера (в setup): сам запрос хендла может идти
  /// через индекс адаптера и не обязан быть нативным путём.
  Object? nativeBindingFor({String? named}) => null;

  /// Резолвит биндинг по хендлу, полученному от [nativeBindingFor].
  ///
  /// Дефолт бросает: вызывать только если [nativeBindingFor] вернул не-null.
  T resolveNative<T extends Object>(Object binding, {String? named}) {
    throw UnsupportedError('$runtimeType does not support native bindings');
  }

  /// Асинхронно резолвит экземпляр типа [T] (если нужно).
  Future<T> resolveAsync<T extends Object>({String? named});

  /// Уничтожает/отчищает DI-контейнер.
  ///
  /// Асинхронный: cherrypick освобождает Disposable-зависимости через await,
  /// и синхронный вызов оставлял бы контейнер частично живым к следующей
  /// итерации — модули накапливались в одном и том же scope.
  Future<void> teardown();

  /// Открывает дочерний scope и возвращает новый адаптер (если поддерживается).
  DIAdapter<TContainer> openSubScope(String name);

  /// Ожидание готовности DI контейнера (если нужно для async DI).
  Future<void> waitForAsyncReady() async {}
}
