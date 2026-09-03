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
///
/// Считает созданные экземпляры, когда включён [countingEnabled]. Счётчик
/// нужен тесту равного объёма работы: если один DI при первом резолве строит
/// 100 объектов, а другой 10 000, сравнивать их время бессмысленно.
/// В измерительном прогоне флаг выключен, и цена — одна проверка bool,
/// одинаковая для всех адаптеров.
class UniversalServiceImpl extends UniversalService {
  static bool countingEnabled = false;
  static int createdCount = 0;

  static void resetCounter() {
    createdCount = 0;
  }

  UniversalServiceImpl({required super.value, super.dependency}) {
    if (countingEnabled) createdCount++;
  }
}
