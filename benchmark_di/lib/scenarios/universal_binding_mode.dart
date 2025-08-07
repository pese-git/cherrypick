/// Enum to represent the DI registration/binding mode.
enum UniversalBindingMode {
  /// Singleton/provider binding.
  singletonStrategy,

  /// Factory-based binding.
  factoryStrategy,

  /// Async-based binding.
  asyncStrategy,
}
