import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../models/weather_data.dart';
import '../models/sensor_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final SensorService _sensorService = SensorService();

  WeatherData? _weatherData;
  SensorData? _sensorData;
  String? _aiInsight;
  bool _isLoading = false;
  String? _error;

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
      // Παίρνουμε τη θέση
      final Position position = await _locationService.getCurrentLocation();

      // Παίρνουμε τον καιρό
      final weather = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );

      // Παίρνουμε sensor data
      final sensors = await _sensorService.getSensorData();

      // Rule-based AI ανάλυση
      final insight = _sensorService.analyzeWeatherRules(
        apiPressure: weather.pressure,
        humidity: weather.humidity,
        temperature: weather.temperature,
        weatherCode: weather.weatherCode,
      );

      setState(() {
        _weatherData = weather;
        _sensorData = sensors;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Text('📍 ', style: TextStyle(fontSize: 20)),
            Text(
              'MeteoSpot',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWeather,
          ),
        ],
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
            Text(
              'Εντοπισμός τοποθεσίας...',
              style: TextStyle(color: Colors.white70),
            ),
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
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadWeather,
                icon: const Icon(Icons.refresh),
                label: const Text('Προσπάθεια ξανά'),
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
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildAIInsightCard(),
            const SizedBox(height: 16),
            _buildSensorsCard(),
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
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${w.latitude.toStringAsFixed(4)}, ${w.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${w.elevation.toInt()}m υψόμετρο',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                w.weatherEmoji,
                style: const TextStyle(fontSize: 64),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${w.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w200,
            ),
          ),
          Text(
            w.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Αίσθηση: ${w.feelsLike.toStringAsFixed(1)}°C',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
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
          const Text(
            'Λεπτομέρειες',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDetailItem('💧', 'Υγρασία', '${w.humidity.toInt()}%'),
              _buildDetailItem('🌬️', 'Άνεμος',
                  '${w.windSpeed.toStringAsFixed(1)} km/h ${w.windDirectionText}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDetailItem(
                  '🌡️', 'Πίεση', '${w.pressure.toStringAsFixed(0)} hPa'),
              _buildDetailItem('☀️', 'UV Index', w.uvIndex.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDetailItem('👁️', 'Ορατότητα',
                  '${(w.visibility / 1000).toStringAsFixed(1)} km'),
              _buildDetailItem('🕐', 'Ενημέρωση',
                  '${w.timestamp.hour}:${w.timestamp.minute.toString().padLeft(2, '0')}'),
            ],
          ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'AI Ανάλυση',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiInsight ?? 'Αναλύω δεδομένα...',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
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

  Widget _buildSensorsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Σένσορες Κινητού',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_sensorData?.accelerometerX != null) ...[
            _buildSensorRow('Επιταχυνσιόμετρο X',
                '${_sensorData!.accelerometerX!.toStringAsFixed(2)} m/s²'),
            _buildSensorRow('Επιταχυνσιόμετρο Y',
                '${_sensorData!.accelerometerY!.toStringAsFixed(2)} m/s²'),
            _buildSensorRow('Επιταχυνσιόμετρο Z',
                '${_sensorData!.accelerometerZ!.toStringAsFixed(2)} m/s²'),
          ] else
            const Text(
              'Οι σένσορες θα ενεργοποιηθούν στο κινητό',
              style: TextStyle(color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}