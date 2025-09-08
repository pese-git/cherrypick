---
sidebar_position: 6
---

# Пример приложения

Ниже приведён полный пример с модулями, подскоупами, асинхронными провайдерами и разрешением зависимостей.

```dart
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:cherrypick/cherrypick.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().withName("apiClientMock").toInstance(ApiClientMock());
    bind<ApiClient>().withName("apiClientImpl").toInstance(ApiClientImpl());
  }
}

class FeatureModule extends Module {
  final bool isMock;
  FeatureModule({required this.isMock});
  @override
  void builder(Scope currentScope) {
    // Асинхронный провайдер DataRepository с выбором зависимости по имени
    bind<DataRepository>()
        .withName("networkRepo")
        .toProvideAsync(() async {
          final client = await Future.delayed(
            Duration(milliseconds: 100),
            () => currentScope.resolve<ApiClient>(
              named: isMock ? "apiClientMock" : "apiClientImpl",
            ),
          );
          return NetworkDataRepository(client);
        })
        .singleton();

    // Вызов асинхронного провайдера для DataBloc
    bind<DataBloc>().toProvideAsync(
      () async {
        final repo = await currentScope.resolveAsync<DataRepository>(
            named: "networkRepo");
        return DataBloc(repo);
      },
    );
  }
}

void main() async {
  final scope = CherryPick.openRootScope().installModules([AppModule()]);
  final featureScope = scope.openSubScope("featureScope")
    ..installModules([FeatureModule(isMock: true)]);

  final dataBloc = await featureScope.resolveAsync<DataBloc>();
  dataBloc.data.listen(
    (d) => print('Получены данные: $d'),
    onError: (e) => print('Ошибка: $e'),
    onDone: () => print('DONE'),
  );

  await dataBloc.fetchData();
}

class DataBloc {
  final DataRepository _dataRepository;
  Stream<String> get data => _dataController.stream;
  final StreamController<String> _dataController = StreamController.broadcast();

  DataBloc(this._dataRepository);

  Future<void> fetchData() async {
    try {
      _dataController.sink.add(await _dataRepository.getData());
    } catch (e) {
      _dataController.sink.addError(e);
    }
  }

  void dispose() {
    _dataController.close();
  }
}

abstract class DataRepository {
  Future<String> getData();
}

class NetworkDataRepository implements DataRepository {
  final ApiClient _apiClient;
  final _token = 'token';
  NetworkDataRepository(this._apiClient);

  @override
  Future<String> getData() async =>
      await _apiClient.sendRequest(
        url: 'www.google.com',
        token: _token,
        requestBody: {'type': 'data'},
      );
}

abstract class ApiClient {
  Future sendRequest({@required String? url, String? token, Map? requestBody});
}

class ApiClientMock implements ApiClient {
  @override
  Future sendRequest(
      {@required String? url, String? token, Map? requestBody}) async {
    return 'Local Data';
  }
}

class ApiClientImpl implements ApiClient {
  @override
  Future sendRequest(
      {@required String? url, String? token, Map? requestBody}) async {
    return 'Network data';
  }
}
```
