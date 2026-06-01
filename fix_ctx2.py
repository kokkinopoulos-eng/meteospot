with open("C:/meteospot/lib/screens/chat_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

lines[91] = "          context += '\\n\\n" + "\u0392\u03c1\u03af\u03c3\u03ba\u03b5\u03c3\u03b1\u03b9 \u03c3\u03c4\u03bf: . \u039a\u03bf\u03bd\u03c4\u03b9\u03bd\u03ad\u03c2 \u03c0\u03b1\u03c1\u03b1\u03bb\u03af\u03b5\u03c2 (\u03b1\u03c0\u03cc\u03c3\u03c4\u03b1\u03c3\u03b7 \u03b5\u03c5\u03b8\u03b5\u03af\u03b1\u03c2 \u03b3\u03c1\u03b1\u03bc\u03bc\u03ae\u03c2 - \u03bb\u03ac\u03b2\u03b5 \u03c5\u03c0\u03cc\u03c8\u03b7 \u03bf\u03b4\u03b9\u03ba\u03ae \u03c0\u03c1\u03cc\u03c3\u03b2\u03b1\u03c3\u03b7):\\n';\n"
lines[93] = "            context += '-  (km \u03b5\u03c5\u03b8\u03b5\u03af\u03b1)\\n';\n"

with open("C:/meteospot/lib/screens/chat_screen.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
print("Line 91:", lines[91].rstrip())
print("Line 93:", lines[93].rstrip())
