with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

loc_name = "widget.weatherData.locationName"
lines[91] = "          context += '\\n\\n" + chr(0x03A4)+ chr(0x03BF) + chr(0x03C0) + chr(0x03BF) + chr(0x03B8) + chr(0x03B5) + chr(0x03C3) + chr(0x03AF) + chr(0x03B1) + " " + chr(0x03C7) + chr(0x03C1) + chr(0x03AE) + chr(0x03C3) + chr(0x03C4) + chr(0x03B7): .\\n" + chr(0x039A) + chr(0x03BF) + chr(0x03BD) + chr(0x03C4) + chr(0x03B9) + chr(0x03BD) + chr(0x03AD) + chr(0x03C2) + " " + chr(0x03C0) + chr(0x03B1) + chr(0x03C1) + chr(0x03B1) + chr(0x03BB) + chr(0x03AF) + chr(0x03B5) + chr(0x03C2) + " (50km):\\n';\n"

with open("C:/meteospot/lib/screens/chat_screen.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
print("New line 91:", lines[91].rstrip())
