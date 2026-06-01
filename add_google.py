with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

dollar = chr(36)

# Add import for secure storage at top
if "flutter_secure_storage" not in lines[1]:
    lines.insert(1, "import 'package:flutter_secure_storage/flutter_secure_storage.dart';\n")

# Find findNearbyBeaches again (shifted by 1)
start = None
for i, line in enumerate(lines):
    if "static Future<List<Map<String, dynamic>>> findNearbyBeaches" in line:
        start = i
        break

# Google Places method to insert before findNearbyBeaches
google_method = [
    "  static Future<List<Map<String, dynamic>>> _findBeachesGoogle(\n",
    "      double lat, double lon, String apiKey, {int radiusKm = 30}) async {\n",
    "    try {\n",
    f"      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'\n",
    f"          '?location={dollar}lat,{dollar}lon&radius={dollar}{{radiusKm * 1000}}&type=natural_feature'\n",
    f"          '&keyword=beach%20paralia&language=el&key={dollar}apiKey';\n",
    "      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));\n",
    "      if (response.statusCode == 200) {\n",
    "        final data = jsonDecode(response.body);\n",
    "        final results = data['results'] as List? ?? [];\n",
    "        final beaches = <Map<String, dynamic>>[];\n",
    "        for (final r in results) {\n",
    "          final name = r['name'] as String?;\n",
    "          final geo = r['geometry']?['location'];\n",
    "          if (name == null || geo == null) continue;\n",
    "          final bLat = (geo['lat'] as num).toDouble();\n",
    "          final bLon = (geo['lng'] as num).toDouble();\n",
    "          final dlat = bLat - lat;\n",
    "          final dlon = bLon - lon;\n",
    "          final distKm = (111.0 * (dlat * dlat + dlon * dlon) * 0.5);\n",
    "          beaches.add({\n",
    "            'name': name,\n",
    "            'lat': bLat,\n",
    "            'lon': bLon,\n",
    "            'distKm': double.parse(distKm.toStringAsFixed(1)),\n",
    "            'rating': (r['rating'] as num?)?.toDouble() ?? 0.0,\n",
    "          });\n",
    "        }\n",
    "        beaches.sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));\n",
    "        return beaches;\n",
    "      }\n",
    "    } catch (_) {}\n",
    "    return [];\n",
    "  }\n",
    "\n",
]

new_lines = lines[:start] + google_method + lines[start:]

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! Inserted Google method at line", start)
