import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';

import '../../core/di/scope_names.dart';
import '../../core/format/quote_formatter.dart';
import '../../domain/entity/user_session.dart';
import 'watchlist_cubit.dart';

part 'session_header_model.inject.cherrypick.g.dart';

/// Field injection, generated rather than written.
///
/// `build_runner` produces the `_$SessionHeaderModel` mixin with an `_inject`
/// method that fills each annotated field from the right place:
/// * `@scope('session')` → resolved from the session subscope
/// * `@named('appName')` → resolved by name from the root scope
/// * plain `@inject()`   → resolved by type from the root scope
///
/// Note the limit this illustrates: `@scope` takes a compile-time constant, so
/// generated injection fits fixed scope paths. Dynamic ones — a scope per
/// symbol — are opened through the runtime API in `WorkspaceCubit`.
@injectable()
class SessionHeaderModel with _$SessionHeaderModel {
  @inject()
  @scope(ScopeNames.session)
  late final UserSession session;

  @inject()
  @scope(ScopeNames.session)
  late final WatchlistCubit watchlist;

  @inject()
  @named('appName')
  late final String appName;

  @inject()
  late final QuoteFormatter formatter;

  SessionHeaderModel() {
    _inject(this);
  }
}
