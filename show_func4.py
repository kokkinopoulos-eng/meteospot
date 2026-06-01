with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[380:426], start=380):
    print(f"{i}: {line.rstrip()}")
