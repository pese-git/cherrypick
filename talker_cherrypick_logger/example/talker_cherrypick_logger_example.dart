import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';
import 'package:talker/talker.dart';

void main() {
  final talker = Talker();
  final logger = TalkerCherryPickObserver(talker);

  logger.onDiagnostic('Hello from CherryPickLogger!');
  logger.onWarning('Something might be wrong...');
  logger.onError('Oops! An error occurred', Exception('Test error'), null);

  // Вывод всех логов
  print('\nВсе сообщения логирования через Talker:');
  for (final log in talker.history) {
    print(log); // Пример, либо log.toString(), либо log.message
  }
}
