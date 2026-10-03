import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:peluna/views/pages/analytics_page.dart';
import 'package:peluna/views/pages/diary_page.dart';
import 'package:peluna/views/pages/home_page.dart';
import 'package:peluna/views/pages/settings_page.dart';
import 'package:peluna/views/pages/tags_page.dart';
import 'package:peluna/views/appbar_navbar_scaffold.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppbarNavbarScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'diary',
                  name: 'diary',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const DiaryPage(),
                  routes: [
                    GoRoute(
                      path: 'tags',
                      name: 'tags',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          TagsPage(initialTags: state.extra as List<String>?),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              name: 'analytics',
              builder: (context, state) => const AnalyticsPage(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
