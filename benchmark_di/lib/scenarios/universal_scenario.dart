/// Enum to represent which scenario is constructed for the benchmark.
enum UniversalScenario {
  /// Single registration.
  register,
  /// Chain of dependencies.
  chain,
  /// Named registrations.
  named,
  /// Child-scope override scenario.
  override,
  /// Asynchronous chain scenario.
  asyncChain,
}
