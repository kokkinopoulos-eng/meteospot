with open("C:/meteospot/lib/services/beach_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

evia_beaches = [
    "    // ΕΥΒΟΙΑ\n",
    "    {'name': 'Λευκαντί', 'lat': 38.4089, 'lon': 23.6711},\n",
    "    {'name': 'Χαλκίδα παραλία', 'lat': 38.4634, 'lon': 23.6012},\n",
    "    {'name': 'Ερέτρια παραλία', 'lat': 38.3934, 'lon': 23.7934},\n",
    "    {'name': 'Αμάρυνθος', 'lat': 38.3712, 'lon': 23.8534},\n",
    "    {'name': 'Αλιβέρι παραλία', 'lat': 38.3923, 'lon': 23.9712},\n",
    "    {'name': 'Κάρυστος', 'lat': 38.0134, 'lon': 24.4123},\n",
    "    {'name': 'Μαρμάρι Ευβοίας', 'lat': 38.0523, 'lon': 24.3234},\n",
    "    {'name': 'Στύρα', 'lat': 38.1534, 'lon': 24.2312},\n",
    "    {'name': 'Νέα Στύρα', 'lat': 38.1423, 'lon': 24.2134},\n",
    "    {'name': 'Αγία Τριάδα Ευβοίας', 'lat': 38.2012, 'lon': 24.1823},\n",
    "    {'name': 'Κύμη παραλία', 'lat': 38.6334, 'lon': 24.0923},\n",
    "    {'name': 'Χαλκίδα Νότια', 'lat': 38.4234, 'lon': 23.6234},\n",
    "    {'name': 'Βασιλικό Ευβοίας', 'lat': 38.4512, 'lon': 23.6523},\n",
    "    {'name': 'Φάρος Ευβοίας', 'lat': 38.4712, 'lon': 23.6812},\n",
    "    {'name': 'Αυλίδα', 'lat': 38.4023, 'lon': 23.5934},\n",
    "    {'name': 'Χαλκούτσι', 'lat': 38.3634, 'lon': 23.7423},\n",
    "    {'name': 'Βατώντας', 'lat': 38.3423, 'lon': 23.8123},\n",
    "    {'name': 'Δροσιά Ευβοίας', 'lat': 38.5234, 'lon': 23.7134},\n",
    "    {'name': 'Λίμνη Ευβοίας', 'lat': 38.7823, 'lon': 23.3012},\n",
    "    {'name': 'Ιστιαία παραλία', 'lat': 38.9234, 'lon': 23.1123},\n",
    "    {'name': 'Αιδηψός παραλία', 'lat': 38.8623, 'lon': 23.0434},\n",
    "    {'name': 'Γιάλτρα', 'lat': 38.8312, 'lon': 23.1534},\n",
    "    {'name': 'Ωρεοί', 'lat': 38.9712, 'lon': 23.0823},\n",
]

new_lines = lines[:340] + evia_beaches + lines[340:]

with open("C:/meteospot/lib/services/beach_service.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Done! Added", len(evia_beaches)-1, "Evia beaches")
print("Total lines:", len(new_lines))
