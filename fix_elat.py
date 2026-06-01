with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

lines[406] = "            if (name == null) continue;\n"
lines.insert(407, "            final eLat = (e['lat'] ?? e['center']?['lat']) as num?;\n")

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
