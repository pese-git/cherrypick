import 'package:cherrypick/cherrypick.dart';
import 'package:talker/talker.dart';

/// Реализация CherryPickLogger для логирования через Talker
class TalkerCherryPickLogger implements CherryPickLogger {
  final Talker talker;

  TalkerCherryPickLogger(this.talker);

  @override
  void info(String message) => talker.info('[CherryPick] $message');

  @override
  void warn(String message) => talker.warning('[CherryPick] $message');

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    talker.handle(
      error ?? '[CherryPick] $message',
      stackTrace,
      '[CherryPick] $message',
    );
  }
}
