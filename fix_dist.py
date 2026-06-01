with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

new_block = [
    "    final radiusDeg = radiusKm / 111.0;\n",
    "    final nearby = _greekBeachesFallback.where((b) {\n",
    "      final dlat = (b['lat'] as double) - lat;\n",
    "      final dlon = (b['lon'] as double) - lon;\n",
    "      return (dlat * dlat + dlon * dlon) <= radiusDeg * radiusDeg;\n",
    "    }).toList();\n",
    "    nearby.sort((a, b) {\n",
    "      final da = _distance(lat, lon, a['lat'] as double, a['lon'] as double);\n",
    "      final db = _distance(lat, lon, b['lat'] as double, b['lon'] as double);\n",
    "      return da.compareTo(db);\n",
    "    });\n",
    "    return nearby.map((b) {\n",
    "      final dlat = (b['lat'] as double) - lat;\n",
    "      final dlon = (b['lon'] as double) - lon;\n",
    "      final distKm = (111.0 * (dlat * dlat + dlon * dlon).abs() * 0.5);\n",
    "      return {'name': b['name'], 'lat': b['lat'], 'lon': b['lon'], 'distKm': double.parse(distKm.toStringAsFixed(1))};\n",
    "    }).toList();\n",
    "  }\n",
    "}\n",
]

new_lines = lines[:376] + new_block

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! Lines:", len(new_lines))
