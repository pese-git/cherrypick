import 'package:auto_route/auto_route.dart';
import '../presentation/pages/logs_page.dart';
import 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: PostsRoute.page, initial: true),
        AutoRoute(page: PostDetailsRoute.page),
        AutoRoute(page: LogsRoute.page),
      ];
}
