with open("C:/meteospot/lib/screens/settings_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "api_key" in line.lower() or "_storage" in line or "provider" in line.lower() or "gemini" in line.lower():
        print(f"{i}: {line.rstrip()}")
