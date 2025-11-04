import 'package:flutter/material.dart';
import 'home_shell.dart';

final appRouter = RouterConfig<Object>(
  routerDelegate: _AppRouterDelegate(),
  routeInformationParser: _AppRouteInformationParser(),
  routeInformationProvider: PlatformRouteInformationProvider(
    initialRouteInformation: const RouteInformation(location: '/'),
  ),
);

class _AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: const <Page<dynamic>>[
        MaterialPage(child: HomeShell()),
      ],
      onPopPage: (route, result) => route.didPop(result),
    );
  }

  @override
  Future<void> setNewRoutePath(configuration) async {}
}

class _AppRouteInformationParser
    extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.location ?? '/';
  }
}


