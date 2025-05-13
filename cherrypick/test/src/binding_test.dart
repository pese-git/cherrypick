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
}
