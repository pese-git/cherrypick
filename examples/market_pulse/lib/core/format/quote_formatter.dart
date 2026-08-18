import '../../data/config/app_config.dart';

/// Formats prices for the UI.
///
/// Trivial on purpose: it exists to be a *singleton provided by the generated
/// module* whose cache hits show up in the Inspector every time a tab repaints.
class QuoteFormatter {
  final AppConfig config;

  const QuoteFormatter(this.config);

  String price(double value) {
    if (value >= 1000) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(3);
    return value.toStringAsFixed(5);
  }

  String change(double value) {
    final sign = value > 0
        ? '+'
        : value < 0
        ? '−'
        : '';
    return '$sign${price(value.abs())}';
  }
}
