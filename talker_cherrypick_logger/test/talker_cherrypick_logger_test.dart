import 'package:test/test.dart';
import 'package:talker/talker.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';

void main() {
  group('TalkerCherryPickLogger', () {
    late Talker talker;
    late TalkerCherryPickLogger logger;

    setUp(() {
      talker = Talker();
      logger = TalkerCherryPickLogger(talker);
    });

    test('logs info messages correctly', () {
      logger.info('Test info');
      final log = talker.history.last;
      expect(log.message, contains('[CherryPick] Test info'));
      //xpect(log.level, TalkerLogLevel.info);
    });

    test('logs warning messages correctly', () {
      logger.warn('Danger!');
      final log = talker.history.last;
      expect(log.message, contains('[CherryPick] Danger!'));
      //expect(log.level, TalkerLogLevel.warning);
    });

    test('logs error messages correctly', () {
      final error = Exception('some error');
      final stack = StackTrace.current;
      logger.error('ERR', error, stack);
      final log = talker.history.last;
      //expect(log.level, TalkerLogLevel.error);
      expect(log.message, contains('[CherryPick] ERR'));
      expect(log.exception, error);
      expect(log.stackTrace, stack);
    });
  });
}
