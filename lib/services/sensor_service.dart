import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';

class SensorService {
  final List<double> _pressureHistory = [];
  static const int _maxHistorySize = 20;

  double? _accX, _accY, _accZ;
  StreamSubscription? _accelerometerSub;

  void startListening() {
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

  /// Advanced Rule-Based AI - Ξ‘Ξ½Ξ±Ξ»ΟΞµΞΉ ΞΊΞ±ΞΉΟΟ ΞΌΞµ Ο€ΞΏΞ»Ξ»ΞΏΟΟ‚ ΞΊΞ±Ξ½ΟΞ½ΞµΟ‚
  String analyzeWeatherRules({
    required double apiPressure,
    required double humidity,
    required double temperature,
    required int weatherCode,
    double? windSpeed,
    double? uvIndex,
    double? visibility,
    double? feelsLike,
    double? sensorPressure,
  }) {
    final List<String> insights = [];
    final List<String> activities = [];
    final List<String> warnings = [];

    // ===== Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ— Ξ Ξ™Ξ•Ξ£Ξ—Ξ£ =====
    if (_pressureHistory.length >= 2) {
      final trend = _pressureHistory.last - _pressureHistory.first;
      if (trend < -5) {
        warnings.add('β οΈ Ξ— Ο€Ξ―ΞµΟƒΞ· Ο€Ξ­Ο†Ο„ΞµΞΉ Ξ±Ο€ΟΟ„ΞΏΞΌΞ± - Ο€ΞΉΞΈΞ±Ξ½Ξ® ΞΊΞ±Ο„Ξ±ΞΉΞ³Ξ―Ξ΄Ξ± ΟƒΞµ 1-3 ΟΟΞµΟ‚');
      } else if (trend < -3) {
        warnings.add('π§ Ξ— Ο€Ξ―ΞµΟƒΞ· Ο€Ξ­Ο†Ο„ΞµΞΉ Ξ³ΟΞ®Ξ³ΞΏΟΞ± - ΞµΟ€ΞΉΞ΄ΞµΞ―Ξ½Ο‰ΟƒΞ· ΟƒΞµ 2-4 ΟΟΞµΟ‚');
      } else if (trend < -1) {
        insights.add('π¥ Ξ— Ο€Ξ―ΞµΟƒΞ· Ο€Ξ­Ο†Ο„ΞµΞΉ - Ο€ΞΉΞΈΞ±Ξ½Ξ® Ξ²ΟΞΏΟ‡Ξ® Ξ±ΟΞ³ΟΟ„ΞµΟΞ±');
      } else if (trend > 3) {
        insights.add('β€οΈ Ξ— Ο€Ξ―ΞµΟƒΞ· Ξ±Ο…ΞΎΞ¬Ξ½ΞµΟ„Ξ±ΞΉ - Ξ²ΞµΞ»Ο„Ξ―Ο‰ΟƒΞ· ΞΊΞ±ΞΉΟΞΏΟ');
      } else if (trend > 1) {
        insights.add('π¤ Ξ£Ο„Ξ±ΞΈΞµΟΞ® Ξ±Ξ½ΞΏΞ΄ΞΉΞΊΞ® Ο„Ξ¬ΟƒΞ· Ο€Ξ―ΞµΟƒΞ·Ο‚');
      }
    }

    // Ξ‘Ο€ΟΞ»Ο…Ο„Ξ· Ο€Ξ―ΞµΟƒΞ·
    if (apiPressure < 990) {
      warnings.add('β› Ξ ΞΏΞ»Ο Ο‡Ξ±ΞΌΞ·Ξ»Ξ® Ο€Ξ―ΞµΟƒΞ· (${apiPressure.toStringAsFixed(0)} hPa) - Ξ±ΟƒΟ„Ξ±ΞΈΞ®Ο‚ ΞΊΞ±ΞΉΟΟΟ‚');
    } else if (apiPressure > 1025) {
      insights.add('β€οΈ Ξ¥ΟΞ·Ξ»Ξ® Ο€Ξ―ΞµΟƒΞ· (${apiPressure.toStringAsFixed(0)} hPa) - ΟƒΟ„Ξ±ΞΈΞµΟΟΟ‚ ΞΊΞ±ΞΉΟΟΟ‚');
    }

    // ===== Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ— Ξ¥Ξ“Ξ΅Ξ‘Ξ£Ξ™Ξ‘Ξ£ =====
    if (humidity > 90) {
      warnings.add('π’§ Ξ ΞΏΞ»Ο Ο…ΟΞ·Ξ»Ξ® Ο…Ξ³ΟΞ±ΟƒΞ―Ξ± (${humidity.toInt()}%) - Ο€ΞΉΞΈΞ±Ξ½Ξ® ΞΏΞΌΞ―Ο‡Ξ»Ξ· Ξ® Ξ²ΟΞΏΟ‡Ξ®');
    } else if (humidity > 80) {
      insights.add('π« Ξ¥ΟΞ·Ξ»Ξ® Ο…Ξ³ΟΞ±ΟƒΞ―Ξ± - Ο€Ξ½ΞΉΞ³Ξ·ΟΞ® Ξ±Ο„ΞΌΟΟƒΟ†Ξ±ΞΉΟΞ±');
    } else if (humidity < 30) {
      insights.add('π Ξ§Ξ±ΞΌΞ·Ξ»Ξ® Ο…Ξ³ΟΞ±ΟƒΞ―Ξ± - ΞΎΞ·ΟΟΟ‚ Ξ±Ξ­ΟΞ±Ο‚, Ο€ΞΉΞµΞ―Ο„Ξµ Ξ½ΞµΟΟ');
    }

    // ===== Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ— ΞΞ•Ξ΅ΞΞΞΞ΅Ξ‘Ξ£Ξ™Ξ‘Ξ£ =====
    if (temperature > 40) {
      warnings.add('π”¥ Ξ‘ΞΞ΅Ξ‘Ξ™Ξ‘ Ξ¶Ξ­ΟƒΟ„Ξ· (${temperature.toStringAsFixed(0)}Β°C) - ΞΊΞ―Ξ½Ξ΄Ο…Ξ½ΞΏΟ‚ ΞΈΞµΟΞΌΞΏΟ€Ξ»Ξ·ΞΎΞ―Ξ±Ο‚!');
    } else if (temperature > 35) {
      warnings.add('π΅ Ξ ΞΏΞ»Ο Ο…ΟΞ·Ξ»Ξ® ΞΈΞµΟΞΌΞΏΞΊΟΞ±ΟƒΞ―Ξ± - Ξ±Ο€ΞΏΟ†ΟΞ³ΞµΟ„Ξµ Ξ·Ξ»ΞΉΞ±ΞΊΞ® Ξ­ΞΊΞΈΞµΟƒΞ· 12-16ΞΌΞΌ');
    } else if (temperature > 30) {
      insights.add('β€οΈ Ξ–Ξ­ΟƒΟ„Ξ· - Ο†ΞΏΟΞ¬Ο„Ξµ ΞΊΞ±Ο€Ξ­Ξ»ΞΏ ΞΊΞ±ΞΉ Ξ±Ξ½Ο„ΞΉΞ·Ξ»ΞΉΞ±ΞΊΟ');
    } else if (temperature < -5) {
      warnings.add('π¥¶ Ξ‘ΞΞ΅Ξ‘Ξ™Ξ ΞΊΟΟΞΏ - ΞΊΞ―Ξ½Ξ΄Ο…Ξ½ΞΏΟ‚ Ο…Ο€ΞΏΞΈΞµΟΞΌΞ―Ξ±Ο‚');
    } else if (temperature < 2) {
      warnings.add('β„οΈ ΞΞ―Ξ½Ξ΄Ο…Ξ½ΞΏΟ‚ Ο€Ξ±Ξ³ΞµΟ„ΞΏΟ - Ο€ΟΞΏΟƒΞΏΟ‡Ξ® ΟƒΟ„ΞΏΟ…Ο‚ Ξ΄ΟΟΞΌΞΏΟ…Ο‚');
    } else if (temperature < 10) {
      insights.add('π§¥ ΞΟΟΞΏ - Ο‡ΟΞµΞΉΞ¬Ξ¶ΞµΟƒΟ„Ξµ Ξ¶ΞµΟƒΟ„Ξ¬ ΟΞΏΟΟ‡Ξ±');
    }

    // Ξ‘Ξ―ΟƒΞΈΞ·ΟƒΞ· ΞΈΞµΟΞΌΞΏΞΊΟΞ±ΟƒΞ―Ξ±Ο‚
    if (feelsLike != null) {
      final diff = (feelsLike - temperature).abs();
      if (diff > 5) {
        if (feelsLike > temperature) {
          insights.add('π¥µ Ξ‘Ξ―ΟƒΞΈΞ·ΟƒΞ· Ο€ΞΉΞΏ Ξ¶ΞµΟƒΟ„Ξ® Ξ»ΟΞ³Ο‰ Ο…Ξ³ΟΞ±ΟƒΞ―Ξ±Ο‚ (${feelsLike.toStringAsFixed(0)}Β°C)');
        } else {
          insights.add('π¥¶ Ξ‘Ξ―ΟƒΞΈΞ·ΟƒΞ· Ο€ΞΉΞΏ ΞΊΟΟΞ± Ξ»ΟΞ³Ο‰ Ξ±Ξ½Ξ­ΞΌΞΏΟ… (${feelsLike.toStringAsFixed(0)}Β°C)');
        }
      }
    }

    // ===== Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ— Ξ‘ΞΞ•ΞΞΞ¥ =====
    if (windSpeed != null) {
      if (windSpeed > 70) {
        warnings.add('π ΞΞ¥Ξ•Ξ›Ξ›Ξ©Ξ”Ξ•Ξ™Ξ£ Ξ¬Ξ½ΞµΞΌΞΏΞΉ (${windSpeed.toStringAsFixed(0)} km/h) - ΞΌΞµΞ―Ξ½ΞµΟ„Ξµ ΞΌΞ­ΟƒΞ±!');
      } else if (windSpeed > 50) {
        warnings.add('π’¨ Ξ ΞΏΞ»Ο ΞΉΟƒΟ‡Ο…ΟΞΏΞ― Ξ¬Ξ½ΞµΞΌΞΏΞΉ - ΞµΟ€ΞΉΞΊΞ―Ξ½Ξ΄Ο…Ξ½ΞΏ Ξ³ΞΉΞ± Ο€ΞµΞ¶ΞΏΟ€ΞΏΟΞ―Ξ±/ΟΞ¬ΟΞµΞΌΞ±');
      } else if (windSpeed > 30) {
        insights.add('π’¨ Ξ™ΟƒΟ‡Ο…ΟΞΏΞ― Ξ¬Ξ½ΞµΞΌΞΏΞΉ - Ο€ΟΞΏΟƒΞΏΟ‡Ξ® ΟƒΞµ ΞµΞΎΟ‰Ο„ΞµΟΞΉΞΊΞ­Ο‚ Ξ΄ΟΞ±ΟƒΟ„Ξ·ΟΞΉΟΟ„Ξ·Ο„ΞµΟ‚');
      } else if (windSpeed < 5) {
        insights.add('πƒ Ξ‰ΟΞµΞΌΞΏΟ‚ Ξ¬Ξ½ΞµΞΌΞΏΟ‚ - ΞΉΞ΄Ξ±Ξ½ΞΉΞΊΟ Ξ³ΞΉΞ± drone, ΟΞ¬ΟΞµΞΌΞ±, ΞΌΟ€Ξ¬ΟΞΌΟ€ΞµΞΊΞΉΞΏΟ…');
      }
    }

    // ===== Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ— UV =====
    if (uvIndex != null) {
      if (uvIndex >= 11) {
        warnings.add('βΆοΈ Ξ‘ΞΞ΅Ξ‘Ξ™Ξ‘ UV (${uvIndex.toStringAsFixed(0)}) - Ξ±Ο€Ξ±ΟΞ±Ξ―Ο„Ξ·Ο„Ξ· Ο€ΟΞΏΟƒΟ„Ξ±ΟƒΞ―Ξ±');
      } else if (uvIndex >= 8) {
        warnings.add('π”† Ξ ΞΏΞ»Ο Ο…ΟΞ·Ξ»Ξ® UV - Ξ±Ξ½Ο„ΞΉΞ·Ξ»ΞΉΞ±ΞΊΟ SPF 50+, ΞΊΞ±Ο€Ξ­Ξ»ΞΏ, Ξ³Ο…Ξ±Ξ»ΞΉΞ¬');
      } else if (uvIndex >= 6) {
        insights.add('β€οΈ Ξ¥ΟΞ·Ξ»Ξ® UV - Ο‡ΟΞµΞΉΞ¬Ξ¶ΞµΟ„Ξ±ΞΉ Ξ±Ξ½Ο„ΞΉΞ·Ξ»ΞΉΞ±ΞΊΟ');
      } else if (uvIndex >= 3) {
        insights.add('π¤ ΞΞ­Ο„ΟΞΉΞ± UV - Ο€ΟΞΏΟƒΟ„Ξ±ΟƒΞ―Ξ± Ο„ΞΉΟ‚ ΞΌΞµΟƒΞ·ΞΌΞµΟΞΉΞ±Ξ½Ξ­Ο‚ ΟΟΞµΟ‚');
      }
    }

    // ===== Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ— ΞΞ΅Ξ‘Ξ¤ΞΞ¤Ξ—Ξ¤Ξ‘Ξ£ =====
    if (visibility != null) {
      if (visibility < 1000) {
        warnings.add('π« Ξ ΞΏΞ»Ο Ο‡Ξ±ΞΌΞ·Ξ»Ξ® ΞΏΟΞ±Ο„ΟΟ„Ξ·Ο„Ξ± (${(visibility / 1000).toStringAsFixed(1)} km) - ΞµΟ€ΞΉΞΊΞ―Ξ½Ξ΄Ο…Ξ½Ξ· ΞΏΞ΄Ξ®Ξ³Ξ·ΟƒΞ·');
      } else if (visibility < 5000) {
        insights.add('π« ΞΞµΞΉΟ‰ΞΌΞ­Ξ½Ξ· ΞΏΟΞ±Ο„ΟΟ„Ξ·Ο„Ξ± - Ο€ΟΞΏΟƒΞΏΟ‡Ξ® ΟƒΟ„Ξ·Ξ½ ΞΏΞ΄Ξ®Ξ³Ξ·ΟƒΞ·');
      }
    }

    // ===== Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ— WEATHER CODE =====
    if (weatherCode >= 95) {
      warnings.add('β› ΞΞ±Ο„Ξ±ΞΉΞ³Ξ―Ξ΄Ξ± ΞµΞ½ΞµΟΞ³Ξ® - ΞΌΞµΞ―Ξ½ΞµΟ„Ξµ ΟƒΞµ ΞΊΞ»ΞµΞΉΟƒΟ„Ο Ο‡ΟΟΞΏ');
    } else if (weatherCode >= 80) {
      warnings.add('π§ ΞΞ½Ο„ΞΏΞ½Ξ· Ξ²ΟΞΏΟ‡ΟΟ€Ο„Ο‰ΟƒΞ· - Ο€Ξ¬ΟΟ„Ξµ ΞΏΞΌΟ€ΟΞ­Ξ»Ξ±');
    } else if (weatherCode >= 71 && weatherCode <= 77) {
      warnings.add('π¨ Ξ§ΞΉΞΏΞ½ΟΟ€Ο„Ο‰ΟƒΞ· - Ο€ΟΞΏΟƒΞΏΟ‡Ξ® ΟƒΞµ ΞΌΞµΟ„Ξ±ΞΊΞΉΞ½Ξ®ΟƒΞµΞΉΟ‚');
    } else if (weatherCode >= 61 && weatherCode <= 67) {
      insights.add('π¦ Ξ¨ΞΉΟ‡Ξ¬Ξ»Ξ± - Ο€Ξ¬ΟΟ„Ξµ ΞµΞ»Ξ±Ο†ΟΟ Ξ±Ξ΄ΞΉΞ¬Ξ²ΟΞΏΟ‡ΞΏ');
    } else if (weatherCode >= 51 && weatherCode <= 57) {
      insights.add('π’§ Ξ¨ΞΉΟ‡Ξ¬Ξ»Ξ± - Ο€ΞΉΞΈΞ±Ξ½Ξ® ΞµΞ»Ξ±Ο†ΟΞΉΞ¬ Ξ²ΟΞΏΟ‡Ξ®');
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      insights.add('π« ΞΞΌΞ―Ο‡Ξ»Ξ· - ΞΌΞµΞΉΟ‰ΞΌΞ­Ξ½Ξ· ΞΏΟΞ±Ο„ΟΟ„Ξ·Ο„Ξ±');
    }

    // ===== Ξ£Ξ¥Ξ£Ξ¤Ξ‘Ξ£Ξ•Ξ™Ξ£ Ξ”Ξ΅Ξ‘Ξ£Ξ¤Ξ—Ξ΅Ξ™ΞΞ¤Ξ—Ξ¤Ξ©Ξ =====
    final isGoodWeather = warnings.isEmpty && weatherCode < 50 && temperature >= 10 && temperature <= 30
        && (windSpeed ?? 0) < 30 && humidity < 80;
    
    if (isGoodWeather) {
      activities.add('π¶ Ξ™Ξ΄Ξ±Ξ½ΞΉΞΊΟΟ‚ Ξ³ΞΉΞ± Ο€ΞµΟΟ€Ξ¬Ο„Ξ·ΞΌΞ±/Ο€ΞµΞ¶ΞΏΟ€ΞΏΟΞ―Ξ±');
      if ((windSpeed ?? 0) < 15) {
        activities.add('π£ ΞΞ±Ξ»Ξ­Ο‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚ Ξ³ΞΉΞ± ΟΞ¬ΟΞµΞΌΞ±');
      }
      if (temperature >= 22 && temperature <= 28) {
        activities.add('π– Ξ™Ξ΄Ξ±Ξ½ΞΉΞΊΟΟ‚ Ξ³ΞΉΞ± Ο€Ξ±ΟΞ±Ξ»Ξ―Ξ±');
      }
    }

    if (temperature < 5 || temperature > 35 || weatherCode >= 80) {
      activities.add('π  ΞΞ±Ξ»ΟΟ„ΞµΟΞ± ΞΌΞ­ΟƒΞ± ΟƒΟ„ΞΏ ΟƒΟ€Ξ―Ο„ΞΉ ΟƒΞ®ΞΌΞµΟΞ±');
    }

    // ===== Ξ£Ξ¥ΞΞΞ•Ξ£Ξ— Ξ‘Ξ Ξ‘ΞΞ¤Ξ—Ξ£Ξ—Ξ£ =====
    final List<String> result = [];
    
    if (warnings.isNotEmpty) {
      result.add('π¨ Ξ Ξ΅ΞΞ•Ξ™Ξ”ΞΞ ΞΞ™Ξ—Ξ£Ξ•Ξ™Ξ£:');
      result.addAll(warnings);
      result.add('');
    }
    
    if (insights.isNotEmpty) {
      result.add('π“ Ξ‘ΞΞ‘Ξ›Ξ¥Ξ£Ξ—:');
      result.addAll(insights);
      result.add('');
    }
    
    if (activities.isNotEmpty) {
      result.add('π’΅ Ξ£Ξ¥Ξ£Ξ¤Ξ‘Ξ£Ξ•Ξ™Ξ£:');
      result.addAll(activities);
    }

    if (result.isEmpty) {
      return 'β… Ξ ΞΊΞ±ΞΉΟΟΟ‚ ΞµΞ―Ξ½Ξ±ΞΉ ΟƒΟ„Ξ±ΞΈΞµΟΟΟ‚. Ξ”ΞµΞ½ ΞµΞ½Ο„ΞΏΟ€Ξ―ΟƒΟ„Ξ·ΞΊΞ±Ξ½ Ξ­Ξ½Ο„ΞΏΞ½Ξ± Ο†Ξ±ΞΉΞ½ΟΞΌΞµΞ½Ξ±.';
    }

    return result.join('\n');
  }
}
