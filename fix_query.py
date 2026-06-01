with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

dollar = chr(36)
lines[385] = f"        '(node[\"natural\"=\"beach\"](around:{dollar}{{radiusKm * 1000}},{dollar}lat,{dollar}lon);'\n"
lines[386] = f"        'way[\"natural\"=\"beach\"](around:{dollar}{{radiusKm * 1000}},{dollar}lat,{dollar}lon);'\n"
lines.insert(387, f"        'node[\"leisure\"=\"beach_resort\"](around:{dollar}{{radiusKm * 1000}},{dollar}lat,{dollar}lon););'\n")
lines[388] = "        'out center 40;';\n"

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
for i, line in enumerate(lines[384:392], start=384):
    print(f"{i}: {line.rstrip()}")
