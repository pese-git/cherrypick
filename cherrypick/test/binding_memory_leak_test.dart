import 'dart:async';
import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

class HeavyService implements Disposable {
  static int instanceCount = 0;
  HeavyService() {
    instanceCount++;
    print('HeavyService created. Instance count: '
        '\u001b[32m$instanceCount\u001b[0m');
  }

  @override
  void dispose() {
    instanceCount--;
    print('HeavyService disposed. Instance count: '
        '\u001b[31m$instanceCount\u001b[0m');
  }

  static final Finalizer<String> _finalizer = Finalizer((msg) {
    print('GC FINALIZED HeavyService: $msg');
  });
  void registerFinalizer() => _finalizer.attach(this, toString(), detach: this);
}

class HeavyModule extends Module {
  @override
  void builder(Scope scope) {
    bind<HeavyService>().toProvide(() => HeavyService());
  }
}

void main() {
  test('Binding memory is cleared after closing and reopening scope', () async {
    final root = CherryPick.openRootScope();
    for (int i = 0; i < 10; i++) {
      print('\nIteration $i -------------------------------');
      final subScope = root.openSubScope('leak-test-scope');
      subScope.installModules([HeavyModule()]);
      final service = subScope.resolve<HeavyService>();
      expect(service, isNotNull);
      await root.closeSubScope('leak-test-scope');
      // Dart GC не сразу удаляет освобождённые объекты, добавляем паузу и вызываем GC.
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Если dispose не вызвался, instanceCount > 0 => утечка.
    expect(HeavyService.instanceCount, equals(0));
  });

  test('Service is finalized after scope is closed/cleaned', () async {
    final root = CherryPick.openRootScope();
    HeavyService? ref;
    {
      final sub = root.openSubScope('s');
      sub.installModules([HeavyModule()]);
      ref = sub.resolve<HeavyService>();
      ref.registerFinalizer();
      expect(HeavyService.instanceCount, 1);
      await root.closeSubScope('s');
    }
    await Future.delayed(const Duration(seconds: 2));
    expect(HeavyService.instanceCount, 0);
  });
}
