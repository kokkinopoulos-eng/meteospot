with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[384:395], start=384):
    print(f"{i}: {line.rstrip()}")
