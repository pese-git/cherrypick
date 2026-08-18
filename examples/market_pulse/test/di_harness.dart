import 'package:cherrypick/cherrypick.dart';
import 'package:market_pulse/core/di/app_module.dart';
import 'package:market_pulse/core/di/bootstrap_module.dart';
import 'package:market_pulse/core/di/platform_module.dart';
import 'package:market_pulse/core/di/router_module.dart';
import 'package:market_pulse/core/di/workspace_cubit.dart';
import 'package:market_pulse/core/observability/inspector_cubit.dart';
import 'package:market_pulse/core/observability/inspector_observer.dart';
import 'package:market_pulse/data/config/app_config.dart';
import 'package:market_pulse/domain/entity/instrument.dart';
import 'package:market_pulse/domain/entity/user_session.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Test bootstrap: the same graph as `main()`, with a fast clock.
///
/// Swapping [AppConfig] here instead of in the module is the point — the config
/// is a binding, so a test decides its value without touching app code.
class TestHarness {
  final WorkspaceCubit workspace;
  final InspectorCubit inspector;

  TestHarness(this.workspace, this.inspector);

  static Future<TestHarness> bootstrap({
    Duration tickInterval = const Duration(milliseconds: 5),
    int historyLength = 16,
  }) async {
    final inspector = InspectorCubit();
    CherryPick.setGlobalObserver(InspectorObserver(inspector));

    final rootScope = CherryPick.openRootScope()
      ..installModules([BootstrapModule()]);

    final instruments = await rootScope.resolveAsync<List<Instrument>>(
      named: 'remote',
    );

    final workspace = WorkspaceCubit();
    rootScope.installModules([
      PlatformModule(
        config: AppConfig(
          environment: 'test',
          tickInterval: tickInterval,
          historyLength: historyLength,
        ),
        instruments: instruments,
        inspector: inspector,
        workspace: workspace,
      ),
      $AppModule(),
      RouterModule(talker: Talker()),
    ]);

    return TestHarness(workspace, inspector);
  }

  void signIn({String userId = 'desk-eu', String name = 'Europe desk'}) {
    workspace.signIn(
      UserSession(
        userId: userId,
        displayName: name,
        openedAt: DateTime.utc(2026),
      ),
    );
  }

  /// Restores global container state between tests.
  ///
  /// Closing the root scope also closes both cubits: they implement
  /// [Disposable], so the container owns their lifetime here exactly as it does
  /// in the running app.
  static Future<void> tearDown() async {
    await CherryPick.closeRootScope();
    CherryPick.clearGlobalCycleDetector();
    CherryPick.disableGlobalCycleDetection();
    CherryPick.disableGlobalCrossScopeCycleDetection();
    CherryPick.setGlobalObserver(SilentCherryPickObserver());
  }
}
