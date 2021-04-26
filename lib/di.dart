import 'package:dart_di/scope.dart';

Scope? _rootScope = null;

class DartDi {
  /// RU: Метод открывает главный [Scope].
  /// ENG: The method opens the main [Scope].
  ///
  /// return
  static Scope openRootScope() {
    if (_rootScope == null) {
      _rootScope = Scope(null);
    }
    return _rootScope!;
  }

  /// RU: Метод закрывает главный [Scope].
  /// ENG: The method close the main [Scope].
  ///
  ///
  static void closeRootScope() {
    if (_rootScope != null) {
      _rootScope = null;
    }
  }
}
