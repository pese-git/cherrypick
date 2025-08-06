import 'package:cherrypick/cherrypick.dart';

class Impl1 {}
class Impl2 {}

class NamedModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Object>().toProvide(() => Impl1()).withName('impl1');
    bind<Object>().toProvide(() => Impl2()).withName('impl2');
  }
}
