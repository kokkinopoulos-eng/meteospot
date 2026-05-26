import 'package:flutter/material.dart';
import 'dart:math';
import '../services/sun_moon_service.dart';
import '../services/location_service.dart';

class SunMoonScreen extends StatefulWidget {
  const SunMoonScreen({super.key});

  @override
  State<SunMoonScreen> createState() => _SunMoonScreenState();
}

class _SunMoonScreenState extends State<SunMoonScreen> {
  final SunMoonService _service = SunMoonService();
  final LocationService _locationService = LocationService();
  SunMoonData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final position = await _locationService.getCurrentLocation();
      final data = _service.calculate(
        position.latitude,
        position.longitude,
        DateTime.now(),
      );
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '$hours\u03C9 $minutes\u03BB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : _data == null
                ? const Center(
                    child: Text('\u03A3\u03C6\u03AC\u03BB\u03BC\u03B1 \u03C6\u03CC\u03C1\u03C4\u03C9\u03C3\u03B7\u03C2',
                        style: TextStyle(color: Colors.white70)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text('\u0389\u03BB\u03B9\u03BF\u03C2 & \u03A3\u03B5\u03BB\u03AE\u03BD\u03B7',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildSunCard(),
                        const SizedBox(height: 16),
                        _buildMoonCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSunCard() {
    final w = _data!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('\u2600\uFE0F', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text('\u0389\u03BB\u03B9\u03BF\u03C2',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: SunArcPainter(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeBlock('\u{1F305}', '\u0391\u03BD\u03B1\u03C4\u03BF\u03BB\u03AE', _formatTime(w.sunrise)),
              _buildTimeBlock('\u{1F307}', '\u0394\u03CD\u03C3\u03B7', _formatTime(w.sunset)),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '\u0394\u03B9\u03AC\u03C1\u03BA\u03B5\u03B9\u03B1 \u03B7\u03BC\u03AD\u03C1\u03B1\u03C2: ${_formatDuration(w.dayLength)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonCard() {
    final w = _data!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('\u{1F319}', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text('\u03A3\u03B5\u03BB\u03AE\u03BD\u03B7',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(w.moonEmoji, style: const TextStyle(fontSize: 100)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              w.moonPhaseName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '\u03A6\u03AC\u03C3\u03B7: ${(w.moonPhase * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: w.moonPhase,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String emoji, String label, String time) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(time,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class SunArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(20, size.height - 10);
    path.quadraticBezierTo(
      size.width / 2, -size.height * 0.5,
      size.width - 20, size.height - 10,
    );
    canvas.drawPath(path, paint);

    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;
    final progress = ((hour - 6) / 12).clamp(0.0, 1.0);

    final t = progress;
    final x = 20 + (size.width - 40) * t;
    final y = (1 - t) * (size.height - 10) + t * (size.height - 10) - sin(t * pi) * size.height * 0.7;

    final sunPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(x, y), 12, sunPaint);

    final glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(x, y), 20, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
