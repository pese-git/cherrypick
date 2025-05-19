import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

import '../model/post_model.dart';

part 'json_placeholder_api.g.dart';

@RestApi(baseUrl: 'https://jsonplaceholder.typicode.com/')
abstract class JsonPlaceholderApi {
  factory JsonPlaceholderApi(Dio dio, {String baseUrl}) = _JsonPlaceholderApi;

  @GET('/posts')
  Future<List<PostModel>> getPosts();

  @GET('/posts/{id}')
  Future<PostModel> getPost(@Path('id') int id);
}
