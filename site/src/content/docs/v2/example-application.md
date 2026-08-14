---
title: Example Application
description: A complete CherryPick 2.x app wiring an API client, repository, and BLoC across scopes.
---

This example wires an API client, a repository, and a simple BLoC across a root
scope and a nested feature scope, using named instances, factory providers,
singletons, and sub-scopes.

```dart
import 'dart:async';
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
    bind<DataRepository>()
        .withName("networkRepo")
        .toProvide(
          () => NetworkDataRepository(
            currentScope.resolve<ApiClient>(
              named: isMock ? "apiClientMock" : "apiClientImpl",
            ),
          ),
        )
        .singleton();

    bind<DataBloc>().toProvide(
      () => DataBloc(
        currentScope.resolve<DataRepository>(named: "networkRepo"),
      ),
    );
  }
}

void main() async {
  final scope = CherryPick.openRootScope().installModules([
    AppModule(),
  ]);

  final subScope = scope
      .openSubScope("featureScope")
      .installModules([FeatureModule(isMock: true)]);

  final dataBloc = subScope.resolve<DataBloc>();
  dataBloc.data.listen(
    (d) => print('Received data: $d'),
    onError: (e) => print('Error: $e'),
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
  Future<String> getData() async => await _apiClient.sendRequest(
        url: 'www.google.com',
        token: _token,
        requestBody: {'type': 'data'},
      );
}

abstract class ApiClient {
  Future sendRequest({String? url, String? token, Map? requestBody});
}

class ApiClientMock implements ApiClient {
  @override
  Future sendRequest({String? url, String? token, Map? requestBody}) async {
    return 'Local Data';
  }
}

class ApiClientImpl implements ApiClient {
  @override
  Future sendRequest({String? url, String? token, Map? requestBody}) async {
    return 'Network data';
  }
}
```
