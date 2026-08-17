import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_session.freezed.dart';

/// The signed-in user.
///
/// Lives in the `session` subscope: signing out closes that scope, which
/// disposes everything created for the user in one call.
@freezed
abstract class UserSession with _$UserSession {
  const factory UserSession({
    required String userId,
    required String displayName,
    required DateTime openedAt,
  }) = _UserSession;
}
