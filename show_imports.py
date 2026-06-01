with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[:15], start=0):
    print(f"{i}: {line.rstrip()}")
