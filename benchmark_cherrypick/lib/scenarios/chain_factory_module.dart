// === DI graph: A -> B -> C (factory/no singleton) ===
import 'package:cherrypick/cherrypick.dart';

import 'service.dart';
import 'service_impl.dart';

class ChainFactoryModule extends Module {
  // количество независимых цепочек
  final int chainCount;

  // глубина вложенности
  final int nestingDepth;

  ChainFactoryModule({
    required this.chainCount,
    required this.nestingDepth,
  });

  @override
  void builder(Scope currentScope) {
    for (var chainIndex = 0; chainIndex < chainCount; chainIndex++) {
      for (var levelIndex = 0; levelIndex < nestingDepth; levelIndex++) {
        final chain = chainIndex + 1;
        final level = levelIndex + 1;

        final prevDepName = '${chain.toString()}_${(level - 1).toString()}';
        final depName = '${chain.toString()}_${level.toString()}';

        bind<Service>()
            .toProvide(
              () => ServiceImpl(
                value: depName,
                dependency: currentScope.tryResolve<Service>(
                  named: prevDepName,
                ),
              ),
            )
            .withName(depName);
      }
    }
  }
}