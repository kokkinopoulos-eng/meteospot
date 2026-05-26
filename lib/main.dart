import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final accepted = prefs.getBool('terms_accepted') ?? false;
  runApp(MetAIoSpotApp(showOnboarding: !accepted));
}

class MetAIoSpotApp extends StatelessWidget {
  final bool showOnboarding;
  const MetAIoSpotApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetAIoSpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}

