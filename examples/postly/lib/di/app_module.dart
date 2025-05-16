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
  Dio dio() => Dio();

  @singleton()
  JsonPlaceholderApi api(Dio dio) => JsonPlaceholderApi(dio);

  @singleton()
  PostRepository repo(JsonPlaceholderApi api) => PostRepositoryImpl(api);
}
