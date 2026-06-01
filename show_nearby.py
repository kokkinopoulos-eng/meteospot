import math

with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Show lines 376-390
for i, line in enumerate(lines[376:392], start=376):
    print(f"{i}: {line.rstrip()}")
