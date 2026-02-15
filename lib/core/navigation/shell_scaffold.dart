import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/sync_listener.dart';

class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    // Determine active index
    final index = navigationShell.currentIndex;

    // TODO: Determine if user is Excavator/Developer to show FAB
    const bool showFab = true;

    return SyncListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle(index)),
          actions: const [
            ConnectivityIndicator(),
            SizedBox(width: 16),
          ],
        ),
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (idx) => _onItemTapped(context, idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: showFab && index == 0 // Show on Home tab primarily? Or all? Not specified. Usually Home/Feed.
            ? FloatingActionButton(
                onPressed: () {
                  // TODO: Navigate to create listing
                  context.push('/listings/create'); 
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  String _getTitle(int index) {
      switch (index) {
        case 0: return 'FillExchange';
        case 1: return 'Map';
        case 2: return 'Activity';
        case 3: return 'Profile';
        default: return 'FillExchange';
      }
  }

  void _onItemTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
