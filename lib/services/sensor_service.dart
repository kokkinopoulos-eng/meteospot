import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';

class SensorService {
  final List<double> _pressureHistory = [];
  static const int _maxHistorySize = 20;

  // Accelerometer data
  double? _accX, _accY, _accZ;

  // Subscriptions
  StreamSubscription? _accelerometerSub;

  void startListening() {
    // Accelerometer
    _accelerometerSub = accelerometerEventStream().listen((event) {
      _accX = event.x;
      _accY = event.y;
      _accZ = event.z;
    });
  }

  void stopListening() {
    _accelerometerSub?.cancel();
  }

  Future<SensorData> getSensorData() async {
    return SensorData(
      accelerometerX: _accX,
      accelerometerY: _accY,
      accelerometerZ: _accZ,
      timestamp: DateTime.now(),
      pressureHistory: List.from(_pressureHistory),
    );
  }

  void addPressureReading(double pressure) {
    _pressureHistory.add(pressure);
    if (_pressureHistory.length > _maxHistorySize) {
      _pressureHistory.removeAt(0);
    }
  }

  // Rule-based AI - Ανάλυση καιρού χωρίς AI
  String analyzeWeatherRules({
    required double apiPressure,
    required double humidity,
    required double temperature,
    required int weatherCode,
    double? sensorPressure,
  }) {
    final List<String> insights = [];

    // Ανάλυση πίεσης
    if (_pressureHistory.length >= 2) {
      final trend = _pressureHistory.last - _pressureHistory.first;
      if (trend < -3) {
        insights.add('⚠️ Η πίεση πέφτει γρήγορα - πιθανή επιδείνωση σε 2-4 ώρες');
      } else if (trend < -1) {
        insights.add('🌂 Η πίεση πέφτει - ενδέχεται βροχή αργότερα');
      } else if (trend > 2) {
        insights.add('🌤️ Η πίεση αυξάνεται - βελτίωση καιρού αναμένεται');
      }
    }

    // Ανάλυση υγρασίας
    if (humidity > 85) {
      insights.add('💧 Πολύ υψηλή υγρασία - πιθανή βροχή ή ομίχλη');
    } else if (humidity > 70) {
      insights.add('💦 Υψηλή υγρασία - μπορεί να αισθάνεσαι ζέστη');
    }

    // Ανάλυση θερμοκρασίας
    if (temperature > 35) {
      insights.add('🔥 Πολύ υψηλή θερμοκρασία - αποφύγετε έκθεση στον ήλιο');
    } else if (temperature < 2) {
      insights.add('🧊 Κίνδυνος παγετού - προσοχή στους δρόμους');
    }

    // Ανάλυση weather code
    if (weatherCode >= 95) {
      insights.add('⛈️ Καταιγίδα ενεργή - μείνετε σε κλειστό χώρο');
    } else if (weatherCode >= 80) {
      insights.add('🌧️ Έντονη βροχόπτωση - αναπόφευκτη βροχή');
    }

    if (insights.isEmpty) {
      return '✅ Ο καιρός είναι σταθερός. Δεν εντοπίστηκαν έντονα φαινόμενα.';
    }

    return insights.join('\n');
  }
}