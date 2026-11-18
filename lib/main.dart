import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/providers/theme_provider.dart';
import 'package:tims/app/routes/app_router.dart';
import 'package:tims/app/services/preferences_service.dart';
import 'package:tims/app/services/providers.dart';
import 'package:tims/app/themes/app_theme.dart';
import 'package:tims/app/widgets/app_update_checker.dart';

/// Entry point for the TIMS application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final prefs = await PreferencesService.create();
  final savedTheme = themeModeFromString(prefs.getThemeMode());

  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWith((ref) => prefs),
        themeModeProvider.overrideWith((ref) => savedTheme),
      ],
      child: const TimsApp(),
    ),
  );
}

/// Root widget for the TIMS application.
class TimsApp extends ConsumerWidget {
  const TimsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CSU TVET Office Inventory Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => AppUpdateChecker(
        navigatorKey: rootNavigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
