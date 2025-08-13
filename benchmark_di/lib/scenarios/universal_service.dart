/// Base interface for any universal service in the benchmarks.
///
/// Represents an object in the dependency chain with an identifiable value
/// and (optionally) a dependency on a previous service in the chain.
abstract class UniversalService {
  /// String ID for this service instance (e.g. chain/level info).
  final String value;

  /// Optional reference to dependency service in the chain.
  final UniversalService? dependency;
  UniversalService({required this.value, this.dependency});
}

/// Default implementation for [UniversalService] used in service chains.
class UniversalServiceImpl extends UniversalService {
  UniversalServiceImpl({required super.value, super.dependency});
}
