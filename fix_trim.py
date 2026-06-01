with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Keep only up to line 424 (the closing of findNearbyBeaches) + closing }
new_lines = lines[:424] + ["}\n"]

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! Total lines:", len(new_lines))
