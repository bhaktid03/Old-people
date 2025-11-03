import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/headlines/presentation/headlines_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const HeadlinesScreen(),
    ),
  ],
);


