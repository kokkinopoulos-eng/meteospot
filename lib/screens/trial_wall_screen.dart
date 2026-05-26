import 'package:flutter/material.dart';
import '../services/trial_service.dart';

class TrialWallScreen extends StatelessWidget {
  const TrialWallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFFE65100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('\u{1F324}\uFE0F', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  children: [
                    TextSpan(text: 'Met'),
                    TextSpan(text: 'AI', style: TextStyle(color: Color(0xFFFFD700))),
                    TextSpan(text: 'oSpot'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '\u039C\u03B5\u03C4\u03B5\u03C9\u03C1\u03BF\u03BB\u03CC\u03B3\u03BF\u03C2 \u03BC\u03B5 AI',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              // Trial expired message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text('\u23F0 \u0397 \u03B4\u03BF\u03BA\u03B9\u03BC\u03B1\u03C3\u03C4\u03B9\u03BA\u03AE \u03C0\u03B5\u03C1\u03AF\u03BF\u03B4\u03BF\u03C2 \u03AD\u03BB\u03B7\u03BE\u03B5',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                      '\u0391\u03C0\u03CC\u03BB\u03B1\u03C5\u03C3\u03B5\u03C2 3 \u03B7\u03BC\u03AD\u03C1\u03B5\u03C2 \u03B4\u03C9\u03C1\u03B5\u03AC\u03BD \u03C7\u03C1\u03AE\u03C3\u03B7\u03C2. \u0391\u03C0\u03CC\u03BA\u03C4\u03B7\u03C3\u03B5 \u03C4\u03B7\u03BD \u03B5\u03C6\u03B1\u03C1\u03BC\u03BF\u03B3\u03AE \u03B3\u03B9\u03B1 \u03C3\u03C5\u03BD\u03AD\u03C7\u03B9\u03C3\u03B7.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Features list
                    _featureRow('\u2705', '\u03A0\u03C1\u03CC\u03B2\u03BB\u03B5\u03C8\u03B7 \u03BA\u03B1\u03B9\u03C1\u03BF\u03CD \u03BC\u03B5 GPS'),
                    _featureRow('\u2705', '\u03A7\u03AC\u03C1\u03C4\u03B7\u03C2 + Google Maps'),
                    _featureRow('\u2705', 'AI \u03B1\u03BD\u03AC\u03BB\u03C5\u03C3\u03B7 \u03BA\u03B1\u03B9\u03C1\u03BF\u03CD'),
                    _featureRow('\u2705', '\u0397\u03BB\u03B9\u03BF\u03C2 & \u03A3\u03B5\u03BB\u03AE\u03BD\u03B7'),
                    _featureRow('\u2705', '\u03A7\u03C9\u03C1\u03AF\u03C2 \u03B4\u03B9\u03B1\u03C6\u03B7\u03BC\u03AF\u03C3\u03B5\u03B9\u03C2'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Purchase button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // TODO: Implement payment
                    // For now simulate purchase
                    await TrialService.setPurchased();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '\u0391\u03B3\u03BF\u03C1\u03AC \u03B3\u03B9\u03B1 \u20AC4.99',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  // Restore purchase
                  final purchased = await TrialService.isPurchased();
                  if (purchased && context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('\u0394\u03B5\u03BD \u03B2\u03C1\u03AD\u03B8\u03B7\u03BA\u03B5 \u03B1\u03B3\u03BF\u03C1\u03AC')),
                    );
                  }
                },
                child: const Text('\u0391\u03BD\u03AC\u03BA\u03C4\u03B7\u03C3\u03B7 \u03B1\u03B3\u03BF\u03C1\u03AC\u03C2', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
