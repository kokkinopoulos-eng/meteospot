with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

lines[431] = "      if (roadDist != null && roadDist <= radiusKm * 2) {\n"

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
