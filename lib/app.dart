import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/theme_mode_controller.dart';

class KagojApp extends ConsumerWidget {
  const KagojApp({super.key, this.router, this.builder});

  /// Defaults to [appRouter]; the demo build passes its own.
  final GoRouter? router;

  /// Wraps the app below the theme (the demo build uses it to add sheets).
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kagoj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router ?? appRouter,
      // Screens without an AppBar (home, words) still need status-bar icons
      // that contrast with the current theme.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: builder?.call(context, child) ?? child!,
      ),
    );
  }
}
