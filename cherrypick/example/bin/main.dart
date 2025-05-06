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
    // Using toProvideAsync for async initialization
    bind<DataRepository>().withName("networkRepo").toProvideAsync(() async {
      final client = await Future.delayed(
          Duration(milliseconds: 100),
          () => currentScope.resolve<ApiClient>(
              named: isMock ? "apiClientMock" : "apiClientImpl"));
      return NetworkDataRepository(client);
    }).singleton();

    // Asynchronous initialization of DataBloc
    bind<DataBloc>().toProvideAsync(
      () async {
        final repo = await currentScope.resolveAsync<DataRepository>(
            named: "networkRepo");
        return DataBloc(repo);
      },
    );
  }
}

Future<void> main() async {
  try {
    final scope = openRootScope().installModules([
      AppModule(),
    ]);

    final subScope = scope
        .openSubScope("featureScope")
        .installModules([FeatureModule(isMock: true)]);

    // Asynchronous instance resolution
    final dataBloc = await subScope.resolveAsync<DataBloc>();
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
      url: 'www.google.com', token: _token, requestBody: {'type': 'data'});
}

abstract class ApiClient {
  Future sendRequest({@required String url, String token, Map requestBody});
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
