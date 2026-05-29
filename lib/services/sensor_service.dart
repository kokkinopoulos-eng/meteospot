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

  /// Advanced Rule-Based AI - Αναλύει καιρό με πολλούς κανόνες
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

    // ===== ΑΝΑΛΥΣΗ ΠΙΕΣΗΣ =====
    if (_pressureHistory.length >= 2) {
      final trend = _pressureHistory.last - _pressureHistory.first;
      if (trend < -5) {
        warnings.add('⚠️ Η πίεση πέφτει απότομα - πιθανή καταιγίδα σε 1-3 ώρες');
      } else if (trend < -3) {
        warnings.add('🌧 Η πίεση πέφτει γρήγορα - επιδείνωση σε 2-4 ώρες');
      } else if (trend < -1) {
        insights.add('🌥 Η πίεση πέφτει - πιθανή βροχή αργότερα');
      } else if (trend > 3) {
        insights.add('☀️ Η πίεση αυξάνεται - βελτίωση καιρού');
      } else if (trend > 1) {
        insights.add('🌤 Σταθερή ανοδική τάση πίεσης');
      }
    }

    // Απόλυτη πίεση
    if (apiPressure < 990) {
      warnings.add('⛈ Πολύ χαμηλή πίεση (${apiPressure.toStringAsFixed(0)} hPa) - ασταθής καιρός');
    } else if (apiPressure > 1025) {
      insights.add('☀️ Υψηλή πίεση (${apiPressure.toStringAsFixed(0)} hPa) - σταθερός καιρός');
    }

    // ===== ΑΝΑΛΥΣΗ ΥΓΡΑΣΙΑΣ =====
    if (humidity > 90) {
      warnings.add('💧 Πολύ υψηλή υγρασία (${humidity.toInt()}%) - πιθανή ομίχλη ή βροχή');
    } else if (humidity > 80) {
      insights.add('🌫 Υψηλή υγρασία - πνιγηρή ατμόσφαιρα');
    } else if (humidity < 30) {
      insights.add('🏜 Χαμηλή υγρασία - ξηρός αέρας, πιείτε νερό');
    }

    // ===== ΑΝΑΛΥΣΗ ΘΕΡΜΟΚΡΑΣΙΑΣ =====
    if (temperature > 40) {
      warnings.add('🔥 ΑΚΡΑΙΑ ζέστη (${temperature.toStringAsFixed(0)}°C) - κίνδυνος θερμοπληξίας!');
    } else if (temperature > 35) {
      warnings.add('🌡 Πολύ υψηλή θερμοκρασία - αποφύγετε ηλιακή έκθεση 12-16μμ');
    } else if (temperature > 30) {
      insights.add('☀️ Ζέστη - φοράτε καπέλο και αντιηλιακό');
    } else if (temperature < -5) {
      warnings.add('🥶 ΑΚΡΑΙΟ κρύο - κίνδυνος υποθερμίας');
    } else if (temperature < 2) {
      warnings.add('❄️ Κίνδυνος παγετού - προσοχή στους δρόμους');
    } else if (temperature < 10) {
      insights.add('🧥 Κρύο - χρειάζεστε ζεστά ρούχα');
    }

    // Αίσθηση θερμοκρασίας
    if (feelsLike != null) {
      final diff = (feelsLike - temperature).abs();
      if (diff > 5) {
        if (feelsLike > temperature) {
          insights.add('🥵 Αίσθηση πιο ζεστή λόγω υγρασίας (${feelsLike.toStringAsFixed(0)}°C)');
        } else {
          insights.add('🥶 Αίσθηση πιο κρύα λόγω ανέμου (${feelsLike.toStringAsFixed(0)}°C)');
        }
      }
    }

    // ===== ΑΝΑΛΥΣΗ ΑΝΕΜΟΥ =====
    if (windSpeed != null) {
      if (windSpeed > 70) {
        warnings.add('🌀 ΘΥΕΛΛΩΔΕΙΣ άνεμοι (${windSpeed.toStringAsFixed(0)} km/h) - μείνετε μέσα!');
      } else if (windSpeed > 50) {
        warnings.add('💨 Πολύ ισχυροί άνεμοι - επικίνδυνο για πεζοπορία/ψάρεμα');
      } else if (windSpeed > 30) {
        insights.add('💨 Ισχυροί άνεμοι - προσοχή σε εξωτερικές δραστηριότητες');
      } else if (windSpeed < 5) {
        insights.add('🍃 Ήρεμος άνεμος - ιδανικό για drone, ψάρεμα, μπάρμπεκιου');
      }
    }

    // ===== ΑΝΑΛΥΣΗ UV =====
    if (uvIndex != null) {
      if (uvIndex >= 11) {
        warnings.add('☢️ ΑΚΡΑΙΑ UV (${uvIndex.toStringAsFixed(0)}) - απαραίτητη προστασία');
      } else if (uvIndex >= 8) {
        warnings.add('🔆 Πολύ υψηλή UV - αντιηλιακό SPF 50+, καπέλο, γυαλιά');
      } else if (uvIndex >= 6) {
        insights.add('☀️ Υψηλή UV - χρειάζεται αντιηλιακό');
      } else if (uvIndex >= 3) {
        insights.add('🌤 Μέτρια UV - προστασία τις μεσημεριανές ώρες');
      }
    }

    // ===== ΑΝΑΛΥΣΗ ΟΡΑΤΟΤΗΤΑΣ =====
    if (visibility != null) {
      if (visibility < 1000) {
        warnings.add('🌫 Πολύ χαμηλή ορατότητα (${(visibility / 1000).toStringAsFixed(1)} km) - επικίνδυνη οδήγηση');
      } else if (visibility < 5000) {
        insights.add('🌫 Μειωμένη ορατότητα - προσοχή στην οδήγηση');
      }
    }

    // ===== ΑΝΑΛΥΣΗ WEATHER CODE =====
    if (weatherCode >= 95) {
      warnings.add('⛈ Καταιγίδα ενεργή - μείνετε σε κλειστό χώρο');
    } else if (weatherCode >= 80) {
      warnings.add('🌧 Έντονη βροχόπτωση - πάρτε ομπρέλα');
    } else if (weatherCode >= 71 && weatherCode <= 77) {
      warnings.add('🌨 Χιονόπτωση - προσοχή σε μετακινήσεις');
    } else if (weatherCode >= 61 && weatherCode <= 67) {
      insights.add('🌦 Ψιχάλα - πάρτε ελαφρύ αδιάβροχο');
    } else if (weatherCode >= 51 && weatherCode <= 57) {
      insights.add('💧 Ψιχάλα - πιθανή ελαφριά βροχή');
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      insights.add('🌫 Ομίχλη - μειωμένη ορατότητα');
    }

    // ===== ΣΥΣΤΑΣΕΙΣ ΔΡΑΣΤΗΡΙΟΤΗΤΩΝ =====
    final isGoodWeather = warnings.isEmpty && weatherCode < 50 && temperature >= 10 && temperature <= 30
        && (windSpeed ?? 0) < 30 && humidity < 80;
    
    if (isGoodWeather) {
      activities.add('🚶 Ιδανικός για περπάτημα/πεζοπορία');
      if ((windSpeed ?? 0) < 15) {
        activities.add('🎣 Καλές συνθήκες για ψάρεμα');
      }
      if (temperature >= 22 && temperature <= 28) {
        activities.add('🏖 Ιδανικός για παραλία');
      }
    }

    if (temperature < 5 || temperature > 35 || weatherCode >= 80) {
      activities.add('🏠 Καλύτερα μέσα στο σπίτι σήμερα');
    }

    // ===== ΣΥΝΘΕΣΗ ΑΠΑΝΤΗΣΗΣ =====
    final List<String> result = [];
    
    if (warnings.isNotEmpty) {
      result.add('🚨 ΠΡΟΕΙΔΟΠΟΙΗΣΕΙΣ:');
      result.addAll(warnings);
      result.add('');
    }
    
    if (insights.isNotEmpty) {
      result.add('📊 ΑΝΑΛΥΣΗ:');
      result.addAll(insights);
      result.add('');
    }
    
    if (activities.isNotEmpty) {
      result.add('💡 ΣΥΣΤΑΣΕΙΣ:');
      result.addAll(activities);
    }

    if (result.isEmpty) {
      return '✅ Ο καιρός είναι σταθερός. Δεν εντοπίστηκαν έντονα φαινόμενα.';
    }

    return result.join('\n');
  }
}
