with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "findNearbyBeaches" in line or "_distance" in line or "radiusDeg" in line or "nearby" in line:
        print(f"{i}: {line.rstrip()}")
