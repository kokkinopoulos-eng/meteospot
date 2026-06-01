with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[366:415], start=366):
    print(f"{i}: {line.rstrip()}")
