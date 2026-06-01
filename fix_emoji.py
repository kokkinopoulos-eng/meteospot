with open("C:/meteospot/lib/models/weather_data.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find weatherEmoji getter
start = None
end = None
for i, line in enumerate(lines):
    if "String get weatherEmoji" in line:
        start = i
    if start and i > start and line.strip() == "}":
        end = i
        break

new_block = [
    "  String get weatherEmoji {\n",
    "    if (windSpeed > 60) return '\U0001F32A\uFE0F';\n",
    "    if (windSpeed > 40) return '\U0001F4A8';\n",
    "    if (temperature > 38) return '\U0001F975';\n",
    "    if (weatherCode == 0 && temperature > 30) return '\U0001F31E';\n",
    "    if (weatherCode == 0) return '\u2600\uFE0F';\n",
    "    if (weatherCode <= 3) return '\u26C5';\n",
    "    if (weatherCode <= 48) return '\U0001F32B\uFE0F';\n",
    "    if (weatherCode <= 57) return '\U0001F326\uFE0F';\n",
    "    if (weatherCode <= 67) return '\U0001F327\uFE0F';\n",
    "    if (weatherCode <= 77) return '\u2744\uFE0F';\n",
    "    if (weatherCode <= 82) return '\U0001F327\uFE0F';\n",
    "    if (weatherCode <= 99) return '\u26C8\uFE0F';\n",
    "    return '\U0001F321\uFE0F';\n",
    "  }\n",
]

new_lines = lines[:start] + new_block + lines[end+1:]

with open("C:/meteospot/lib/models/weather_data.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! start=%d end=%d" % (start, end))
