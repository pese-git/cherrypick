import 'dart:io';

import 'package:test/test.dart';

void main() {
  final doc = File('METHODOLOGY.md');

  test('METHODOLOGY.md существует', () {
    expect(doc.existsSync(), isTrue);
  });

  group('объясняет каждое решение аппарата', () {
    final content = doc.existsSync() ? doc.readAsStringSync() : '';

    final requiredTopics = {
      'равный объём работы': 'equivalence_test',
      'разрешение таймера': 'elapsedTicks',
      'батчи steady-state': 'opsPerSample',
      'изоляция процессов': 'matrix.dart',
      'baseline памяти': 'baseline',
      'робастная статистика': 'MAD',
      'иерархия scope': 'override',
      'режим компиляции': 'AOT',
      'детектор циклов': 'cycleDetection',
      'строгий разбор CLI': 'exit 64',
      'освобождение контейнера': 'teardownAsync',
    };

    requiredTopics.forEach((topic, marker) {
      test('$topic упомянут через $marker', () {
        expect(content, contains(marker),
            reason: 'решение "$topic" не объяснено — следующий читатель '
                'откатит его как усложнение');
      });
    });
  });

  test('каждый раздел несёт мотивацию, а не только описание', () {
    final content = doc.existsSync() ? doc.readAsStringSync() : '';
    final sections = '## '.allMatches(content).length;
    expect(content.split('**Что было.**').length - 1, sections - 1,
        reason: 'у каждого решения должен быть блок "Что было"');
    expect(content, contains('**Почему это давало неверный результат.**'));
    expect(content, contains('**Как стало.**'));
  });
}
