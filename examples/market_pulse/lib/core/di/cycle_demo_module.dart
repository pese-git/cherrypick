import 'package:cherrypick/cherrypick.dart';

/// Deliberately broken services used by the Inspector's cycle experiment.
///
/// `RiskEngine` needs `PortfolioService`, which needs `RiskEngine` back. With
/// cycle detection off this resolves into a `StackOverflowError` with no useful
/// stack; with it on you get a [CircularDependencyException] naming the exact
/// chain. The Inspector button demonstrates the difference.
class RiskEngine {
  final PortfolioService portfolio;

  RiskEngine(this.portfolio);
}

class PortfolioService {
  final RiskEngine risk;

  PortfolioService(this.risk);
}

/// Installed into the throwaway `session.cycle-lab` scope, never into the app.
class CycleDemoModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<RiskEngine>().toProvide(
      () => RiskEngine(currentScope.resolve<PortfolioService>()),
    );

    bind<PortfolioService>().toProvide(
      () => PortfolioService(currentScope.resolve<RiskEngine>()),
    );
  }
}
