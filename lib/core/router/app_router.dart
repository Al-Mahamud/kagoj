import 'package:go_router/go_router.dart';

import '../../features/epaper/presentation/epaper_browser_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/reader/domain/article.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/words/presentation/words_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouter = createRouter();

/// The ePaper browser and reader live inside the Home branch so the bottom
/// navigation bar stays visible; tapping Home again returns to the home page.
/// [initialLocation] and [initialExtra] let the demo build open any screen.
GoRouter createRouter({String initialLocation = '/', Object? initialExtra}) => GoRouter(
  initialLocation: initialLocation,
  initialExtra: initialExtra,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'paper/:id',
                builder: (_, state) =>
                    EpaperBrowserScreen(paperId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'reader',
                builder: (_, state) =>
                    ReaderScreen(article: state.extra! as Article),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/words', builder: (_, __) => const WordsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ]),
      ],
    ),
  ],
);
