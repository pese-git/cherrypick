import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/material.dart';
import 'di/app_module.dart';
import 'domain/repository/post_repository.dart';
import 'presentation/bloc/post_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'router/app_router.dart';

void main() {
  final scope = CherryPick.openRootScope();
  scope.installModules([$AppModule()]);

  runApp(MyApp(scope: scope));
}

class MyApp extends StatelessWidget {
  final Scope scope;
  final _appRouter = AppRouter();

  MyApp({super.key, required this.scope});

  @override
  Widget build(BuildContext context) {
    // Получаем репозиторий через injector
    final repository = scope.resolve<PostRepository>();

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
