import re

with open("C:/meteospot/lib/screens/settings_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add controller + storage + show flag after chatgptController
content = content.replace(
    "  final _chatgptController = TextEditingController();\n",
    "  final _chatgptController = TextEditingController();\n  final _googlePlacesController = TextEditingController();\n  final _placesStorage = const FlutterSecureStorage();\n  bool _showGooglePlacesKey = false;\n",
    1
)

# 2. Load google key in _loadSettings
content = content.replace(
    "    final chatgptKey = await _aiService.getApiKey(AIProvider.chatgpt);\n",
    "    final chatgptKey = await _aiService.getApiKey(AIProvider.chatgpt);\n    String? googlePlacesKey;\n    try { googlePlacesKey = await _placesStorage.read(key: 'google_places_key'); } catch (_) {}\n",
    1
)
content = content.replace(
    "      if (chatgptKey != null) _chatgptController.text = chatgptKey;\n",
    "      if (chatgptKey != null) _chatgptController.text = chatgptKey;\n      if (googlePlacesKey != null) _googlePlacesController.text = googlePlacesKey;\n",
    1
)

# 3. Add card in build after save button
content = content.replace(
    "                    _buildSaveButton(),\n",
    "                    _buildSaveButton(),\n                    const SizedBox(height: 16),\n                    _buildGooglePlacesCard(),\n",
    1
)

# 4. Dispose
content = content.replace(
    "    _geminiController.dispose();\n",
    "    _geminiController.dispose();\n    _googlePlacesController.dispose();\n",
    1
)

with open("C:/meteospot/lib/screens/settings_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Done with 4 edits")
