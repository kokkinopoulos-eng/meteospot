with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

print(f"Total: {len(lines)}")
for i, line in enumerate(lines[-10:], start=len(lines)-10):
    print(f"{i}: {line.rstrip()}")
