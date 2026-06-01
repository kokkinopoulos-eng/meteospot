with open("C:/meteospot/lib/services/ai_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

new_block = []
new_block.append("  String buildWeatherContext({\n")
new_block.append("    required double temperature, required double feelsLike,\n")
new_block.append("    required double humidity, required double windSpeed,\n")
new_block.append("    required String windDirection, required double pressure,\n")
new_block.append("    required double uvIndex, required double visibility,\n")
new_block.append("    required String description, required double elevation,\n")
new_block.append("    required double latitude, required double longitude,\n")
new_block.append("    String locationName = '',\n")
new_block.append("  }) {\n")
new_block.append("    final loc = locationName.isNotEmpty\n")
new_block.append("        ? locationName\n")
new_block.append("        : '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';\n")
new_block.append("    return '''\n")
new_block.append("" + chr(0x1F4CD) + " " + chr(0x03A4) + chr(0x03BF) + chr(0x03C0) + chr(0x03BF) + chr(0x03B8) + chr(0x03B5) + chr(0x03C3) + chr(0x03AF) + chr(0x03B1) + ": $loc (${elevation.toInt()}m " + chr(0x03C5) + chr(0x03C8) + chr(0x03CC) + chr(0x03BC) + chr(0x03B5) + chr(0x03C4) + chr(0x03C1) + chr(0x03BF) + ")\n")
new_block.append("${temperature.toStringAsFixed(1)}" + chr(0xB0) + "C (" + chr(0x03B1) + chr(0x03AF) + chr(0x03C3) + chr(0x03B8) + chr(0x03B7) + chr(0x03C3) + chr(0x03B7) + ": ${feelsLike.toStringAsFixed(1)}" + chr(0xB0) + "C)\n")
new_block.append("${humidity.toInt()}%\n")
new_block.append("${windSpeed.toStringAsFixed(1)} km/h " + chr(0x03B1) + chr(0x03C0) + chr(0x03CC) + " $windDirection\n")
new_block.append("${pressure.toStringAsFixed(0)} hPa\n")
new_block.append("${uvIndex.toStringAsFixed(1)}\n")
new_block.append("${(visibility / 1000).toStringAsFixed(1)} km\n")
new_block.append("$description\n")
new_block.append("''';\n")
new_block.append("  }\n")
new_block.append("}\n")

new_lines = lines[:266] + new_block

with open("C:/meteospot/lib/services/ai_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! Lines:", len(new_lines))
