import 'package:cherrypick/cherrypick.dart';
import 'package:test/test.dart';

void main() {
  // --- Instance binding (synchronous) ---
  group('Instance Binding (toInstance)', () {
    group('Without name', () {
      test('Returns null by default', () {
        final binding = Binding<int>();
        expect(binding.resolver, null);
      });

      test('Sets mode to instance', () {
        final binding = Binding<int>().toInstance(5);
        expect(binding.resolver, isA<InstanceResolver<int>>());
      });

      test('isSingleton is true', () {
        final binding = Binding<int>().toInstance(5);
        expect(binding.isSingleton, true);
      });

      test('Stores value', () {
        final binding = Binding<int>().toInstance(5);
        expect(binding.resolver?.resolveSync(), 5);
      });
    });

    group('With name', () {
      test('Returns null by default', () {
        final binding = Binding<int>().withName('n');
        expect(binding.resolver, null);
      });

      test('Sets mode to instance', () {
        final binding = Binding<int>().withName('n').toInstance(5);
        expect(binding.resolver, isA<InstanceResolver<int>>());
      });

      test('Sets key', () {
        final binding = Binding<int>().withName('n').toInstance(5);
        expect(binding.key, int);
      });

      test('isSingleton is true', () {
        final binding = Binding<int>().withName('n').toInstance(5);
        expect(binding.isSingleton, true);
      });

      test('Stores value', () {
        final binding = Binding<int>().withName('n').toInstance(5);
        expect(binding.resolver?.resolveSync(), 5);
      });

      test('Sets name', () {
        final binding = Binding<int>().withName('n').toInstance(5);
        expect(binding.name, 'n');
      });
    });

    test('Multiple toInstance calls change value', () {
      final binding = Binding<int>().toInstance(1).toInstance(2);
      expect(binding.resolver?.resolveSync(), 2);
    });
  });

  // --- Instance binding (asynchronous) ---
  group('Async Instance Binding (toInstanceAsync)', () {
    test('Resolves instanceAsync with expected value', () async {
      final binding = Binding<int>().toInstance(Future.value(42));
      expect(await binding.resolveAsync(), 42);
    });

    test('Sets mode to instance', () {
      final binding = Binding<int>().toInstance(Future.value(5));
      expect(binding.resolver, isA<InstanceResolver<int>>());
    });

    test('isSingleton is true after toInstanceAsync', () {
      final binding = Binding<int>().toInstance(Future.value(5));
      expect(binding.isSingleton, isTrue);
    });

    test('Composes with withName', () async {
      final binding =
          Binding<int>().withName('asyncValue').toInstance(Future.value(7));
      expect(binding.isNamed, isTrue);
      expect(binding.name, 'asyncValue');
      expect(await binding.resolveAsync(), 7);
    });

    test('Keeps value after multiple awaits', () async {
      final binding = Binding<int>().toInstance(Future.value(123));
      final result1 = await binding.resolveAsync();
      final result2 = await binding.resolveAsync();
      expect(result1, equals(result2));
    });
  });

  // --- Provider binding (synchronous) ---
  group('Provider Binding (toProvide)', () {
    group('Without name', () {
      test('Returns null by default', () {
        final binding = Binding<int>();
        expect(binding.resolver, null);
      });

      test('Sets mode to providerInstance', () {
        final binding = Binding<int>().toProvide(() => 5);
        expect(binding.resolver, isA<ProviderResolver<int>>());
      });

      test('isSingleton is false by default', () {
        final binding = Binding<int>().toProvide(() => 5);
        expect(binding.isSingleton, false);
      });

      test('Returns provided value', () {
        final binding = Binding<int>().toProvide(() => 5);
        expect(binding.resolveSync(), 5);
      });
    });

    group('With name', () {
      test('Returns null by default', () {
        final binding = Binding<int>().withName('n');
        expect(binding.resolver, null);
      });

      test('Sets mode to providerInstance', () {
        final binding = Binding<int>().withName('n').toProvide(() => 5);
        expect(binding.resolver, isA<ProviderResolver<int>>());
      });

      test('Sets key', () {
        final binding = Binding<int>().withName('n').toProvide(() => 5);
        expect(binding.key, int);
      });

      test('isSingleton is false by default', () {
        final binding = Binding<int>().withName('n').toProvide(() => 5);
        expect(binding.isSingleton, false);
      });

      test('Returns provided value', () {
        final binding = Binding<int>().withName('n').toProvide(() => 5);
        expect(binding.resolveSync(), 5);
      });

      test('Sets name', () {
        final binding = Binding<int>().withName('n').toProvide(() => 5);
        expect(binding.name, 'n');
      });
    });
  });

  // --- Async provider binding ---
  group('Async Provider Binding', () {
    test('Resolves asyncProvider value', () async {
      final binding = Binding<int>().toProvide(() async => 5);
      expect(await binding.resolveAsync(), 5);
    });

    test('Resolves asyncProviderWithParams value', () async {
      final binding = Binding<int>()
          .toProvideWithParams((param) async => 5 + (param as int));
      expect(await binding.resolveAsync(3), 8);
    });
  });

  // --- Singleton provider binding ---
  group('Singleton Provider Binding', () {
    group('Without name', () {
      test('Returns null if no provider set', () {
        final binding = Binding<int>().singleton();
        expect(binding.resolver, null);
      });

      test('isSingleton is true', () {
        final binding = Binding<int>().toProvide(() => 5).singleton();
        expect(binding.isSingleton, true);
      });

      test('Returns singleton value', () {
        final binding = Binding<int>().toProvide(() => 5).singleton();
        expect(binding.resolveSync(), 5);
      });

      test('Returns same value each call and provider only called once', () {
        int counter = 0;
        final binding = Binding<int>().toProvide(() {
          counter++;
          return counter;
        }).singleton();

        final first = binding.resolveSync();
        final second = binding.resolveSync();
        expect(first, equals(second));
        expect(counter, 1);
      });
    });

    group('With name', () {
      test('Returns null if no provider set', () {
        final binding = Binding<int>().withName('n').singleton();
        expect(binding.resolver, null);
      });

      test('Sets key', () {
        final binding =
            Binding<int>().withName('n').toProvide(() => 5).singleton();
        expect(binding.key, int);
      });

      test('isSingleton is true', () {
        final binding =
            Binding<int>().withName('n').toProvide(() => 5).singleton();
        expect(binding.isSingleton, true);
      });

      test('Returns singleton value', () {
        final binding =
            Binding<int>().withName('n').toProvide(() => 5).singleton();
        expect(binding.resolveSync(), 5);
      });

      test('Sets name', () {
        final binding =
            Binding<int>().withName('n').toProvide(() => 5).singleton();
        expect(binding.name, 'n');
      });
    });
  });

  // --- WithName / Named binding, isNamed, edge-cases ---
  group('Named binding & helpers', () {
    test('withName sets isNamed true and stores name', () {
      final binding = Binding<int>().withName('foo');
      expect(binding.isNamed, true);
      expect(binding.name, 'foo');
    });

    test('providerWithParams returns null if not set', () {
      final binding = Binding<int>();
      expect(binding.resolveSync(123), null);
    });
  });
}
