class WeatherData {
  final double latitude;
  final double longitude;
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final double pressure;
  final double uvIndex;
  final double visibility;
  final int weatherCode;
  final String description;
  final DateTime timestamp;
  final double elevation;
  String locationName;

  // Sensor data (από το κινητό)
  double? sensorPressure;
  double? sensorTemperature;
  double? lightLevel;
  double? altitude;

  WeatherData({
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.uvIndex,
    required this.visibility,
    required this.weatherCode,
    required this.description,
    required this.timestamp,
    required this.elevation,
    this.locationName = '',
    this.sensorPressure,
    this.sensorTemperature,
    this.lightLevel,
    this.altitude,
  });

  // Μετατροπή από Open-Meteo JSON
  factory WeatherData.fromOpenMeteo(
      Map<String, dynamic> json, double lat, double lon) {
    final current = json['current'] as Map<String, dynamic>;
    return WeatherData(
      latitude: lat,
      longitude: lon,
      temperature: (current['temperature_2m'] ?? 0).toDouble(),
      feelsLike: (current['apparent_temperature'] ?? 0).toDouble(),
      humidity: (current['relative_humidity_2m'] ?? 0).toDouble(),
      windSpeed: (current['wind_speed_10m'] ?? 0).toDouble(),
      windDirection: (current['wind_direction_10m'] ?? 0).toDouble(),
      pressure: (current['surface_pressure'] ?? 0).toDouble(),
      uvIndex: (current['uv_index'] ?? 0).toDouble(),
      visibility: (current['visibility'] ?? 0).toDouble(),
      weatherCode: (current['weather_code'] ?? 0).toInt(),
      description: _getWeatherDescription(current['weather_code'] ?? 0),
      timestamp: DateTime.now(),
      elevation: (json['elevation'] ?? 0).toDouble(),
    );
  }

  static String _getWeatherDescription(int code) {
    if (code == 0) return 'Αίθριος καιρός';
    if (code <= 3) return 'Συννεφιά';
    if (code <= 9) return 'Ομίχλη';
    if (code <= 19) return 'Ψιλόβροχο';
    if (code <= 29) return 'Βροχή';
    if (code <= 39) return 'Χιόνι';
    if (code <= 49) return 'Παγοκρύσταλλοι';
    if (code <= 59) return 'Ψιλόβροχο';
    if (code <= 69) return 'Βροχή';
    if (code <= 79) return 'Χιόνι';
    if (code <= 99) return 'Καταιγίδα';
    return 'Άγνωστος καιρός';
  }

  // Εικονίδιο καιρού
  String get weatherEmoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 9) return '🌫️';
    if (weatherCode <= 39) return '🌧️';
    if (weatherCode <= 79) return '❄️';
    if (weatherCode <= 99) return '⛈️';
    return '🌡️';
  }

  // Κατεύθυνση ανέμου
  String get windDirectionText {
    if (windDirection < 22.5) return 'Β';
    if (windDirection < 67.5) return 'ΒΑ';
    if (windDirection < 112.5) return 'Α';
    if (windDirection < 157.5) return 'ΝΑ';
    if (windDirection < 202.5) return 'Ν';
    if (windDirection < 247.5) return 'ΝΔ';
    if (windDirection < 292.5) return 'Δ';
    if (windDirection < 337.5) return 'ΒΔ';
    return 'Β';
  }

  // Έχει sensor data;
  bool get hasSensorData =>
      sensorPressure != null ||
      sensorTemperature != null ||
      lightLevel != null;
}
