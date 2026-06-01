with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
for i, line in enumerate(lines[420:476], start=420):
    print(f"{i}: {line.rstrip()}")
