import 'package:dartz/dartz.dart';
import '../entity/post.dart';

abstract class PostRepository {
  Future<Either<Exception, List<Post>>> getPosts();
  Future<Either<Exception, Post>> getPost(int id);
}
