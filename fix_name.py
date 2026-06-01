with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

lines[405] = "            final name = tags['name'] ?? tags['name:el'] ?? tags['name:en'];\n"
lines[406] = "            if (name == null) continue;\n"

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
