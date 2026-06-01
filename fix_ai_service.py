with open('C:/meteospot/lib/services/ai_service.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_block = [
    "  String buildWeatherContext({\n",
    "    required double temperature, required double feelsLike,\n",
    "    required double humidity, required double windSpeed,\n",
    "    required String windDirection, required double pressure,\n",
    "    required double uvIndex, required double visibility,\n",
    "    required String description, required double elevation,\n",
    "    required double latitude, required double longitude,\n",
    "    String locationName = '',\n",
    "  }) {\n",
    "    final loc = locationName.isNotEmpty\n",
    "        ? locationName\n",
    "        : '\, \';\n",
    "    return '''\n",
    "📍 Τοποθεσία: \ (\m υψόμετρο)\n",
    "🌡️ Θερμοκρασία: \°C (Αίσθηση: \°C)\n",
    "💧 Υγρασία: \%\n",
    "🌬️ Άνεμος: \ km/h από \\n",
    "🌡️ Πίεση: \ hPa\n",
    "☀️ UV Index: \\n",
    "👁️ Ορατότητα: \ km\n",
    "⛅ Συνθήκες: \\n",
    "''';\n",
    "  }\n",
    "}\n",
]

start = 266
new_lines = lines[:start] + new_block

with open('C:/meteospot/lib/services/ai_service.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print('Done! Lines:', len(new_lines))
