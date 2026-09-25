import 'package:benchmark_di/di_adapters/cherrypick_adapter.dart';
import 'package:benchmark_di/di_adapters/di_adapter.dart';
import 'package:benchmark_di/di_adapters/get_it_adapter.dart';
import 'package:benchmark_di/di_adapters/kiwi_adapter.dart';
import 'package:benchmark_di/di_adapters/riverpod_adapter.dart';
import 'package:benchmark_di/di_adapters/yx_scope_adapter.dart';
import 'package:benchmark_di/di_adapters/yx_scope_universal_container.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:get_it/get_it.dart';
import 'package:kiwi/kiwi.dart';
import 'package:riverpod/riverpod.dart' as rp;

/// Имена всех адаптеров под тестом. Совпадают со значениями опции --di.
const adapterNames = ['cherrypick', 'getit', 'riverpod', 'kiwi', 'yx_scope'];

/// Адаптеры, поддерживающие асинхронные привязки.
const asyncCapable = ['cherrypick', 'getit', 'riverpod'];

/// Контейнеры, у которых дочерний scope видит регистрации родителя.
const hierarchical = ['cherrypick', 'getit', 'riverpod'];

/// Выполняет [body] со свежим адаптером [name], сохраняя статический тип
/// контейнера.
///
/// Хранить адаптеры в `Map<String, DIAdapter Function()>` нельзя: параметр
/// типа стирается до `dynamic`, и `setupDependencies` падает в рантайме на
/// `(Scope) => void is not a subtype of (dynamic) => void`. Обобщённый
/// параметр функции сохраняет тип на всём пути вызова.
R withAdapter<R>(String name, R Function<T>(DIAdapter<T> adapter) body) {
  switch (name) {
    case 'cherrypick':
      return body<Scope>(CherrypickDIAdapter());
    case 'getit':
      return body<GetIt>(GetItAdapter());
    case 'riverpod':
      return body<Map<String, rp.ProviderBase<Object?>>>(RiverpodAdapter());
    case 'kiwi':
      return body<KiwiContainer>(KiwiAdapter());
    case 'yx_scope':
      return body<UniversalYxScopeContainer>(YxScopeAdapter());
    default:
      throw ArgumentError('Неизвестный адаптер: $name');
  }
}
