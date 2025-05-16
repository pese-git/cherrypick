import 'package:dio/dio.dart';
import 'package:cherrypick/cherrypick.dart';
import '../data/network/json_placeholder_api.dart';
import '../data/post_repository_impl.dart';
import '../domain/repository/post_repository.dart';

class AppModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<Dio>().toProvide(() => Dio()).singleton();

    bind<JsonPlaceholderApi>()
        .toProvide(() => JsonPlaceholderApi(currentScope.resolve<Dio>()))
        .singleton();

    bind<PostRepository>()
        .toProvide(() =>
            PostRepositoryImpl(currentScope.resolve<JsonPlaceholderApi>()))
        .singleton();
  }
}
