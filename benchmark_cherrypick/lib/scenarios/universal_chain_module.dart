import 'package:cherrypick/cherrypick.dart';
import 'universal_service.dart';

enum UniversalBindingMode {
  singletonStrategy,
  factoryStrategy,
  asyncStrategy,
}

enum UniversalScenario {
  register,
  chain,
  named,
  override,
  asyncChain,
}

class UniversalChainModule extends Module {
  final int chainCount;
  final int nestingDepth;
  final UniversalBindingMode bindingMode;
  final UniversalScenario scenario;

  UniversalChainModule({
    required this.chainCount,
    required this.nestingDepth,
    this.bindingMode = UniversalBindingMode.singletonStrategy,
    this.scenario = UniversalScenario.chain,
  });

  @override
  void builder(Scope currentScope) {
    if (scenario == UniversalScenario.asyncChain) {
      for (var chainIndex = 0; chainIndex < chainCount; chainIndex++) {
        for (var levelIndex = 0; levelIndex < nestingDepth; levelIndex++) {
          final chain = chainIndex + 1;
          final level = levelIndex + 1;
          final prevDepName = '${chain}_${level - 1}';
          final depName = '${chain}_$level';
          bind<UniversalService>()
            .toProvideAsync(() async {
              final prev = level > 1
                  ? await currentScope.resolveAsync<UniversalService>(named: prevDepName)
                  : null;
              return UniversalServiceImpl(
                value: depName,
                dependency: prev,
              );
            })
            .withName(depName)
            .singleton();
        }
      }
      return;
    }

    switch (scenario) {
      case UniversalScenario.register:
        bind<UniversalService>()
            .toProvide(() => UniversalServiceImpl(value: 'reg', dependency: null))
            .singleton();
        break;
      case UniversalScenario.named:
        bind<Object>().toProvide(() => UniversalServiceImpl(value: 'impl1')).withName('impl1');
        bind<Object>().toProvide(() => UniversalServiceImpl(value: 'impl2')).withName('impl2');
        break;
      case UniversalScenario.chain:
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
        break;
      case UniversalScenario.override:
        // handled at benchmark level
        break;
      case UniversalScenario.asyncChain:
        // already handled above
        break;
    }
  }
}
