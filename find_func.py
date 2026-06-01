with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find findNearbyBeaches start
for i, line in enumerate(lines):
    if "static Future<List<Map<String, dynamic>>> findNearbyBeaches" in line:
        print(f"Found at line {i}")
        break
