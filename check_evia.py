with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    content = f.read()

import re
beaches = re.findall(r"\{'name': '([^']+)', 'lat': ([\d.]+), 'lon': ([\d.]+)\}", content)

# Evia is roughly lat 38.0-39.0, lon 23.0-24.5
evia = [(n,la,lo) for n,la,lo in beaches if 38.0 <= float(la) <= 39.0 and 23.0 <= float(lo) <= 24.5]
print(f"Evia beaches: {len(evia)}")
for b in evia:
    print(b)

# Also check Attika (lat 37.5-38.3, lon 23.5-24.2) - these are the problem
attika = [(n,la,lo) for n,la,lo in beaches if 37.5 <= float(la) <= 38.3 and 23.5 <= float(lo) <= 24.2]
print(f"\nAttika beaches: {len(attika)}")
for b in attika:
    print(b)
