import 'package:cherrypick/cherrypick.dart';
import 'universal_service.dart';

enum UniversalBindingMode {
  singletonStrategy,
  factoryStrategy,
  asyncStrategy,
}

class UniversalChainModule extends Module {
  final int chainCount;
  final int nestingDepth;
  final UniversalBindingMode bindingMode;

  UniversalChainModule({
    required this.chainCount,
    required this.nestingDepth,
    this.bindingMode = UniversalBindingMode.singletonStrategy,
  });

  @override
  void builder(Scope currentScope) {
    for (var chainIndex = 0; chainIndex < chainCount; chainIndex++) {
      for (var levelIndex = 0; levelIndex < nestingDepth; levelIndex++) {
        final chain = chainIndex + 1;
        final level = levelIndex + 1;
        final prevDepName = '${chain}_${level - 1}';
        final depName = '${chain}_$level';
        switch (bindingMode) {
          case UniversalBindingMode.singletonStrategy:
            bind<UniversalService>()
                .toProvide(() => UniversalServiceImpl(
                  value: depName,
                  dependency: currentScope.tryResolve<UniversalService>(named: prevDepName),
                ))
                .withName(depName)
                .singleton();
            break;
          case UniversalBindingMode.factoryStrategy:
            bind<UniversalService>()
                .toProvide(() => UniversalServiceImpl(
                  value: depName,
                  dependency: currentScope.tryResolve<UniversalService>(named: prevDepName),
                ))
                .withName(depName);
            break;
          case UniversalBindingMode.asyncStrategy:
            bind<UniversalService>()
                .toProvideAsync(() async => UniversalServiceImpl(
                  value: depName,
                  dependency: await currentScope.resolveAsync<UniversalService>(named: prevDepName),
                ))
                .withName(depName)
                .singleton();
            break;
        }
      }
    }
  }
}
