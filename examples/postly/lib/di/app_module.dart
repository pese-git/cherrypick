import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:dio/dio.dart';
import 'package:cherrypick/cherrypick.dart';
import '../data/network/json_placeholder_api.dart';
import '../data/post_repository_impl.dart';
import '../domain/repository/post_repository.dart';

part 'app_module.cherrypick.g.dart';

@module()
abstract class AppModule extends Module {
  @singleton()
  @named('dio')
  Dio dio() => Dio();

  @singleton()
  @named('api')
  JsonPlaceholderApi api(@named('dio') Dio dio) => JsonPlaceholderApi(dio);

  @named('repo')
  @singleton()
  PostRepository repo(@named('api') JsonPlaceholderApi api) =>
      PostRepositoryImpl(api);
}
