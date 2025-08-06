import 'package:cherrypick/cherrypick.dart';
import 'foo_service.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<FooService>().toProvide(() => FooService());
  }
}
