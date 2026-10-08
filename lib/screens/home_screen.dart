import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/network_diagnostic_state.dart';
import '../widgets/menu_card.dart';
import 'activity_one_screen.dart';
import 'local_mesh_chat_screen.dart';
import 'network_diagnostic_screen.dart';
import 'network_monitor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds instantly whenever global state changes.
    final appState = context.watch<AppState>();
    final health = context.watch<NetworkDiagnosticState>().health;
    final scheme = Theme.of(context).colorScheme;

    void go(String route) => Navigator.pushNamed(context, route);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Activity Hub'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => go(SettingsScreen.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.primary,
                      child: Text(
                        appState.userName[0].toUpperCase(),
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${appState.userName}!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(appState.isDarkMode
                              ? 'Dark mode is ON'
                              : 'Light mode is ON'),
                          const SizedBox(height: 4),
                          // Global network health broadcast (Activity 3)
                          Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: health.color),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Network health: ${health.label}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Activities',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  children: [
                    MenuCard(
                      icon: Icons.layers,
                      title: 'Activity 1',
                      subtitle: 'State & Layout',
                      onTap: () => go(ActivityOneScreen.routeName),
                    ),
                    MenuCard(
                      icon: Icons.network_check,
                      title: 'Activity 2',
                      subtitle: 'Network Monitor',
                      onTap: () => go(NetworkMonitorScreen.routeName),
                    ),
                    MenuCard(
                      icon: Icons.speed,
                      title: 'Activity 3',
                      subtitle: 'Network Diagnostic',
                      onTap: () => go(NetworkDiagnosticScreen.routeName),
                    ),
                    MenuCard(
                      icon: Icons.forum,
                      title: 'Activity 4',
                      subtitle: 'Local Mesh Chat',
                      onTap: () => go(LocalMeshChatScreen.routeName),
                    ),
                    MenuCard(
                      icon: Icons.settings,
                      title: 'Settings',
                      subtitle: 'Theme & profile name',
                      onTap: () => go(SettingsScreen.routeName),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
