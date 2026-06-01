with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "Kontines" in line or "\u03a0\u03b1\u03c1\u03b1\u03bb\u03af\u03b5\u03c2" in line:
        print(f"{i}: {line.rstrip()}")
