import 'package:riverpod/riverpod.dart';
import 'di_adapter.dart';

/// Унифицированный DIAdapter для Riverpod с поддержкой scopes и строгой типизацией.
class RiverpodAdapter extends DIAdapter<Map<String, ProviderBase<Object?>>> {
  ProviderContainer? _container;
  final Map<String, ProviderBase<Object?>> _namedProviders;
  final ProviderContainer? _parent;
  final bool _isSubScope;

  RiverpodAdapter({
    ProviderContainer? container,
    Map<String, ProviderBase<Object?>>? providers,
    ProviderContainer? parent,
    bool isSubScope = false,
  })  : _container = container,
        _namedProviders = providers ?? <String, ProviderBase<Object?>>{},
        _parent = parent,
        _isSubScope = isSubScope;

  @override
  void setupDependencies(void Function(Map<String, ProviderBase<Object?>> container) registration) {
    _container ??= _parent == null
        ? ProviderContainer()
        : ProviderContainer(parent: _parent);
    registration(_namedProviders);
  }

  @override
  T resolve<T extends Object>({String? named}) {
    final key = named ?? T.toString();
    final provider = _namedProviders[key];
    if (provider == null) {
      throw Exception('Provider not found for $key');
    }
    return _container!.read(provider) as T;
  }

  @override
  Future<T> resolveAsync<T extends Object>({String? named}) async {
    final key = named ?? T.toString();
    final provider = _namedProviders[key];
    if (provider == null) {
      throw Exception('Provider not found for $key');
    }
    // Если это FutureProvider — используем .future
    if (provider.runtimeType.toString().contains('FutureProvider')) {
      return await _container!.read((provider as dynamic).future) as T;
    }
    return resolve<T>(named: named);
  }

  @override
  void teardown() {
    _container?.dispose();
    _container = null;
    _namedProviders.clear();
  }

  @override
  RiverpodAdapter openSubScope(String name) {
    final newContainer = ProviderContainer(parent: _container);
    return RiverpodAdapter(
      container: newContainer,
      providers: Map.of(_namedProviders),
      parent: _container,
      isSubScope: true,
    );
  }

  @override
  Future<void> waitForAsyncReady() async {
    // Riverpod синхронный по умолчанию.
    return;
  }
}
