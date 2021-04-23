import 'package:dart_di/experimental/binding.dart';
import 'package:test/test.dart';

void main() {
  group("Check instance.", () {
    group("Without name.", () {
      test("Binding resolves null", () {
        final binding = Binding<int>();
        expect(binding.instance, null);
      });

      test("Binding check mode", () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);

        expect(binding.mode, Mode.INSTANCE);
      });

      test("Binding check singeltone", () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);

        expect(binding.isSingeltone, true);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);

        expect(binding.instance, expectedValue);
      });

      test("Binding resolves value", () {
        final expectedValue = 5;
        final binding = Binding<int>().toInstance(expectedValue);
        expect(binding.instance, expectedValue);
      });
    });

    group("With name.", () {
      test("Binding resolves null", () {
        final binding = Binding<int>().withName("expectedValue");
        expect(binding.instance, null);
      });

      test("Binding check mode", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName("expectedValue").toInstance(expectedValue);

        expect(binding.mode, Mode.INSTANCE);
      });

      test("Binding check key", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName("expectedValue").toInstance(expectedValue);

        expect(binding.key, int);
      });

      test("Binding check singeltone", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName("expectedValue").toInstance(expectedValue);

        expect(binding.isSingeltone, true);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName("expectedValue").toInstance(expectedValue);

        expect(binding.instance, expectedValue);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName("expectedValue").toInstance(expectedValue);

        expect(binding.name, "expectedValue");
      });

      test("Binding resolves value", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().withName("expectedValue").toInstance(expectedValue);
        expect(binding.instance, expectedValue);
      });
    });
  });

  group("Check provide.", () {
    group("Without name.", () {
      test("Binding resolves null", () {
        final binding = Binding<int>();
        expect(binding.provider, null);
      });

      test("Binding check mode", () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);

        expect(binding.mode, Mode.PROVIDER_INSTANCE);
      });

      test("Binding check singeltone", () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);

        expect(binding.isSingeltone, false);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);

        expect(binding.provider, expectedValue);
      });

      test("Binding resolves value", () {
        final expectedValue = 5;
        final binding = Binding<int>().toProvide(() => expectedValue);
        expect(binding.provider, expectedValue);
      });
    });

    group("With name.", () {
      test("Binding resolves null", () {
        final binding = Binding<int>().withName("expectedValue");
        expect(binding.provider, null);
      });

      test("Binding check mode", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue);

        expect(binding.mode, Mode.PROVIDER_INSTANCE);
      });

      test("Binding check key", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue);

        expect(binding.key, int);
      });

      test("Binding check singeltone", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue);

        expect(binding.isSingeltone, false);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue);

        expect(binding.provider, expectedValue);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue);

        expect(binding.name, "expectedValue");
      });

      test("Binding resolves value", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue);
        expect(binding.provider, expectedValue);
      });
    });
  });

  group("Check singeltone provide.", () {
    group("Without name.", () {
      test("Binding resolves null", () {
        final binding = Binding<int>().singeltone();
        expect(binding.provider, null);
      });

      test("Binding check mode", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singeltone();

        expect(binding.mode, Mode.PROVIDER_INSTANCE);
      });

      test("Binding check singeltone", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singeltone();

        expect(binding.isSingeltone, true);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singeltone();

        expect(binding.provider, expectedValue);
      });

      test("Binding resolves value", () {
        final expectedValue = 5;
        final binding =
            Binding<int>().toProvide(() => expectedValue).singeltone();
        expect(binding.provider, expectedValue);
      });
    });

    group("With name.", () {
      test("Binding resolves null", () {
        final binding = Binding<int>().withName("expectedValue").singeltone();
        expect(binding.provider, null);
      });

      test("Binding check mode", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue)
            .singeltone();

        expect(binding.mode, Mode.PROVIDER_INSTANCE);
      });

      test("Binding check key", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue)
            .singeltone();

        expect(binding.key, int);
      });

      test("Binding check singeltone", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue)
            .singeltone();

        expect(binding.isSingeltone, true);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue)
            .singeltone();

        expect(binding.provider, expectedValue);
      });

      test("Binding check value", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue)
            .singeltone();

        expect(binding.name, "expectedValue");
      });

      test("Binding resolves value", () {
        final expectedValue = 5;
        final binding = Binding<int>()
            .withName("expectedValue")
            .toProvide(() => expectedValue)
            .singeltone();
        expect(binding.provider, expectedValue);
      });
    });
  });
}
