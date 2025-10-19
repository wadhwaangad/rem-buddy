import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'providers/reminder_provider.dart';
import 'screens/modern_onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() {
  // Initialize timezone database
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReminderProvider(),
      child: MaterialApp(
        title: 'REM Buddy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
        ),
        home: Consumer<ReminderProvider>(
          builder: (context, provider, child) {
            // Show onboarding if it's first launch OR user is not authenticated
            return provider.isFirstLaunch || !provider.isAuthenticated
                ? const ModernOnboardingScreen()
                : const HomeScreen();
          },
        ),
      ),
    );
  }
}
