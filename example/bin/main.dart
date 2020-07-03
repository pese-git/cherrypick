import 'dart:async';
import 'package:meta/meta.dart';
import 'package:dart_di/dart_di.dart';

void main() async {
  final dataModule = new DiContainer()
    ..bind<ApiClient>().toValue(new ApiClientMock())
    ..bind<DataRepository>()
        .toFactory1<ApiClient>((c) => new NetworkDataRepository(c))
    ..bind<DataBloc>().toFactory1<DataRepository>((s) => new DataBloc(s));

  final dataBloc = dataModule.resolve<DataBloc>();
  dataBloc.data.listen((d) => print('Received data: $d'),
      onError: (e) => print('Error: $e'), onDone: () => print('DONE'));

  await dataBloc.fetchData();
}

class DataBloc {
  final DataRepository _dataRepository;

  Stream<String> get data => _dataController.stream;
  StreamController<String> _dataController = new StreamController.broadcast();

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
      {@required String url, String token, Map requestBody}) async {
    return 'hello world';
  }
}
