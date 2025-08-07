import 'package:riverpod/riverpod.dart';
import 'di_adapter.dart';

/// RiverpodAdapter реализует DIAdapter для универсального бенчмарка через Riverpod.
class RiverpodAdapter implements DIAdapter {
  late ProviderContainer _container;
  late final Map<String?, ProviderBase<Object?>> _namedProviders;
  final ProviderContainer? _parent;

  // Основной конструктор
  RiverpodAdapter() : _parent = null {
    _namedProviders = <String?, ProviderBase<Object?>>{};
  }

  // Внутренний конструктор для дочерних скоупов
  RiverpodAdapter._child(this._container, this._namedProviders, this._parent);

  @override
  void setupDependencies(void Function(dynamic container) registration) {
    // Для главного контейнера
    _container = _parent == null
        ? ProviderContainer()
        : ProviderContainer(parent: _parent);
    registration(_namedProviders);
  }

  /// Регистрировать провайдеры нужно по имени-сервису.
  /// Пример: container['SomeClass'] = Provider((ref) => SomeClass());

  @override
  T resolve<T extends Object>({String? named}) {
    final provider = _namedProviders[named ?? T.toString()];
    if (provider == null) {
      throw Exception('Provider not found for $named');
    }
    return _container.read(provider) as T;
  }

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async {
    final provider = _namedProviders[named ?? T.toString()];
    if (provider == null) {
      throw Exception('Provider not found for $named');
    }
    // Если это FutureProvider — используем .future
    if (provider.runtimeType.toString().contains('FutureProvider')) {
      final result = await _container.read((provider as dynamic).future);
      return result as T;
    }
    return resolve<T>(named: named);
  }

  @override
  void teardown() {
    _container.dispose();
    _namedProviders.clear();
  }

  @override
  DIAdapter openSubScope(String name) {
    // Создаём дочерний scope через новый контейнер с parent
    final childContainer = ProviderContainer(parent: _container);
    // Провайдеры будут унаследованы (immutable копия), но при желании можно их расширять в дочернем scope.
    return RiverpodAdapter._child(childContainer, Map.of(_namedProviders), _container);
  }

  @override
  Future<void> waitForAsyncReady() async {
    // Riverpod синхронный по умолчанию.
    return;
  }
}
