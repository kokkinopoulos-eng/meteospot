with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[85:100], start=85):
    print(f"{i}: {line.rstrip()}")
