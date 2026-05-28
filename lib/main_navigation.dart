import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/sun_moon_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/beach_screen.dart';
import 'screens/settings_screen.dart';
import 'models/weather_data.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  WeatherData? _weatherData;

  void _onWeatherLoaded(WeatherData weather) {
    setState(() => _weatherData = weather);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onWeatherLoaded: _onWeatherLoaded),
          const SunMoonScreen(),
          const BeachScreen(),
          _weatherData != null
              ? ChatScreen(weatherData: _weatherData!)
              : const _NoWeatherPlaceholder(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1A2744),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            activeIcon: Icon(Icons.wb_sunny),
            label: '\u039a\u03b1\u03b9\u03c1\u03cc\u03c2',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nightlight_outlined),
            activeIcon: Icon(Icons.nightlight),
            label: '\u0389\u03bb\u03b9\u03bf\u03c2/\u03a3\u03b5\u03bb\u03ae\u03bd\u03b7',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.beach_access_outlined),
            activeIcon: Icon(Icons.beach_access),
            label: '\u03a0\u03b1\u03c1\u03b1\u03bb\u03af\u03b5\u03c2',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '\u03a1\u03c5\u03b8\u03bc\u03af\u03c3\u03b5\u03b9\u03c2',
          ),
        ],
      ),
    );
  }
}

class _NoWeatherPlaceholder extends StatelessWidget {
  const _NoWeatherPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: Colors.white38, size: 64),
            SizedBox(height: 16),
            Text(
              '\u03a0\u03c1\u03ce\u03c4\u03b1 \u03c6\u03cc\u03c1\u03c4\u03c9\u03c3\u03b5 \u03c4\u03bf\u03bd \u03ba\u03b1\u03b9\u03c1\u03cc',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
