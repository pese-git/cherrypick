import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'data/network/json_placeholder_api.dart';
import 'data/post_repository_impl.dart';
import 'domain/repository/post_repository.dart';
import 'presentation/bloc/post_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'router/app_router.dart';

void main() {
  final dio = Dio();
  final api = JsonPlaceholderApi(dio);
  final repository = PostRepositoryImpl(api);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final PostRepository repository;
  final _appRouter = AppRouter();

  MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostBloc(repository),
      child: MaterialApp.router(
        routeInformationParser: _appRouter.defaultRouteParser(),
        routerDelegate: _appRouter.delegate(),
        theme: ThemeData.light(),
      ),
    );
  }
}
