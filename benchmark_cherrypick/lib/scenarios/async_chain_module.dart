import 'package:cherrypick/cherrypick.dart';

class AsyncA {}
class AsyncB {
  final AsyncA a;
  AsyncB(this.a);
}
class AsyncC {
  final AsyncB b;
  AsyncC(this.b);
}

class AsyncChainModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<AsyncA>().toProvideAsync(() async => AsyncA()).singleton();
    bind<AsyncB>().toProvideAsync(() async => AsyncB(await currentScope.resolveAsync<AsyncA>())).singleton();
    bind<AsyncC>().toProvideAsync(() async => AsyncC(await currentScope.resolveAsync<AsyncB>())).singleton();
  }
}
