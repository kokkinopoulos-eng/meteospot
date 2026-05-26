import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'screens/trial_wall_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/trial_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MetAIoSpotApp());
}

class MetAIoSpotApp extends StatelessWidget {
  const MetAIoSpotApp({super.key});

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
      home: const AppStartup(),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  @override
  void initState() {
    super.initState();
    _checkStartup();
  }

  Future<void> _checkStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAcceptedTerms = prefs.getBool('accepted_terms') ?? false;

    if (!hasAcceptedTerms) {
      // First launch - show onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
      return;
    }

    // Check trial
    final trial = await TrialService.getTrialStatus();
    if (mounted) {
      if (trial.hasFullAccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TrialWallScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(
        child: CircularProgressIndicator(color: Colors.blue),
      ),
    );
  }
}
