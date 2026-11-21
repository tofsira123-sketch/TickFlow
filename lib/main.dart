import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TickFlowApp());
}

class TickFlowApp extends StatefulWidget {
  const TickFlowApp({super.key});

  @override
  State<TickFlowApp> createState() => _TickFlowAppState();
}

class _TickFlowAppState extends State<TickFlowApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.load();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2B34B8),
      secondary: const Color(0xFF00ACC1),
      brightness: Brightness.light,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F51B5),
      secondary: const Color(0xFF26C6DA),
      brightness: Brightness.dark,
    );

    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'TickFlow',
          debugShowCheckedModeBanner: false,
          themeMode: _appState.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
          ),
          home: HomeShell(appState: _appState),
        );
      },
    );
  }
}
