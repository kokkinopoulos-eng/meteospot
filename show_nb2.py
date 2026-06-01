with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "static Future<List<Map<String, dynamic>>> findNearbyBeaches" in line:
        start = i
        break

for i, line in enumerate(lines[start:start+8], start=start):
    print(f"{i}: {line.rstrip()}")
