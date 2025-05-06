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
  final bool isMock;

  FeatureModule({required this.isMock});

  @override
  void builder(Scope currentScope) {
    // DataRepository remains async for demonstration
    bind<DataRepository>().withName('networkRepo').toProvideAsync(
      () async {
        // Using synchronous resolve for ApiClient
        final apiClient = currentScope.resolve<ApiClient>(
          named: isMock ? 'apiClientMock' : 'apiClientImpl',
        );
        return NetworkDataRepository(apiClient);
      },
    ).singleton();

    bind<DataBloc>().toProvideAsyncWithParams(
      (param) async {
        final dataRepository = await currentScope.resolveAsync<DataRepository>(
            named: 'networkRepo');
        return DataBloc(dataRepository, param);
      },
    );
  }
}

Future<void> main() async {
  final scope = openRootScope().installModules([
    AppModule(),
  ]);

  final subScope = scope
      .openSubScope('featureScope')
      .installModules([FeatureModule(isMock: true)]);

  try {
    final dataBloc = await subScope.resolveAsync<DataBloc>(params: 'PARAMETER');
    dataBloc.data.listen((d) => print('Received data: $d'),
        onError: (e) => print('Error: $e'), onDone: () => print('DONE'));

    await dataBloc.fetchData();
  } catch (e) {
    print('Error resolving dependency: $e');
  }
}

class DataBloc {
  final DataRepository _dataRepository;

  final StreamController<String> _dataController = StreamController.broadcast();
  Stream<String> get data => _dataController.stream;

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
  Future sendRequest({
    @required String? url,
    String? token,
    Map? requestBody,
    String? param,
  }) async {
    return 'Network data $param';
  }
}
