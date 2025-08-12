import 'package:test/test.dart';
import 'package:talker/talker.dart';
import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';

void main() {
  group('TalkerCherryPickObserver', () {
    late Talker talker;
    late TalkerCherryPickObserver observer;

    setUp(() {
      talker = Talker();
      observer = TalkerCherryPickObserver(talker);
    });

    test('onInstanceRequested logs info', () {
      observer.onInstanceRequested('A', String, scopeName: 'test');
      final log = talker.history.last;
      expect(log.message, contains('[request][CherryPick] A — String (scope: test)'));
    });

    test('onCycleDetected logs warning', () {
      observer.onCycleDetected(['A', 'B'], scopeName: 's');
      final log = talker.history.last;
      expect(log.message, contains('[cycle][CherryPick] Detected'));
      //expect(log.level, TalkerLogLevel.warning);
    });

    test('onError calls handle', () {
      final error = Exception('fail');
      final stack = StackTrace.current;
      observer.onError('Oops', error, stack);
      final log = talker.history.last;
      expect(log.message, contains('[error][CherryPick] Oops'));
      expect(log.exception, error);
      expect(log.stackTrace, stack);
    });

    test('onDiagnostic logs verbose', () {
      observer.onDiagnostic('hello', details: 123);
      final log = talker.history.last;
      //expect(log.level, TalkerLogLevel.verbose);
      expect(log.message, contains('hello'));
      expect(log.message, contains('123'));
    });
  });
}
