import 'dart:async';

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
        expect(binding.resolver, isA<BindingResolver<int>>());
        expect(binding.resolver, isA<SyncInstanceResolver<int>>());
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
        expect(binding.resolver, isA<BindingResolver<int>>());
        expect(binding.resolver, isA<SyncInstanceResolver<int>>());
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
      expect(binding.resolver, isA<BindingResolver<int>>());
      expect(binding.resolver, isA<AsyncInstanceResolver<int>>());
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
        expect(binding.resolver, isA<BindingResolver<int>>());
        expect(binding.resolveSync(), 5);
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
        expect(binding.resolver, isA<BindingResolver<int>>());
        expect(binding.resolveSync(), 5);
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

    test('Resolves toProvideAsync value', () async {
      final binding = Binding<int>().toProvideAsync(() async => 5);
      expect(await binding.resolveAsync(), 5);
    });

    test('toProvideAsync singleton caches instance', () async {
      int counter = 0;
      final binding = Binding<int>().toProvideAsync(() async {
        counter++;
        return counter;
      }).singleton();

      final first = await binding.resolveAsync();
      final second = await binding.resolveAsync();
      expect(first, equals(second));
      expect(counter, 1);
    });

    test('Resolves toProvideAsyncWithParams value', () async {
      final binding = Binding<int>()
          .toProvideAsyncWithParams((param) async => 5 + (param as int));
      expect(await binding.resolveAsync(3), 8);
    });

    test('toProvideAsyncWithParams singleton caches instance', () async {
      int counter = 0;
      final binding = Binding<int>().toProvideAsyncWithParams((param) async {
        counter++;
        return counter + (param as int);
      }).singleton();

      final first = await binding.resolveAsync(10);
      final second = await binding.resolveAsync(20);
      expect(first, equals(second));
      expect(counter, 1);
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

  // --- FutureOr provider resolver (lazy detection, no eager side-effects) ---
  group('FutureOr Provider Resolver', () {
    test('Does not call provider at binding creation', () {
      int calls = 0;
      FutureOr<int> provider() {
        calls++;
        return 42;
      }

      final binding = Binding<int>().toProvide(provider);
      expect(calls, 0);
      expect(binding.resolveSync(), 42);
      expect(calls, 1);
    });

    test('Sync FutureOr provider resolves via resolveSync', () {
      final binding = Binding<int>().toProvide(() => 7);
      expect(binding.resolveSync(), 7);
    });

    test('Async FutureOr provider throws on resolveSync', () {
      final binding =
          Binding<int>().toProvide(() async => 7);
      expect(() => binding.resolveSync(), throwsStateError);
    });

    test('Async FutureOr provider resolves via resolveAsync', () async {
      final binding =
          Binding<int>().toProvide(() async => 7);
      expect(await binding.resolveAsync(), 7);
    });

    test('FutureOr provider with params does not call provider at creation',
        () {
      int calls = 0;
      FutureOr<int> provider(dynamic p) {
        calls++;
        return (p as int) + 1;
      }

      final binding = Binding<int>().toProvideWithParams(provider);
      expect(calls, 0);
      expect(binding.resolveSync(5), 6);
      expect(calls, 1);
    });

    test('Async FutureOr provider with params throws on resolveSync', () {
      final binding = Binding<int>()
          .toProvideWithParams((p) async => (p as int) + 1);
      expect(() => binding.resolveSync(5), throwsStateError);
    });

    test('Async FutureOr provider with params resolves via resolveAsync',
        () async {
      final binding = Binding<int>()
          .toProvideWithParams((p) async => (p as int) + 1);
      expect(await binding.resolveAsync(5), 6);
    });

    test('FutureOr singleton caches sync result', () {
      int calls = 0;
      final binding = Binding<int>().toProvide(() {
        calls++;
        return 99;
      }).singleton();

      expect(binding.resolveSync(), 99);
      expect(binding.resolveSync(), 99);
      expect(calls, 1);
    });

    test('FutureOr singleton caches async result', () async {
      int calls = 0;
      final binding = Binding<int>().toProvide(() async {
        calls++;
        return 99;
      }).singleton();

      expect(await binding.resolveAsync(), 99);
      expect(await binding.resolveAsync(), 99);
      expect(calls, 1);
    });
  });

  // --- InstanceResolver factory ---
  group('InstanceResolver.create', () {
    test('Returns SyncInstanceResolver for sync value', () {
      final binding = Binding<int>().toInstance(5);
      expect(binding.resolver, isA<SyncInstanceResolver<int>>());
    });

    test('Returns AsyncInstanceResolver for Future value', () {
      final binding = Binding<int>().toInstance(Future.value(5));
      expect(binding.resolver, isA<AsyncInstanceResolver<int>>());
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
