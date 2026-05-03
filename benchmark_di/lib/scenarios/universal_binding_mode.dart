/// Enum to represent the DI registration/binding mode.
enum UniversalBindingMode {
  /// Eager singleton — instance created at registration time.
  singletonStrategy,

  /// Lazy singleton — instance created on first resolve, then cached.
  lazySingletonStrategy,

  /// Factory-based binding — new instance every time.
  factoryStrategy,

  /// Async-based binding.
  asyncStrategy,
}
