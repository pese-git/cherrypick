import 'package:talker_cherrypick_logger/talker_cherrypick_logger.dart';
import 'package:talker/talker.dart';

void main() {
  final talker = Talker();
  final logger = TalkerCherryPickLogger(talker);

  logger.info('Hello from CherryPickLogger!');
  logger.warn('Something might be wrong...');
  logger.error('Oops! An error occurred', Exception('Test error'));

  // Вывод всех логов
  print('\nВсе сообщения логирования через Talker:');
  for (final log in talker.history) {
    print(log); // Пример, либо log.toString(), либо log.message
  }
}
