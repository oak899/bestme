import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GrowthOSApp());
}

class GrowthOSApp extends StatefulWidget {
  const GrowthOSApp({super.key});

  @override
  State<GrowthOSApp> createState() => _GrowthOSAppState();
}

class _GrowthOSAppState extends State<GrowthOSApp> {
  late final AppState _appState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _router = createAppRouter(_appState);
    _appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'GrowthOS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _appState.themeMode,
            routerConfig: _router,
            builder: (context, child) {
              if (_appState.initialized) return child ?? const SizedBox.shrink();
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const ColoredBox(
                    color: Color(0x88000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
