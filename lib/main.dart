import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'providers/local_mesh_chat_state.dart';
import 'providers/network_diagnostic_state.dart';
import 'providers/network_monitor_state.dart';
import 'screens/activity_one_screen.dart';
import 'screens/home_screen.dart';
import 'screens/local_mesh_chat_screen.dart';
import 'screens/network_diagnostic_screen.dart';
import 'screens/network_monitor_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => NetworkMonitorState()),
        ChangeNotifierProvider(create: (_) => NetworkDiagnosticState()),
        ChangeNotifierProvider(create: (_) => LocalMeshChatState()),
      ],
      child: const LabActivityHubApp(),
    ),
  );
}

class LabActivityHubApp extends StatelessWidget {
  const LabActivityHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'Lab Activity Hub',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        ActivityOneScreen.routeName: (_) => const ActivityOneScreen(),
        NetworkMonitorScreen.routeName: (_) => const NetworkMonitorScreen(),
        NetworkDiagnosticScreen.routeName: (_) =>
            const NetworkDiagnosticScreen(),
        LocalMeshChatScreen.routeName: (_) => const LocalMeshChatScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}
