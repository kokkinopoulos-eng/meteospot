import 'dart:convert';
import 'package:http/http.dart' as http;

class BeachData {
  final String locationName;
  final double latitude;
  final double longitude;
  final double waveHeight;    // meters (beach) or cm (ski = snow depth)
  final double waveDirection;
  final double wavePeriod;    // seconds (beach) or km visibility (ski)
  final double seaTemperature; // water temp (beach) or air temp (ski)
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
    if (waveHeight < 0.3) return 'Απόλυτη ηρεμία';
    if (waveHeight < 0.5) return 'Ηρεμία';
    if (waveHeight < 1.0) return 'Μέτρια κύματα';
    if (waveHeight < 1.5) return 'Κύματα';
    if (waveHeight < 2.5) return 'Ισχυρά κύματα';
    return 'Πολύ ισχυρά κύματα';
  }

  String get skiCondition {
    if (waveHeight >= 100) return 'Άριστες συνθήκες';
    if (waveHeight >= 50) return 'Καλές συνθήκες';
    if (waveHeight >= 20) return 'Μέτριες συνθήκες';
    if (waveHeight >= 5) return 'Λίγο χιόνι';
    return 'Χωρίς χιόνι';
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
    const directions = ['Β', 'ΒΑ', 'Α', 'ΝΑ', 'Ν', 'ΝΔ', 'Δ', 'ΒΔ'];
    final index = ((waveDirection + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}

class BeachService {
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
          };
        }
      }
    } catch (_) {}
    return null;
  }

  // Check if coordinates are in the sea (not on land)
  static Future<bool> isSeaLocation(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://marine-api.open-meteo.com/v1/marine?latitude=$lat&longitude=$lon'
        '&hourly=wave_height&forecast_days=1'
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      final hourly = data['hourly'];
      if (hourly == null) return false;
      final waveHeights = hourly['wave_height'] as List?;
      if (waveHeights == null || waveHeights.isEmpty) return false;
      return waveHeights.any((v) => v != null);
    } catch (_) {
      return false;
    }
  }

  static Future<BeachData?> getBeachData(String locationName, double lat, double lon) async {
    try {
      final marineUri = Uri.parse(
        'https://marine-api.open-meteo.com/v1/marine?latitude=$lat&longitude=$lon'
        '&hourly=wave_height,wave_direction,wave_period,sea_surface_temperature'
        '&timezone=auto&forecast_days=1'
      );
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&hourly=wind_speed_10m,wind_direction_10m'
        '&timezone=auto&forecast_days=1'
      );

      final results = await Future.wait([
        http.get(marineUri).timeout(const Duration(seconds: 10)),
        http.get(weatherUri).timeout(const Duration(seconds: 10)),
      ]);

      // If marine API returns error, location is on land
      if (results[0].statusCode != 200) return null;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final marineData = jsonDecode(results[0].body);
        final weatherData = jsonDecode(results[1].body);
        final hour = DateTime.now().hour;
        final hourly = marineData['hourly'];
        final weatherHourly = weatherData['hourly'];

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
          time: DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<BeachData?> getSkiData(String locationName, double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&hourly=temperature_2m,wind_speed_10m,wind_direction_10m,snow_depth,visibility'
        '&timezone=auto&forecast_days=1'
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hour = DateTime.now().hour;
        final hourly = data['hourly'];

        double getVal(dynamic list, int idx, double fallback) {
          if (list == null || idx >= list.length || list[idx] == null) return fallback;
          return (list[idx] as num).toDouble();
        }

        final snowDepthM = getVal(hourly['snow_depth'], hour, 0.0);
        final visibilityM = getVal(hourly['visibility'], hour, 10000.0);

        return BeachData(
          locationName: locationName,
          latitude: lat,
          longitude: lon,
          waveHeight: snowDepthM * 100,    // cm
          waveDirection: getVal(hourly['wind_direction_10m'], hour, 0.0),
          wavePeriod: visibilityM / 1000,   // km
          seaTemperature: getVal(hourly['temperature_2m'], hour, 0.0),
          windSpeed: getVal(hourly['wind_speed_10m'], hour, 0.0),
          windDirection: getVal(hourly['wind_direction_10m'], hour, 0.0),
          time: DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=el'
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MetAIoSpot/1.0 (gr.webdevelopment.metaiospot)'
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address != null) {
          final parts = <String>[];
          if (address['village'] != null) parts.add(address['village']);
          else if (address['town'] != null) parts.add(address['town']);
          else if (address['city'] != null) parts.add(address['city']);
          if (address['county'] != null) parts.add(address['county']);
          else if (address['state'] != null) parts.add(address['state']);
          if (parts.isNotEmpty) return parts.join(', ');
          return data['display_name']?.toString().split(',').take(2).join(',');
        }
      }
    } catch (_) {}
    return null;
  }


  // Check if location is mountainous (elevation > 600m) for ski restriction
  static Future<bool> isMountainLocation(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/elevation?latitude=$lat&longitude=$lon'
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elevation = (data['elevation'] as List?)?.firstOrNull;
        if (elevation != null) {
          return (elevation as num).toDouble() > 600;
        }
      }
    } catch (_) {}
    return false;
  }


  static Future<List<Map<String, dynamic>>> findNearbyBeaches(
      double lat, double lon, {int radiusKm = 50}) async {
    final query = '[out:json][timeout:25];'
        '(node["natural"="beach"](around:\,\,\);'
        'way["natural"="beach"](around:\,\,\););'
        'out center 15;';
    final mirrors = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass.openstreetmap.ru/api/interpreter',
    ];
    for (final mirror in mirrors) {
      try {
        final uri = Uri.parse(mirror).replace(queryParameters: {'data': query});
        final response = await http.get(uri, headers: {
          'User-Agent': 'MetAIoSpot/1.0 (gr.webdevelopment.metaiospot)'
        }).timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final elements = data['elements'] as List? ?? [];
          final beaches = <Map<String, dynamic>>[];
          for (final e in elements) {
            final tags = e['tags'] as Map? ?? {};
            final name = tags['name'] ?? tags['name:el'] ?? 'Παραλία';
            final eLat = (e['lat'] ?? e['center']?['lat']) as num?;
            final eLon = (e['lon'] ?? e['center']?['lon']) as num?;
            if (eLat != null && eLon != null) {
              beaches.add({'name': name, 'lat': eLat.toDouble(), 'lon': eLon.toDouble()});
            }
          }
          if (beaches.isNotEmpty) return beaches;
        }
      } catch (_) { continue; }
    }
    return [];
  }
}
