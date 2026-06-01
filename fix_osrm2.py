with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

dollar = chr(36)
new_block = [
    "          if (beaches.isNotEmpty) {\n",
    "            final verified = <Map<String, dynamic>>[];\n",
    "            for (final b in beaches) {\n",
    "              final roadDist = await _roadDistance(lat, lon, b['lat'] as double, b['lon'] as double);\n",
    "              if (roadDist != null && roadDist <= radiusKm * 2) {\n",
    "                verified.add({...b, 'distKm': double.parse(roadDist.toStringAsFixed(1))});\n",
    "              } else if (roadDist == null) {\n",
    "                verified.add(b);\n",
    "              }\n",
    "            }\n",
    "            if (verified.isNotEmpty) {\n",
    "              verified.sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));\n",
    "              return verified;\n",
    "            }\n",
    "            return beaches;\n",
    "          }\n",
]

new_lines = lines[:412] + new_block + lines[413:]

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! Total lines:", len(new_lines))
