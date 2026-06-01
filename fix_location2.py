with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

lines[91] = "          context += '\\n\\nBriskesei sto: \.\\nKontines paralies (50km):\\n';\n"

with open("C:/meteospot/lib/screens/chat_screen.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
print("New:", lines[91].rstrip())
