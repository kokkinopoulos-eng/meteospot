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


  static double _distance(double lat1, double lon1, double lat2, double lon2) {
    final dlat = (lat2 - lat1).abs();
    final dlon = (lon2 - lon1).abs();
    return dlat * dlat + dlon * dlon;
  }

  static const List<Map<String, dynamic>> _greekBeachesFallback = [
    {'name': 'Βουλιαγμένη', 'lat': 37.8123, 'lon': 23.7812},
    {'name': 'Βάρκιζα', 'lat': 37.8012, 'lon': 23.7923},
    {'name': 'Λούτσα', 'lat': 37.9312, 'lon': 24.0523},
    {'name': 'Ραφήνα', 'lat': 38.0212, 'lon': 24.0012},
    {'name': 'Σχοινιάς', 'lat': 38.1534, 'lon': 24.0345},
    {'name': 'Νέα Μάκρη', 'lat': 38.0934, 'lon': 23.9823},
    {'name': 'Ανάβυσσος', 'lat': 37.7234, 'lon': 23.9312},
    {'name': 'Σαρωνίδα', 'lat': 37.7512, 'lon': 23.9534},
    {'name': 'Γλυφάδα', 'lat': 37.8712, 'lon': 23.7523},
    {'name': 'Φάληρο', 'lat': 37.9234, 'lon': 23.6934},
    {'name': 'Καλλιθέα Χαλκιδικής', 'lat': 40.0823, 'lon': 23.1534},
    {'name': 'Κασσάνδρα', 'lat': 39.9712, 'lon': 23.3823},
    {'name': 'Σάνη', 'lat': 40.0534, 'lon': 23.3012},
    {'name': 'Χανιώτη', 'lat': 39.9923, 'lon': 23.4234},
    {'name': 'Νικήτη', 'lat': 40.2123, 'lon': 23.6534},
    {'name': 'Ουρανούπολη', 'lat': 40.3323, 'lon': 23.9712},
    {'name': 'Ελαφονήσι', 'lat': 35.2634, 'lon': 23.5312},
    {'name': 'Μπάλος', 'lat': 35.5923, 'lon': 23.5634},
    {'name': 'Βάι', 'lat': 35.2523, 'lon': 26.2512},
    {'name': 'Σταλίδα', 'lat': 35.2934, 'lon': 25.4123},
    {'name': 'Μάλια', 'lat': 35.2812, 'lon': 25.5034},
    {'name': 'Χερσόνησος', 'lat': 35.2712, 'lon': 25.3723},
    {'name': 'Αγία Γαλήνη', 'lat': 35.0923, 'lon': 24.6923},
    {'name': 'Πλακιάς', 'lat': 35.1834, 'lon': 24.4034},
    {'name': 'Ρέθυμνο παραλία', 'lat': 35.3712, 'lon': 24.4712},
    {'name': 'Γεωργιούπολη', 'lat': 35.3623, 'lon': 24.2534},
    {'name': 'Χανιά παραλία', 'lat': 35.5134, 'lon': 24.0212},
    {'name': 'Φαλάσαρνα', 'lat': 35.5012, 'lon': 23.5712},
    {'name': 'Λίντος', 'lat': 36.0923, 'lon': 28.0834},
    {'name': 'Φαληράκι', 'lat': 36.3234, 'lon': 28.2012},
    {'name': 'Τσαμπίκα', 'lat': 36.2034, 'lon': 28.1312},
    {'name': 'Πεφκός', 'lat': 36.0712, 'lon': 28.0623},
    {'name': 'Παλαιοκαστρίτσα', 'lat': 39.6623, 'lon': 19.6934},
    {'name': 'Γλυφάδα Κέρκυρας', 'lat': 39.5934, 'lon': 19.7812},
    {'name': 'Μυρτιώτισσα', 'lat': 39.5823, 'lon': 19.7234},
    {'name': 'Αγίος Γόρδης', 'lat': 39.5234, 'lon': 19.8234},
    {'name': 'Πλατύς Γιαλός Μυκόνου', 'lat': 37.3934, 'lon': 25.3612},
    {'name': 'Ψαρού', 'lat': 37.4112, 'lon': 25.3234},
    {'name': 'Περίσσα', 'lat': 36.3523, 'lon': 25.4712},
    {'name': 'Καμάρι', 'lat': 36.3734, 'lon': 25.4834},
    {'name': 'Ναυάγιο Ζακύνθου', 'lat': 37.8612, 'lon': 20.6234},
    {'name': 'Λαγανάς', 'lat': 37.7234, 'lon': 20.8534},
    {'name': 'Μύρτος Κεφαλονιάς', 'lat': 38.2334, 'lon': 20.5512},
    {'name': 'Αντίσαμος', 'lat': 38.2512, 'lon': 20.6823},
    {'name': 'Εγκρεμνοί', 'lat': 38.6923, 'lon': 20.5534},
    {'name': 'Πόρτο Κατσίκι', 'lat': 38.6512, 'lon': 20.5423},
    {'name': 'Κουκουναριές', 'lat': 39.1423, 'lon': 23.4234},
    {'name': 'Λαλάρια', 'lat': 39.1912, 'lon': 23.5234},
    {'name': 'Χρυσή Ακτή Πάρου', 'lat': 37.0234, 'lon': 25.2534},
    {'name': 'Κολυμπήθρες Πάρου', 'lat': 37.1123, 'lon': 25.1923},
    {'name': 'Αγία Άννα Νάξου', 'lat': 37.0312, 'lon': 25.3634},
    {'name': 'Πλάκα Νάξου', 'lat': 37.0123, 'lon': 25.3512},
    {'name': 'Σαραντινάρι Μήλου', 'lat': 36.7234, 'lon': 24.4623},
    {'name': 'Φυριπλάκα', 'lat': 36.6812, 'lon': 24.4523},
    {'name': 'Τίγκακι', 'lat': 36.8534, 'lon': 27.0823},
    {'name': 'Κάρδαμαινα', 'lat': 36.7823, 'lon': 27.1523},
    {'name': 'Χρυσή Αμμουδιά Θάσου', 'lat': 40.7234, 'lon': 24.6634},
    {'name': 'Αλυκή Θάσου', 'lat': 40.6523, 'lon': 24.7312},
    {'name': 'Βατερά', 'lat': 38.9734, 'lon': 26.2334},
    {'name': 'Ψιλή Άμμος Σάμου', 'lat': 37.6634, 'lon': 26.9423},
    {'name': 'Κοκκάρι', 'lat': 37.7934, 'lon': 26.8812},
    {'name': 'Βοϊδοκοιλιά', 'lat': 36.9734, 'lon': 21.6623},
    {'name': 'Τολό', 'lat': 37.5123, 'lon': 22.8634},
    {'name': 'Πόρτο Χέλι', 'lat': 37.3234, 'lon': 23.1512},
    {'name': 'Μονεμβάσια', 'lat': 36.6923, 'lon': 23.0534},
    {'name': 'Ελαφόνησος', 'lat': 36.4923, 'lon': 22.9734},
    {'name': 'Στούπα', 'lat': 36.8423, 'lon': 22.2712},
    {'name': 'Μεθώνη', 'lat': 36.8212, 'lon': 21.7034},
    {'name': 'Κορώνη', 'lat': 36.7934, 'lon': 21.9623},
    {'name': 'Φοινικούντα', 'lat': 36.8034, 'lon': 21.8134},
    {'name': 'Μηλοπότας', 'lat': 36.7134, 'lon': 25.3312},
    {'name': 'Μαγγανάρι', 'lat': 36.6823, 'lon': 25.3534},
    {'name': 'Στάφυλος', 'lat': 39.1023, 'lon': 23.7234},
    {'name': 'Μύρινα Λήμνου', 'lat': 39.8734, 'lon': 25.0612},
    {'name': 'Μαγαζιά Σκύρου', 'lat': 38.8934, 'lon': 24.5534},
    {'name': 'Πλατύς Γιαλός Σίφνου', 'lat': 36.9423, 'lon': 24.7234},
    {'name': 'Γρίκος Πάτμου', 'lat': 37.2934, 'lon': 26.5623},
    {'name': 'Νιμπόριο Σύμης', 'lat': 36.6234, 'lon': 27.8423},
    {'name': 'Κάρφας Χίου', 'lat': 38.3234, 'lon': 26.1423},
    {'name': 'Παχιά Άμμος Σαμοθράκης', 'lat': 40.4423, 'lon': 25.5534},
    {'name': 'Αιγιάλη Αμοργού', 'lat': 36.8534, 'lon': 25.9023},
    {'name': 'Λούρδας Κεφαλονιάς', 'lat': 38.0923, 'lon': 20.7234},
    {'name': 'Βασιλική Λευκάδας', 'lat': 38.6234, 'lon': 20.6623},
    {'name': 'Ξυλόκαστρο', 'lat': 38.0734, 'lon': 22.6334},
    {'name': 'Λουτράκι παραλία', 'lat': 37.9623, 'lon': 22.9734},
    {'name': 'Νέα Επίδαυρος', 'lat': 37.6434, 'lon': 23.1523},
    {'name': 'Ερμιόνη', 'lat': 37.3834, 'lon': 23.2512},
  ];

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
        }).timeout(const Duration(seconds: 15));
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
    final radiusDeg = radiusKm / 111.0;
    final nearby = _greekBeachesFallback.where((b) {
      final dlat = (b['lat'] as double) - lat;
      final dlon = (b['lon'] as double) - lon;
      return (dlat * dlat + dlon * dlon) <= radiusDeg * radiusDeg;
    }).toList();
    nearby.sort((a, b) {
      final da = _distance(lat, lon, a['lat'] as double, a['lon'] as double);
      final db = _distance(lat, lon, b['lat'] as double, b['lon'] as double);
      return da.compareTo(db);
    });
    return nearby;
  }
}
