import 'package:cherrypick/cherrypick.dart';

import '../../data/config/app_config.dart';
import '../../data/repository/static_instrument_repository.dart';
import '../../domain/entity/instrument.dart';
import '../../domain/repository/instrument_repository.dart';

/// Everything the app must `await` before it can build a synchronous graph.
///
/// Bindings shown here:
/// * [Binding.toProvide]     — the repository, created on first use
/// * [Binding.toInstance]    — a `Future` registered as an instance
/// * [Binding.toProvideAsync] — an async factory
///
/// This is also where the functional error handling stops being functional:
/// the repository hands back `TaskEither`, and the binding decides what a
/// failure means for the whole app — here, run with a safe fallback. Absorbing
/// it at the composition root keeps every consumer downstream free of it.
class BootstrapModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<InstrumentRepository>()
        .toProvide(StaticInstrumentRepository.new)
        .singleton();

    // toInstance accepts a FutureOr, so a Future is a valid instance.
    // `.getOrElse(...)` turns TaskEither into a Task that cannot fail, and
    // `.run()` is what finally starts the work.
    bind<AppConfig>()
        .withName('remote')
        .toInstance(
          fetchRemoteConfig().getOrElse((_) => AppConfig.offline).run(),
        );

    bind<List<Instrument>>()
        .withName('remote')
        .toProvideAsync(
          () => currentScope
              .resolve<InstrumentRepository>()
              .loadAll()
              .getOrElse((_) => const <Instrument>[])
              .run(),
        )
        .singleton();
  }
}
