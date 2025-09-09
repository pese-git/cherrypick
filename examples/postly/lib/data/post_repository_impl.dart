import 'package:dartz/dartz.dart';
import '../domain/entity/post.dart';
import '../domain/repository/post_repository.dart';
import 'network/json_placeholder_api.dart';

class PostRepositoryImpl implements PostRepository {
  final JsonPlaceholderApi api;

  PostRepositoryImpl(this.api);

  @override
  Future<Either<Exception, List<Post>>> getPosts() async {
    try {
      final posts = await api.getPosts();
      return Right(
        posts.map((e) => Post(id: e.id, title: e.title, body: e.body)).toList(),
      );
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Post>> getPost(int id) async {
    try {
      final post = await api.getPost(id);
      return Right(Post(id: post.id, title: post.title, body: post.body));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
