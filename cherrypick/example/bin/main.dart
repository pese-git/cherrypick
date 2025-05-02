import 'dart:async';

import 'package:cherrypick/cherrypick.dart';
import 'package:meta/meta.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<ApiClient>().withName('apiClientMock').toInstance(ApiClientMock());
    bind<ApiClient>().withName('apiClientImpl').toInstance(ApiClientImpl());
  }
}

class FeatureModule extends Module {
  bool isMock;

  FeatureModule({required this.isMock});

  @override
  void builder(Scope currentScope) {
    bind<DataRepository>()
        .withName('networkRepo')
        .toProvide(
          () => NetworkDataRepository(
            currentScope.resolve<ApiClient>(
              named: isMock ? 'apiClientMock' : 'apiClientImpl',
            ),
          ),
        )
        .singleton();

    bind<DataBloc>().toProvideWithParams(
      (param) => DataBloc(
        currentScope.resolve<DataRepository>(named: 'networkRepo'),
        param,
      ),
    );
  }
}

void main() async {
  final scope = openRootScope().installModules([
    AppModule(),
  ]);

  final subScope = scope
      .openSubScope('featureScope')
      .installModules([FeatureModule(isMock: true)]);

  final dataBloc = subScope.resolve<DataBloc>(params: 'PARAMETER');
  dataBloc.data.listen((d) => print('Received data: $d'),
      onError: (e) => print('Error: $e'), onDone: () => print('DONE'));

  await dataBloc.fetchData();
}

class DataBloc {
  final DataRepository _dataRepository;

  Stream<String> get data => _dataController.stream;
  final StreamController<String> _dataController = StreamController.broadcast();

  final String param;

  DataBloc(this._dataRepository, this.param);

  Future<void> fetchData() async {
    try {
      _dataController.sink.add(await _dataRepository.getData(param));
    } catch (e) {
      _dataController.sink.addError(e);
    }
  }

  void dispose() {
    _dataController.close();
  }
}

abstract class DataRepository {
  Future<String> getData(String param);
}

class NetworkDataRepository implements DataRepository {
  final ApiClient _apiClient;
  final _token = 'token';

  NetworkDataRepository(this._apiClient);

  @override
  Future<String> getData(String param) async => await _apiClient.sendRequest(
      url: 'www.google.com',
      token: _token,
      requestBody: {'type': 'data'},
      param: param);
}

abstract class ApiClient {
  Future sendRequest({
    @required String url,
    String token,
    Map requestBody,
    String param,
  });
}

class ApiClientMock implements ApiClient {
  @override
  Future sendRequest({
    @required String? url,
    String? token,
    Map? requestBody,
    String? param,
  }) async {
    return 'Local Data $param';
  }
}

class ApiClientImpl implements ApiClient {
  @override
  Future sendRequest({
    @required String? url,
    String? token,
    Map? requestBody,
    String? param,
  }) async {
    return 'Network data $param';
  }
}
