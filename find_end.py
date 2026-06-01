with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find the end of fallback list
for i, line in enumerate(lines):
    if "Ερμιόνη" in line:
        print(f"Found Ermioni at line {i}: {line.rstrip()}")
        break
