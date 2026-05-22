class SensorData {
  final double? pressure;        // hPa από βαρόμετρο
  final double? temperature;     // °C από θερμόμετρο
  final double? humidity;        // % από υγρασιόμετρο
  final double? lightLevel;      // lux από φωτόμετρο
  final double? altitude;        // m από GPS
  final double? accelerometerX;
  final double? accelerometerY;
  final double? accelerometerZ;
  final DateTime timestamp;

  // Trend πίεσης (για πρόβλεψη καιρού)
  final List<double> pressureHistory;

  SensorData({
    this.pressure,
    this.temperature,
    this.humidity,
    this.lightLevel,
    this.altitude,
    this.accelerometerX,
    this.accelerometerY,
    this.accelerometerZ,
    required this.timestamp,
    this.pressureHistory = const [],
  });

  // Τάση πίεσης
  PressureTrend get pressureTrend {
    if (pressureHistory.length < 2) return PressureTrend.stable;
    final diff = pressureHistory.last - pressureHistory.first;
    if (diff > 2) return PressureTrend.rising;
    if (diff < -2) return PressureTrend.falling;
    return PressureTrend.stable;
  }

  String get pressureTrendText {
    switch (pressureTrend) {
      case PressureTrend.rising:
        return '↑ Αυξάνεται (βελτίωση καιρού)';
      case PressureTrend.falling:
        return '↓ Πέφτει (επιδείνωση καιρού)';
      case PressureTrend.stable:
        return '→ Σταθερή';
    }
  }

  // Διαθέσιμοι σένσορες
  bool get hasPressure => pressure != null;
  bool get hasTemperature => temperature != null;
  bool get hasLight => lightLevel != null;
}

enum PressureTrend { rising, falling, stable }