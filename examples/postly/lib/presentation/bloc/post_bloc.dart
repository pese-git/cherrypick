import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entity/post.dart';
import '../../domain/repository/post_repository.dart';

part 'post_bloc.freezed.dart';

@freezed
class PostEvent with _$PostEvent {
  const factory PostEvent.fetchAll() = _FetchAll;
}

@freezed
class PostState with _$PostState {
  const factory PostState.initial() = _Initial;
  const factory PostState.loading() = _Loading;
  const factory PostState.loaded(List<Post> posts) = _Loaded;
  const factory PostState.failure(String message) = _Failure;
}

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository repository;

  PostBloc(this.repository) : super(const PostState.initial()) {
    on<PostEvent>((event, emit) async {
      await event.map(
        fetchAll: (e) async {
          emit(const PostState.loading());
          final result = await repository.getPosts();
          result.fold(
            (l) => emit(PostState.failure(l.toString())),
            (r) => emit(PostState.loaded(r)),
          );
        },
      );
    });
  }
}
