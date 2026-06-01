with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[88:100], start=88):
    print(f"{i}: {line.rstrip()}")
