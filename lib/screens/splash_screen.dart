import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_navigation.dart';
import '../services/beach_service.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAcceptedTerms = prefs.getBool('accepted_terms') ?? false;

    if (!mounted) return;

    if (!hasAcceptedTerms) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    // Check if beach cache exists
    final hasCache = prefs.getString('cached_greek_beaches') != null;
    if (!hasCache) {
      setState(() => _downloadStatus = 'Λήψη δεδομένων παραλιών...');
      // Simulate progress while downloading
      for (int i = 1; i <= 9; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) setState(() => _downloadProgress = i / 10);
      }
      await BeachCache.getBeaches();
      if (mounted) setState(() => _downloadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/splash_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF0D1B2A).withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/app_icon.png', width: 100, height: 100),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Color(0xFF1E88E5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        children: [
                          TextSpan(text: 'Met'),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFFD700),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(text: 'o Spot'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\u039F AI \u03BC\u03B5\u03C4\u03B5\u03C9\u03C1\u03BF\u03BB\u03CC\u03B3\u03BF\u03C2 \u03C3\u03BF\u03C5',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                    if (_downloadProgress > 0) ...[
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          children: [
                            Text(_downloadStatus,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
