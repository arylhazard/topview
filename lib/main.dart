import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:topview/screens/main_navigation.dart'; // Restore old home
import 'package:topview/themes/app_theme.dart';
import 'package:topview/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseService.database;
  
  // Get saved theme mode
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  
  runApp(MyApp(savedThemeMode: savedThemeMode));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  
  const MyApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {    return ChangeNotifierProvider(
      create: (context) => PortfolioProvider()..initialize(), // Auto-initialize
      child: AdaptiveTheme(
        light: AppTheme.lightTheme,
        dark: AppTheme.darkTheme,
        initial: savedThemeMode ?? AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp(
          title: 'TopView Portfolio Tracker',
          theme: theme,
          darkTheme: darkTheme,
          home: const MainNavigation(), // Restore old home
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
