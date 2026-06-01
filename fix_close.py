with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

lines[423] = "    return [];\n"
lines[424] = "  }\n"
lines.append("}\n")

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
