/// Базовый интерфейс для автоматического управления ресурсами в CherryPick.
/// Если объект реализует [Disposable], DI-контейнер вызовет [dispose] при очистке scope.
abstract class Disposable {
  void dispose();
}
