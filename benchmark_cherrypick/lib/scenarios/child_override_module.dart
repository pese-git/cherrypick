import 'package:cherrypick/cherrypick.dart';
import 'child_impl.dart';
import 'shared.dart';

class ChildOverrideModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Shared>().toProvide(() => ChildImpl()).singleton();
  }
}
