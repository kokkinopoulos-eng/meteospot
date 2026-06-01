with open("C:/meteospot/lib/screens/settings_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[105:120], start=105):
    print(f"{i}: {line.rstrip()}")
