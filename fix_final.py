with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

dollar = chr(36)
new_func = [
    "  static Future<List<Map<String, dynamic>>> findNearbyBeaches(\n",
    "      double lat, double lon, {int radiusKm = 50}) async {\n",
    "    final query = '[out:json][timeout:25];'\n",
    f"        '(node[\"natural\"=\"beach\"](around:{dollar}{{radiusKm * 1000}},{dollar}lat,{dollar}lon);'\n",
    f"        'way[\"natural\"=\"beach\"](around:{dollar}{{radiusKm * 1000}},{dollar}lat,{dollar}lon););'\n",
    "        'out center 15;';\n",
    "    final mirrors = [\n",
    "      'https://overpass-api.de/api/interpreter',\n",
    "      'https://overpass.kumi.systems/api/interpreter',\n",
    "      'https://overpass.openstreetmap.ru/api/interpreter',\n",
    "    ];\n",
    "    for (final mirror in mirrors) {\n",
    "      try {\n",
    "        final uri = Uri.parse(mirror).replace(queryParameters: {'data': query});\n",
    "        final response = await http.get(uri, headers: {\n",
    "          'User-Agent': 'MetAIoSpot/1.0 (gr.webdevelopment.metaiospot)'\n",
    "        }).timeout(const Duration(seconds: 15));\n",
    "        if (response.statusCode == 200) {\n",
    "          final data = jsonDecode(response.body);\n",
    "          final elements = data['elements'] as List? ?? [];\n",
    "          final beaches = <Map<String, dynamic>>[];\n",
    "          for (final e in elements) {\n",
    "            final tags = e['tags'] as Map? ?? {};\n",
    "            final name = tags['name'] ?? tags['name:el'] ?? tags['name:en'];\n",
    "            if (name == null) continue;\n",
    "            final eLat = (e['lat'] ?? e['center']?['lat']) as num?;\n",
    "            final eLon = (e['lon'] ?? e['center']?['lon']) as num?;\n",
    "            if (eLat != null && eLon != null) {\n",
    "              final dlat = eLat.toDouble() - lat;\n",
    "              final dlon = eLon.toDouble() - lon;\n",
    "              final distKm = (111.0 * (dlat * dlat + dlon * dlon) * 0.5);\n",
    "              beaches.add({'name': name, 'lat': eLat.toDouble(), 'lon': eLon.toDouble(), 'distKm': double.parse(distKm.toStringAsFixed(1))});\n",
    "            }\n",
    "          }\n",
    "          if (beaches.isNotEmpty) {\n",
    "            beaches.sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));\n",
    "            return beaches;\n",
    "          }\n",
    "        }\n",
    "      } catch (_) { continue; }\n",
    "    }\n",
    "    return [];\n",
    "  }\n",
]

new_lines = lines[:382] + new_func + lines[412:]

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! Total lines:", len(new_lines))
