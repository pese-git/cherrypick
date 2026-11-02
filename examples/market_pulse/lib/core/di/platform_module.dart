import 'package:cherrypick/cherrypick.dart';

import '../../data/config/app_config.dart';
import '../../domain/entity/instrument.dart';
import '../observability/inspector_cubit.dart';
import 'instrument_universe.dart';
import 'workspace_cubit.dart';

/// Root-scope bindings that are already resolved by the time modules install.
///
/// Written by hand rather than generated: a module that has to receive
/// constructor arguments (the awaited config, the observer created in `main`)
/// cannot be produced by the code generator, and mixing both styles in one app
/// is the point — see `AppModule` for the generated half.
class PlatformModule extends Module {
  final AppConfig _config;
  final List<Instrument> _instruments;
  final InspectorCubit _inspector;
  final WorkspaceCubit _workspace;

  PlatformModule({
    required AppConfig config,
    required List<Instrument> instruments,
    required InspectorCubit inspector,
    required WorkspaceCubit workspace,
  }) : _config = config,
       _instruments = instruments,
       _inspector = inspector,
       _workspace = workspace;

  @override
  void builder(Scope currentScope) {
    // toInstance: the value already exists, no factory needed.
    bind<AppConfig>().toInstance(_config);
    bind<InstrumentUniverse>().toInstance(InstrumentUniverse(_instruments));

    // Both cubits implement Disposable, so closing the root scope closes them.
    bind<InspectorCubit>().toInstance(_inspector);
    bind<WorkspaceCubit>().toInstance(_workspace);
  }
}
