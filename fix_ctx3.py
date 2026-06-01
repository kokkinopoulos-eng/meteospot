with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

dollar = chr(36)
lines[91] = f"          context += '\\n\\n{dollar}{{widget.weatherData.locationName}} - Kontines paralies (apostasi euthias grammes - lave ypopsi odiki prosvasi):\\n';\n"
lines[93] = f"            context += '- {dollar}{{b[\"name\"]}} ({dollar}{{b[\"distKm\"]}}km euthia)\\n';\n"

with open("C:/meteospot/lib/screens/chat_screen.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
print("91:", lines[91].rstrip())
print("93:", lines[93].rstrip())
