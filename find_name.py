with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "name'] ?? tags['name:el'] ?? " in line:
        print(f"{i}: {line.rstrip()}")
