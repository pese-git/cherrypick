import 'package:cherrypick/src/binding.dart';
import 'package:test/test.dart';

void main() {
  group('Check instance.', () {
    group('Without name.', () {
      test('Binding resolves null', () {
        final binding = Binding<int>();
        expect(binding.instance, null);
      });

      test('Binding check mode', () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);

        expect(binding.mode, Mode.instance);
      });

      test('Binding check singleton', () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);

        expect(binding.isSingleton, true);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);

        expect(binding.instance, expectedValue);
      });

      test('Binding resolves value', () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);
        expect(binding.instance, expectedValue);
      });
    });

    group('With name.', () {
      test('Binding resolves null', () {
        final binding = Binding<int>().withName('expectedValue');
        expect(binding.instance, null);
      });

      test('Binding check mode', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName('expectedValue').toInstance(expectedValue);

        expect(binding.mode, Mode.instance);
      });

      test('Binding check key', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName('expectedValue').toInstance(expectedValue);

        expect(binding.key, int);
      });

      test('Binding check singleton', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName('expectedValue').toInstance(expectedValue);

        expect(binding.isSingleton, true);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName('expectedValue').toInstance(expectedValue);

        expect(binding.instance, expectedValue);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName('expectedValue').toInstance(expectedValue);

        expect(binding.name, 'expectedValue');
      });

      test('Binding resolves value', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName('expectedValue').toInstance(expectedValue);
        expect(binding.instance, expectedValue);
      });
    });
  });

  group('Check provide.', () {
    group('Without name.', () {
      test('Binding resolves null', () {
        final binding = Binding<int>();
        expect(binding.provider, null);
      });

      test('Binding check mode', () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);

        expect(binding.mode, Mode.providerInstance);
      });

      test('Binding check singleton', () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);

        expect(binding.isSingleton, false);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);

        expect(binding.provider, expectedValue);
      });

      test('Binding resolves value', () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);
        expect(binding.provider, expectedValue);
      });
    });

    group('With name.', () {
      test('Binding resolves null', () {
        final binding = Binding<int>().withName('expectedValue');
        expect(binding.provider, null);
      });

      test('Binding check mode', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue);

        expect(binding.mode, Mode.providerInstance);
      });

      test('Binding check key', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue);

        expect(binding.key, int);
      });

      test('Binding check singleton', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue);

        expect(binding.isSingleton, false);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue);

        expect(binding.provider, expectedValue);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue);

        expect(binding.name, 'expectedValue');
      });

      test('Binding resolves value', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue);
        expect(binding.provider, expectedValue);
      });
    });
  });

  group('Check Async provider.', () {
    test('Binding resolves value asynchronously', () async {
      final expectedValue = 5;
      final binding = Binding<int>().toProvideAsync(() async => expectedValue);

      final result = await binding.asyncProvider?.call();
      expect(result, expectedValue);
    });

    test('Binding resolves value asynchronously with params', () async {
      final expectedValue = 5;
      final binding = Binding<int>().toProvideAsyncWithParams(
          (param) async => expectedValue + (param as int));

      final result = await binding.asyncProviderWithParams?.call(3);
      expect(result, expectedValue + 3);
    });
  });

  group('Check singleton provide.', () {
    group('Without name.', () {
      test('Binding resolves null', () {
        final binding = Binding<int>().singleton();
        expect(binding.provider, null);
      });

      test('Binding check mode', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singleton();

        expect(binding.mode, Mode.providerInstance);
      });

      test('Binding check singleton', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singleton();

        expect(binding.isSingleton, true);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singleton();

        expect(binding.provider, expectedValue);
      });

      test('Binding resolves value', () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singleton();
        expect(binding.provider, expectedValue);
      });
    });

    group('With name.', () {
      test('Binding resolves null', () {
        final binding = Binding<int>().withName('expectedValue').singleton();
        expect(binding.provider, null);
      });

      test('Binding check mode', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue)
            .singleton();

        expect(binding.mode, Mode.providerInstance);
      });

      test('Binding check key', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue)
            .singleton();

        expect(binding.key, int);
      });

      test('Binding check singleton', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue)
            .singleton();

        expect(binding.isSingleton, true);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue)
            .singleton();

        expect(binding.provider, expectedValue);
      });

      test('Binding check value', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue)
            .singleton();

        expect(binding.name, 'expectedValue');
      });

      test('Binding resolves value', () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName('expectedValue')
            .toProvide(() => expectedValue)
            .singleton();
        expect(binding.provider, expectedValue);
      });
    });
  });

  test('Binding returns null providerWithParams if not set', () {
    final binding = Binding<int>();
    expect(binding.providerWithParams(123), null);
  });

  test('Binding withName changes isNamed to true', () {
    final binding = Binding<int>().withName('foo');
    expect(binding.isNamed, true);
    expect(binding.name, 'foo');
  });

  // Проверка singleton provider вызывается один раз
  test('Singleton provider only called once', () {
    int counter = 0;
    final binding = Binding<int>().toProvide(() {
      counter++;
      return counter;
    }).singleton();

    final first = binding.provider;
    final second = binding.provider;
    expect(first, equals(second));
    expect(counter, 1);
  });

  // Повторный вызов toInstance влияет на значение
  test('Multiple toInstance calls changes instance', () {
    final binding = Binding<int>().toInstance(1).toInstance(2);
    expect(binding.instance, 2);
  });

  // Проверка mode после chaining
  test('Chained withName and singleton preserves mode', () {
    final binding =
        Binding<int>().toProvide(() => 3).withName("named").singleton();
    expect(binding.mode, Mode.providerInstance);
  });

  group('Check toInstanceAsync.', () {
    test('Binding resolves instanceAsync with expected value', () async {
      final expectedValue = 42;
      final binding =
          Binding<int>().toInstanceAsync(Future.value(expectedValue));
      final result = await binding.instanceAsync;
      expect(result, equals(expectedValue));
    });

    test('Binding instanceAsync does not affect instance', () {
      final binding = Binding<int>().toInstanceAsync(Future.value(5));
      expect(binding.instance, null);
    });

    test('Binding mode is set to instance', () {
      final binding = Binding<int>().toInstanceAsync(Future.value(5));
      expect(binding.mode, Mode.instance);
    });

    test('Binding isSingleton is true after toInstanceAsync', () {
      final binding = Binding<int>().toInstanceAsync(Future.value(5));
      expect(binding.isSingleton, isTrue);
    });

    test('Binding withName combines with toInstanceAsync', () async {
      final binding = Binding<int>()
          .withName('asyncValue')
          .toInstanceAsync(Future.value(7));
      expect(binding.isNamed, isTrue);
      expect(binding.name, 'asyncValue');
      expect(await binding.instanceAsync, 7);
    });

    test('Binding instanceAsync keeps value after multiple awaits', () async {
      final binding = Binding<int>().toInstanceAsync(Future.value(123));
      final result1 = await binding.instanceAsync;
      final result2 = await binding.instanceAsync;
      expect(result1, equals(result2));
    });
  });
}
