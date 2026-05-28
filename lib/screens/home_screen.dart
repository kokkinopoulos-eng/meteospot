import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'settings_screen.dart' as settings_screen;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../models/weather_data.dart';

class HomeScreen extends StatefulWidget {
  final void Function(WeatherData)? onWeatherLoaded;
  const HomeScreen({super.key, this.onWeatherLoaded});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final SensorService _sensorService = SensorService();

  WeatherData? _weatherData;
  String? _aiInsight;
  bool _isLoading = false;
  String? _error;
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _sensorService.startListening();
    _loadWeather();
  }

  @override
  void dispose() {
    _sensorService.stopListening();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Position position = await _locationService.getCurrentLocation();
      final weather = await _weatherService.getWeather(position.latitude, position.longitude);
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.locality, p.administrativeArea].where((s) => s != null && s.isNotEmpty).toList();
          weather.locationName = parts.join(', ');
        }
      } catch (_) {}

      final insight = _sensorService.analyzeWeatherRules(
        apiPressure: weather.pressure,
        humidity: weather.humidity,
        temperature: weather.temperature,
        weatherCode: weather.weatherCode,
        windSpeed: weather.windSpeed,
        uvIndex: weather.uvIndex,
        visibility: weather.visibility,
        feelsLike: weather.feelsLike,
      );

      setState(() {
        _weatherData = weather;
        widget.onWeatherLoaded?.call(weather);
        _aiInsight = insight;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _lon2tile(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _lat2tile(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << zoom)).floor();
  }

  Future<void> _openInGoogleMaps(double lat, double lon) async {
    // Try Android geo URI first (opens native Google Maps app)
    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon(MetAIoSpot)');
    final webUri = Uri.parse('https://www.google.com/maps?q=$lat,$lon');
    
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _onTempTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 2) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      _showTestMenu();
    }
  }

  void _showTestMenu() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2744),
        title: const Text('🧪 Developer Test', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Test mode - not real data', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            _testBtn(ctx, '☀️ Καλός καιρός', 1, 25, 50, 5),
            _testBtn(ctx, '🌧️ Βροχή', 61, 18, 85, 20),
            _testBtn(ctx, '⛈️ Καταιγίδα', 95, 22, 90, 15),
            _testBtn(ctx, '❄️ Χιόνι', 71, -2, 80, 10),
            _testBtn(ctx, '🌬️ Δυνατοί άνεμοι', 2, 20, 40, 75),
            _testBtn(ctx, '🥵 Καύσωνας', 3, 42, 20, 5),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadWeather();
            },
            child: const Text('🔄 Πραγματικός καιρός', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _testBtn(BuildContext ctx, String label, int code, double temp, double humidity, double wind) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
          onPressed: () {
            Navigator.pop(ctx);
            if (_weatherData != null) {
              setState(() {
                _weatherData!.weatherCode = code;
                _weatherData!.temperature = temp;
                _weatherData!.humidity = humidity;
                _weatherData!.windSpeed = wind;
                _weatherData!.description = '🧪 TEST MODE';
                _aiInsight = _sensorService.analyzeWeatherRules(
                  apiPressure: _weatherData!.pressure,
                  humidity: humidity,
                  temperature: temp,
                  weatherCode: code,
                  windSpeed: wind,
                  uvIndex: _weatherData!.uvIndex,
                  visibility: _weatherData!.visibility,
                  feelsLike: temp - 1,
                );
              });
            }
          },
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF0D47A1), Color(0xFFBF360C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x661E88E5),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Met', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0)),
                Text('AI', style: TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('o Spot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  if (_weatherData != null) {
                    final w = _weatherData!;
                    SharePlus.instance.share(ShareParams(text: 'MetAIo Spot\n' + w.locationName + '\n' + w.temperature.toStringAsFixed(1) + '°C ' + w.description + '\nΥγρασία: ' + w.humidity.toInt().toString() + '% | Άνεμος: ' + w.windSpeed.toStringAsFixed(1) + ' km/h'));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadWeather,
              ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => settings_screen.SettingsScreen())),
                ),
            ],
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Εντοπισμός τοποθεσίας...',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadWeather,
                icon: const Icon(Icons.refresh),
                label: const Text('Προσπάθεια ξανά'),
              ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => settings_screen.SettingsScreen())),
                ),
            ],
          ),
        ),
      );
    }

    if (_weatherData == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainWeatherCard(),
            const SizedBox(height: 16),
            _buildMapCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildAIInsightCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    final w = _weatherData!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: left = coords/elevation, right = location + description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: coordinates + elevation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${w.latitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${w.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${w.elevation.toInt()}m υψόμετρο',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Right side: location name + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      w.locationName.isNotEmpty
                          ? w.locationName
                          : 'Άγνωστη περιοχή',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      w.description,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Middle: thermometer + temperature
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildThermometer(w.temperature),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _onTempTap,
                child: Text(
                '${w.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                ),
              ),
              ),
            ],
          ),
          // Bottom row: feels-like left, emoji right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Αίσθηση: ${w.feelsLike.toStringAsFixed(1)}°C',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(w.weatherEmoji, style: const TextStyle(fontSize: 64)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    final w = _weatherData!;
    const zoom = 14;
    final x = _lon2tile(w.longitude, zoom);
    final y = _lat2tile(w.latitude, zoom);
    final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';

    return GestureDetector(
      onTap: () => _openInGoogleMaps(w.latitude, w.longitude),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
                placeholder: (_, __) => Container(
                  color: const Color(0xFF263238),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF263238),
                  child: const Center(
                    child: Icon(Icons.map_outlined, color: Colors.white38, size: 48),
                  ),
                ),
              ),
              // Red marker (pin shape)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // "Tap to open in Google Maps" hint
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Google Maps',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final w = _weatherData!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Πληροφορίες Σημείου',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            _buildDetailItem('💧', 'Υγρασία', '${w.humidity.toInt()}%'),
            _buildDetailItem('💨', 'Άνεμος',
                '${w.windSpeed.toStringAsFixed(1)} km/h ${w.windDirectionText}'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _buildDetailItem('🌡️', 'Πίεση', '${w.pressure.toStringAsFixed(0)} hPa'),
            _buildDetailItem('☀️', 'UV Index', w.uvIndex.toStringAsFixed(1)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _buildDetailItem('👁️', 'Ορατότητα',
                '${(w.visibility / 1000).toStringAsFixed(1)} km'),
            _buildDetailItem('🕐', 'Ενημέρωση',
                '${w.timestamp.hour}:${w.timestamp.minute.toString().padLeft(2, '0')}'),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String emoji, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermometer(double temp) {
    // Map temperature to fill ratio (0..1) using range -10..45
    final clamped = temp.clamp(-10.0, 45.0);
    final ratio = (clamped + 10) / 55.0;
    
    // Color based on temperature
    Color fillColor;
    if (temp < 0) {
      fillColor = const Color(0xFF42A5F5); // Light blue - freezing
    } else if (temp < 10) {
      fillColor = const Color(0xFF26C6DA); // Cyan - cold
    } else if (temp < 20) {
      fillColor = const Color(0xFF66BB6A); // Green - cool
    } else if (temp < 28) {
      fillColor = const Color(0xFFFFEE58); // Yellow - warm
    } else if (temp < 35) {
      fillColor = const Color(0xFFFF7043); // Orange - hot
    } else {
      fillColor = const Color(0xFFE53935); // Red - very hot
    }
    
    return SizedBox(
      width: 32,
      height: 110,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Tube background
          Positioned(
            top: 0,
            bottom: 18,
            child: Container(
              width: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
            ),
          ),
          // Tube fill (animated based on temp)
          Positioned(
            bottom: 18,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              width: 10,
              height: (110 - 28) * ratio,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(5),
                  topRight: const Radius.circular(5),
                  bottomLeft: Radius.circular(ratio < 0.05 ? 5 : 0),
                  bottomRight: Radius.circular(ratio < 0.05 ? 5 : 0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: fillColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          // Bulb (filled circle at bottom)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: fillColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: fillColor.withValues(alpha: 0.7),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🤖', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('AI Ανάλυση',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text(
            _aiInsight ?? 'Αναλύω δεδομένα...',
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          const Text(
            '⚠️ Ενδεικτική ανάλυση. Για δραστηριότητες με κίνδυνο, συμβουλευτείτε ΕΜΥ.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
