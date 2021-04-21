enum Mode { SIMPLE, INSTANCE, PROVIDER_INSTANCE }

class Binding<T> {
  late Mode _mode;
  late Type _key;
  late String _name;
  late T _instance;
  late T Function() _provider;
  late bool _isSingeltone = false;
  late bool _isNamed = false;

  Binding() {
    _mode = Mode.SIMPLE;
    _key = T;
  }

  Mode get mode => _mode;
  Type get key => _key;
  String get name => _name;
  bool get isSingeltone => _isSingeltone;
  bool get isNamed => _isNamed;

  Binding<T> withName(String name) {
    _name = name;
    _isNamed = true;
    return this;
  }

  Binding<T> toInstance(T value) {
    _mode = Mode.INSTANCE;
    _instance = value;
    _isSingeltone = true;
    return this;
  }

  Binding<T> toProvide(T Function() value) {
    _mode = Mode.PROVIDER_INSTANCE;
    _provider = value;
    return this;
  }

  Binding<T> singeltone() {
    if (_mode == Mode.PROVIDER_INSTANCE) {
      _instance = _provider.call();
    }
    _isSingeltone = true;
    return this;
  }

  T? get instance => _instance;

  T? get provider => _provider.call();
}
