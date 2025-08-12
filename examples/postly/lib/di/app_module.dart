import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:dio/dio.dart';
import 'package:cherrypick/cherrypick.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../data/network/json_placeholder_api.dart';
import '../data/post_repository_impl.dart';
import '../domain/repository/post_repository.dart';

part 'app_module.module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @provide()
  @singleton()
  TalkerDioLoggerSettings talkerDioLoggerSettings() => TalkerDioLoggerSettings(
      printRequestHeaders: true,
      printResponseHeaders: true,
      printResponseMessage: true,
  );

  @provide()
  @singleton()
  TalkerDioLogger talkerDioLogger(Talker talker, TalkerDioLoggerSettings settings) => TalkerDioLogger(talker: talker, settings: settings);

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
  Dio dio(@named('baseUrl') String baseUrl, TalkerDioLogger logger) =>
      Dio(BaseOptions(baseUrl: baseUrl))..interceptors.add(logger);

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
