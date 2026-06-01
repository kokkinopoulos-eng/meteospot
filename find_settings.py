with open("C:/meteospot/lib/screens/settings_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find _loadSettings to add google key loading, and the build area
for i, line in enumerate(lines):
    if "_buildAdvancedInfo" in line or "_buildLegalCard" in line or "_buildSaveButton" in line or "buildActiveProviderCard" in line:
        print(f"{i}: {line.rstrip()}")
print("Total:", len(lines))
