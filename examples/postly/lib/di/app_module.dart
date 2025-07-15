import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:dio/dio.dart';
import 'package:cherrypick/cherrypick.dart';
import '../data/network/json_placeholder_api.dart';
import '../data/post_repository_impl.dart';
import '../domain/repository/post_repository.dart';

part '../generated/di/app_module.module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @instance()
  int timeout() => 1000;

  @instance()
  @named('Delay')
  Future<int> delay() => Future.value(1000);

  @instance()
  @named('Size')
  Future<int> size() async => 10;

  @instance()
  @named('baseUrl')
  String baseUrl() => "https://google.com";

  @provide()
  @named('Delay1')
  Future<int> delay1() => Future.value(1000);

  @provide()
  @named('Size1')
  Future<int> size1() async => 10;

  @provide()
  @singleton()
  @named('dio')
  Dio dio(@named('baseUrl') String baseUrl) =>
      Dio(BaseOptions(baseUrl: baseUrl));

  @provide()
  @singleton()
  JsonPlaceholderApi api(@named('dio') Dio dio) => JsonPlaceholderApi(dio);

  @provide()
  @named('repo')
  PostRepository repo(JsonPlaceholderApi api) => PostRepositoryImpl(api);

  @provide()
  @named('TestProvideWithParams')
  String testProvideWithParams(@params() dynamic params) => "hello $params";

  @provide()
  @named('TestProvideAsyncWithParams')
  Future<String> testProvideAsyncWithParams(@params() dynamic params) async =>
      "hello $params";

  @provide()
  @named('TestProvideWithParams1')
  String testProvideWithParams1(
          @named('baseUrl') String baseUrl, @params() dynamic params) =>
      "hello $params";

  @provide()
  @named('TestProvideAsyncWithParams1')
  Future<String> testProvideAsyncWithParams1(
          @named('baseUrl') String baseUrl, @params() dynamic params) async =>
      "hello $params";
}
