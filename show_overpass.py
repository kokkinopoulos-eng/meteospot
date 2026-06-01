with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Replace the Overpass return to also verify with OSRM
old_lines = lines[399:413]
for i, l in enumerate(old_lines, start=399):
    print(f"{i}: {l.rstrip()}")
