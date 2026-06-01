with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find start and end of function
start = None
end = None
for i, line in enumerate(lines):
    if "static Future<List<Map<String, dynamic>>> findNearbyBeaches" in line:
        start = i
    if start and i > start + 5 and line.strip() == "}" and lines[i+1].strip() == "}":
        end = i
        break

print(f"Function: lines {start} to {end}")
