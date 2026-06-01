with open("C:/meteospot/lib/screens/settings_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Add import if missing
if "flutter_secure_storage" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:flutter_secure_storage/flutter_secure_storage.dart';\n",
        1
    )

# Add save logic for google key inside _saveSettings - save it always
content = content.replace(
    "      await _aiService.saveApiKey(_selectedProvider, key);\n",
    "      await _aiService.saveApiKey(_selectedProvider, key);\n      try { await _placesStorage.write(key: 'google_places_key', value: _googlePlacesController.text.trim()); } catch (_) {}\n",
    1
)

# Add the widget method before _buildSaveButton
widget_code = '''  Widget _buildGooglePlacesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('\\u{1F3D6}\\u{FE0F}', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Expanded(child: Text('Google Places (\\u03c0\\u03c1\\u03bf\\u03b1\\u03b9\\u03c1\\u03b5\\u03c4\\u03b9\\u03ba\\u03cc)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 8),
          const Text('\\u0392\\u03ac\\u03bb\\u03b5 \\u03b4\\u03b9\\u03ba\\u03cc \\u03c3\\u03bf\\u03c5 Google Places API key \\u03b3\\u03b9\\u03b1 \\u03ba\\u03b1\\u03bb\\u03cd\\u03c4\\u03b5\\u03c1\\u03b1 \\u03b1\\u03c0\\u03bf\\u03c4\\u03b5\\u03bb\\u03ad\\u03c3\\u03bc\\u03b1\\u03c4\\u03b1 \\u03c0\\u03b1\\u03c1\\u03b1\\u03bb\\u03b9\\u03ce\\u03bd (\\u03c3\\u03c9\\u03c3\\u03c4\\u03ac \\u03bf\\u03bd\\u03cc\\u03bc\\u03b1\\u03c4\\u03b1 + \\u03b1\\u03be\\u03b9\\u03bf\\u03bb\\u03bf\\u03b3\\u03ae\\u03c3\\u03b5\\u03b9\\u03c2). \\u03a7\\u03c9\\u03c1\\u03af\\u03c2 key, \\u03c7\\u03c1\\u03b7\\u03c3\\u03b9\\u03bc\\u03bf\\u03c0\\u03bf\\u03b9\\u03b5\\u03af\\u03c4\\u03b1\\u03b9 OpenStreetMap.',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _googlePlacesController,
            obscureText: !_showGooglePlacesKey,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Google Places API Key',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0D1B2A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(_showGooglePlacesKey ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                onPressed: () => setState(() => _showGooglePlacesKey = !_showGooglePlacesKey),
              ),
            ),
          ),
        ],
      ),
    );
  }

'''

content = content.replace("  Widget _buildSaveButton() {", widget_code + "  Widget _buildSaveButton() {", 1)

with open("C:/meteospot/lib/screens/settings_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
