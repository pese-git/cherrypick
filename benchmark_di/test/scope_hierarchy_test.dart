import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/scenarios/universal_binding_mode.dart';
import 'package:benchmark_di/scenarios/universal_scenario.dart';
import 'package:benchmark_di/scenarios/universal_service.dart';
import 'package:test/test.dart';

import 'support/adapters.dart';

void main() {
  group('дочерний scope', () {
    for (final name in hierarchical) {
      test('$name: резолвит из родителя без собственных регистраций', () {
        final value = withAdapter(name, <T>(DIAdapter<T> parent) {
          parent.setupDependencies(parent.universalRegistration(
            scenario: UniversalScenario.chain,
            chainCount: 1,
            nestingDepth: 3,
            bindingMode: UniversalBindingMode.singletonStrategy,
          ));
          final child = parent.openSubScope('child');
          return child.resolve<UniversalService>().value;
        });
        expect(value, '1_3');
      });
    }

    for (final name in ['kiwi', 'yx_scope']) {
      test('$name: сценарий override объявлен неподдерживаемым', () {
        expect(
          () => withAdapter(
            name,
            <T>(DIAdapter<T> adapter) => adapter.universalRegistration(
              scenario: UniversalScenario.override,
              chainCount: 1,
              nestingDepth: 3,
              bindingMode: UniversalBindingMode.singletonStrategy,
            ),
          ),
          throwsUnsupportedError,
          reason: 'контейнер без иерархии обязан отказываться от сценария, '
              'а не подменять его плоским резолвом',
        );
      });
    }
  });
}
