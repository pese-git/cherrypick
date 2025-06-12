import 'package:cherrypick/cherrypick.dart';
import 'package:cherrypick_annotations/cherrypick_annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'domain/repository/post_repository.dart';
import 'presentation/bloc/post_bloc.dart';
import 'router/app_router.dart';

part 'app.inject.cherrypick.g.dart';

@injectable()
class MyApp extends StatelessWidget with _$MyApp {
  final _appRouter = AppRouter();

  @named('repo')
  @inject()
  late final PostRepository repository;

  MyApp({super.key}) {
    _inject(this);
  }

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
