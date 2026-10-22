import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/reader/presentation/widgets/now_reading_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.location});

  final StatefulNavigationShell shell;

  /// Current path; the "Now reading" bar hides while the reader itself is open.
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (location != '/reader') const NowReadingBar(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_outline),
                selectedIcon: Icon(Icons.bookmark),
                label: 'Words',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
