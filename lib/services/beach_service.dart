import 'dart:convert';
import 'package:http/http.dart' as http;

class BeachData {
  final String locationName;
  final double latitude;
  final double longitude;
  final double waveHeight;
  final double waveDirection;
  final double wavePeriod;
  final double seaTemperature;
  final double windSpeed;
  final double windDirection;
  final DateTime time;

  BeachData({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.waveHeight,
    required this.waveDirection,
    required this.wavePeriod,
    required this.seaTemperature,
    required this.windSpeed,
    required this.windDirection,
    required this.time,
  });

  String get waveCondition {
    if (waveHeight < 0.3) return '\u0391\u03c0\u03cc\u03bb\u03c5\u03c4\u03b7 \u03b7\u03c1\u03b5\u03bc\u03af\u03b1';
    if (waveHeight < 0.5) return '\u0397\u03c1\u03b5\u03bc\u03af\u03b1';
    if (waveHeight < 1.0) return '\u039c\u03ad\u03c4\u03c1\u03b9\u03b1 \u03ba\u03cd\u03bc\u03b1\u03c4\u03b1';
    if (waveHeight < 1.5) return '\u039a\u03cd\u03bc\u03b1\u03c4\u03b1';
    if (waveHeight < 2.5) return '\u0399\u03c3\u03c7\u03c5\u03c1\u03ac \u03ba\u03cd\u03bc\u03b1\u03c4\u03b1';
    return '\u03a0\u03bf\u03bb\u03cd \u03b9\u03c3\u03c7\u03c5\u03c1\u03ac \u03ba\u03cd\u03bc\u03b1\u03c4\u03b1';
  }

  String get swimRating {
    if (waveHeight > 1.5 || windSpeed > 40) return 'danger';
    if (waveHeight > 0.8 || windSpeed > 25) return 'warning';
    return 'good';
  }

  String get surfRating {
    if (waveHeight < 0.5 || waveHeight > 3.0) return 'bad';
    if (waveHeight >= 0.5 && waveHeight <= 2.0 && windSpeed < 35) return 'good';
    return 'ok';
  }

  String get divingRating {
    if (waveHeight > 0.5 || windSpeed > 20) return 'bad';
    return 'good';
  }

  String get waveDirectionText {
    const directions = ['\u0392', '\u0392\u0391', '\u0391', '\u0391\u0394', '\u0394', '\u039d\u0394', '\u039d', '\u039d\u0394'];
    final index = ((waveDirection + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}

class BeachService {
  // Geocoding: find coordinates from place name
  static Future<Map<String, dynamic>?> geocodePlace(String placeName) async {
    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(placeName)}&count=1&language=el&format=json'
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          return {
            'name': result['name'] ?? placeName,
            'latitude': result['latitude'],
            'longitude': result['longitude'],
            'country': result['country'] ?? '',
            'admin1': result['admin1'] ?? '',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  // Get marine + weather data for coordinates
  static Future<BeachData?> getBeachData(String locationName, double lat, double lon) async {
    try {
      // Marine API
      final marineUri = Uri.parse(
        'https://marine-api.open-meteo.com/v1/marine?latitude=$lat&longitude=$lon'
        '&hourly=wave_height,wave_direction,wave_period,sea_surface_temperature'
        '&timezone=auto&forecast_days=1'
      );

      // Weather API for wind
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&hourly=wind_speed_10m,wind_direction_10m'
        '&timezone=auto&forecast_days=1'
      );

      final results = await Future.wait([
        http.get(marineUri).timeout(const Duration(seconds: 10)),
        http.get(weatherUri).timeout(const Duration(seconds: 10)),
      ]);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final marineData = jsonDecode(results[0].body);
        final weatherData = jsonDecode(results[1].body);

        // Get current hour index
        final now = DateTime.now();
        final hour = now.hour;

        final hourly = marineData['hourly'];
        final weatherHourly = weatherData['hourly'];

        // Safe value extraction
        double getVal(dynamic list, int idx, double fallback) {
          if (list == null || idx >= list.length || list[idx] == null) return fallback;
          return (list[idx] as num).toDouble();
        }

        return BeachData(
          locationName: locationName,
          latitude: lat,
          longitude: lon,
          waveHeight: getVal(hourly['wave_height'], hour, 0.0),
          waveDirection: getVal(hourly['wave_direction'], hour, 0.0),
          wavePeriod: getVal(hourly['wave_period'], hour, 0.0),
          seaTemperature: getVal(hourly['sea_surface_temperature'], hour, 20.0),
          windSpeed: getVal(weatherHourly['wind_speed_10m'], hour, 0.0),
          windDirection: getVal(weatherHourly['wind_direction_10m'], hour, 0.0),
          time: now,
        );
      }
    } catch (_) {}
    return null;
  }
}
