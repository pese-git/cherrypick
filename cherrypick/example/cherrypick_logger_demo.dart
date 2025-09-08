import 'package:cherrypick/cherrypick.dart';

/// Example of a simple service class.
class UserRepository {
  String getUserName() => 'Sergey DI';
}

/// DI module for registering dependencies.
class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<UserRepository>().toInstance(UserRepository());
  }
}

void main() {
  // Set a global logger for the DI system
  CherryPick.setGlobalObserver(PrintCherryPickObserver());

  // Open the root scope
  final rootScope = CherryPick.openRootScope();

  // Register the DI module
  rootScope.installModules([AppModule()]);

  // Resolve a dependency (service)
  final repo = rootScope.resolve<UserRepository>();
  print('User: ${repo.getUserName()}');

  // Work with a sub-scope (create/close)
  final subScope = rootScope.openSubScope('feature.profile');
  subScope.closeSubScope('feature.profile');

  // Demonstrate disabling and re-enabling logging
  CherryPick.setGlobalObserver(SilentCherryPickObserver());
  rootScope.resolve<UserRepository>(); // now without logs
}
