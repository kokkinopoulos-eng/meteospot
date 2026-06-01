with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "beaches" in line or "beach" in line.lower():
        print(f"{i}: {line.rstrip()}")
