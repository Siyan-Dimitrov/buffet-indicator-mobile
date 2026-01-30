import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/analysis_provider.dart';
import 'providers/sec_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open history box for persistent storage
  final historyBox = await Hive.openBox<String>('analysis_history');

  runApp(BuffetIndicatorApp(historyBox: historyBox));
}

class BuffetIndicatorApp extends StatelessWidget {
  final Box<String> historyBox;

  const BuffetIndicatorApp({super.key, required this.historyBox});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AnalysisProvider(historyBox: historyBox)),
        ChangeNotifierProvider(create: (_) => SecProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Buffet Indicator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
