import 'package:cherrypick/cherrypick.dart';
import 'parent_impl.dart';
import 'shared.dart';

class ParentModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Shared>().toProvide(() => ParentImpl()).singleton();
  }
}
