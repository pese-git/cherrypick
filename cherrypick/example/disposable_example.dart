import 'package:cherrypick/cherrypick.dart';

/// Ваш сервис с освобождением ресурсов
class MyService implements Disposable {
  bool wasDisposed = false;

  @override
  void dispose() {
    // Например: закрыть соединение, остановить таймер, освободить память
    wasDisposed = true;
    print('MyService disposed!');
  }

  void doSomething() => print('Doing something...');
}

void main() {
  final scope = CherryPick.openRootScope();

  // Регистрируем биндинг (singleton для примера)
  scope.installModules([
    ModuleImpl(),
  ]);

  // Получаем зависимость
  final service = scope.resolve<MyService>();
  service.doSomething(); // «Doing something...»

  // Освобождаем все ресурсы
  scope.dispose();
  print('Service wasDisposed = ${service.wasDisposed}'); // true
}

/// Пример модуля CherryPick
class ModuleImpl extends Module {
  @override
  void builder(Scope scope) {
    bind<MyService>().toProvide(() => MyService()).singleton();
  }
}
