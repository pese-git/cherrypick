import 'package:cherrypick_flutter/cherrypick_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/workspace_cubit.dart';
import 'presentation/theme.dart';

/// Root widget.
///
/// Both the [WorkspaceCubit] and the [GoRouter] come from the container and are
/// exposed to the tree — the cubit with `BlocProvider.value`, the router as
/// `routerConfig`. The widget tree reads them; the root scope owns them.
class MarketPulseApp extends StatelessWidget {
  const MarketPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final rootScope = CherryPickProvider.of(context).openRootScope();

    return BlocProvider<WorkspaceCubit>.value(
      value: rootScope.resolve<WorkspaceCubit>(),
      child: MaterialApp.router(
        title: 'Market Pulse',
        debugShowCheckedModeBanner: false,
        theme: buildMarketTheme(),
        routerConfig: rootScope.resolve<GoRouter>(),
      ),
    );
  }
}
