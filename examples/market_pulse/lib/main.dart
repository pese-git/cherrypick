import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_observer.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'app.dart';
import 'core/di/app_module.dart';
import 'core/di/bootstrap_module.dart';
import 'core/di/platform_module.dart';
import 'core/di/router_module.dart';
import 'core/di/workspace_cubit.dart';
import 'core/observability/composite_observer.dart';
import 'core/observability/inspector_cubit.dart';
import 'core/observability/inspector_observer.dart';
import 'data/config/app_config.dart';
import 'domain/entity/instrument.dart';

/// Bootstrap in four steps, in the order the container wants them:
///
/// 1. install the observer *before* the first scope exists, so nothing is
///    missed — scope creation itself is an observable event;
/// 2. install the modules whose values must be awaited;
/// 3. await them once;
/// 4. install the synchronous graph that depends on those values.
///
/// Step 3/4 is the standard answer to "a module needs a value that only exists
/// after an await": prefetch asynchronously, then bind the results.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Without this Flutter web keeps routes behind a #fragment, and
  // `/market/BTCUSD` would never reach the router — which would quietly undo
  // the point of addressing DI scopes by URL.
  usePathUrlStrategy();

  final talker = Talker();
  final inspector = InspectorCubit();

  // Two observer stacks, one log: DI events through CherryPick's observer,
  // bloc transitions through Bloc.observer.
  CherryPick.setGlobalObserver(
    CompositeCherryPickObserver([
      InspectorObserver(inspector),
      TalkerCherryPickObserver(talker),
    ]),
  );
  Bloc.observer = TalkerBlocObserver(talker: talker);

  // Cost is only paid in debug: detection walks the resolution chain.
  if (kDebugMode) {
    CherryPick.enableGlobalCycleDetection();
    CherryPick.enableGlobalCrossScopeCycleDetection();
  }

  final rootScope = CherryPick.openRootScope()
    ..installModules([BootstrapModule()]);

  final config = await rootScope.resolveAsync<AppConfig>(named: 'remote');
  final instruments = await rootScope.resolveAsync<List<Instrument>>(
    named: 'remote',
  );

  rootScope.installModules([
    PlatformModule(
      config: config,
      instruments: instruments,
      inspector: inspector,
      workspace: WorkspaceCubit(),
    ),
    // Generated from the annotated AppModule by build_runner.
    $AppModule(),
    RouterModule(talker: talker),
  ]);

  runApp(const CherryPickProvider(child: MarketPulseApp()));
}
