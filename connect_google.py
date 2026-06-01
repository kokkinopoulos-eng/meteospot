with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "static Future<List<Map<String, dynamic>>> findNearbyBeaches" in line:
        start = i
        break

# Insert Google check right after the opening line (after line start+1 which is the params)
google_check = [
    "    // Try Google Places first if user provided a key\n",
    "    try {\n",
    "      const storage = FlutterSecureStorage();\n",
    "      final googleKey = await storage.read(key: 'google_places_key');\n",
    "      if (googleKey != null && googleKey.isNotEmpty) {\n",
    "        final googleResults = await _findBeachesGoogle(lat, lon, googleKey, radiusKm: 30);\n",
    "        if (googleResults.isNotEmpty) return googleResults;\n",
    "      }\n",
    "    } catch (_) {}\n",
]

# Insert after line start+1 (the params line ending with async {)
new_lines = lines[:start+2] + google_check + lines[start+2:]

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done")
