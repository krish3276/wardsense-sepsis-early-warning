/// WardSense - Trend-Based Early Sepsis Deterioration Assistant
///
/// This is the main entry point for the WardSense application.
/// The app provides clinical decision support for early sepsis detection
/// by analyzing trends in vital signs collected intermittently in hospital wards.
///
/// Architecture: Clean Architecture with Riverpod for state management
/// - Presentation Layer: UI, Screens, Widgets, Providers
/// - Domain Layer: Entities, Use Cases, Repository Interfaces
/// - Data Layer: Models, Repositories, Local Storage

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/datasources/local/hive_adapters.dart';
import 'data/datasources/local/demo_data_initializer.dart';
import 'presentation/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Hive for local storage (offline-first)
  await Hive.initFlutter();

  // Register Hive adapters for our models
  registerHiveAdapters();

  // Open required boxes
  await openHiveBoxes();

  // Initialize demo data for hackathon presentation
  await DemoDataInitializer.initializeIfEmpty();

  runApp(const ProviderScope(child: WardSenseApp()));
}

/// Opens all required Hive boxes for data persistence
Future<void> openHiveBoxes() async {
  await Hive.openBox(AppConstants.patientsBox);
  await Hive.openBox(AppConstants.vitalsBox);
  await Hive.openBox(AppConstants.alertsBox);
  await Hive.openBox(AppConstants.escalationsBox);
  await Hive.openBox(AppConstants.settingsBox);
}

/// Main application widget
///
/// Uses Material 3 design with custom theming optimized for
/// clinical environments (high contrast, accessible colors)
class WardSenseApp extends ConsumerWidget {
  const WardSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Material 3 theming with clinical-optimized colors
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Start with home screen (role selection)
      home: const HomeScreen(),
    );
  }
}
