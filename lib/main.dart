import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/analysis_provider.dart';
import 'providers/sec_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open history box for persistent storage
  final historyBox = await Hive.openBox<String>('analysis_history');

  // Check onboarding flag
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(BuffetIndicatorApp(
    historyBox: historyBox,
    preferences: prefs,
    showOnboarding: !hasSeenOnboarding,
  ));
}

class BuffetIndicatorApp extends StatelessWidget {
  final Box<String> historyBox;
  final SharedPreferences preferences;
  final bool showOnboarding;

  const BuffetIndicatorApp({
    super.key,
    required this.historyBox,
    required this.preferences,
    required this.showOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(
            historyBox: historyBox,
            preferences: preferences,
          ),
        ),
        ChangeNotifierProvider(create: (_) => SecProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Value Lens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: showOnboarding ? const _OnboardingWrapper() : const HomeScreen(),
      ),
    );
  }
}

class _OnboardingWrapper extends StatefulWidget {
  const _OnboardingWrapper();

  @override
  State<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<_OnboardingWrapper> {
  bool _showingOnboarding = true;

  @override
  Widget build(BuildContext context) {
    if (_showingOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() => _showingOnboarding = false);
        },
      );
    }
    return const HomeScreen();
  }
}
