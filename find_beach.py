with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find the beach context line
for i, line in enumerate(lines):
    if "context += '\\n\\nKontines" in line or "Κοντινές παραλίες" in line:
        print(f"Found at line {i}: {line.strip()}")
        break

print("Total lines:", len(lines))
