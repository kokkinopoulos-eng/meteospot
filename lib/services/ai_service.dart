import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AIProvider { gemini, claude, chatgpt, none }

class AIService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _geminiKeyName = 'gemini_api_key';
  static const String _claudeKeyName = 'claude_api_key';
  static const String _chatgptKeyName = 'chatgpt_api_key';
  static const String _providerKeyName = 'ai_provider';

  Future<void> saveApiKey(AIProvider provider, String key) async {
    String keyName;
    switch (provider) {
      case AIProvider.gemini: keyName = _geminiKeyName; break;
      case AIProvider.claude: keyName = _claudeKeyName; break;
      case AIProvider.chatgpt: keyName = _chatgptKeyName; break;
      default: return;
    }
    await _storage.write(key: keyName, value: key);
    await _storage.write(key: _providerKeyName, value: provider.name);
  }

  Future<String?> getApiKey(AIProvider provider) async {
    String keyName;
    switch (provider) {
      case AIProvider.gemini: keyName = _geminiKeyName; break;
      case AIProvider.claude: keyName = _claudeKeyName; break;
      case AIProvider.chatgpt: keyName = _chatgptKeyName; break;
      default: return null;
    }
    return await _storage.read(key: keyName);
  }

  Future<AIProvider> getCurrentProvider() async {
    final provider = await _storage.read(key: _providerKeyName);
    if (provider == AIProvider.gemini.name) return AIProvider.gemini;
    if (provider == AIProvider.claude.name) return AIProvider.claude;
    if (provider == AIProvider.chatgpt.name) return AIProvider.chatgpt;
    return AIProvider.none;
  }

  bool isWeatherRelated(String question) {
    final keywords = [
      'καιρός', 'βροχή', 'ήλιος', 'χιόνι', 'άνεμος', 'αέρας',
      'θερμοκρασία', 'υγρασία', 'πίεση', 'σύννεφα', 'ομίχλη',
      'καταιγίδα', 'ψάρεμα', 'περπάτημα', 'εκδρομή', 'μπάνιο',
      'weather', 'rain', 'snow', 'wind', 'temperature', 'cloud',
      'να βγω', 'να πάω', 'να οδηγήσω', 'ασφαλές', 'κρύο', 'ζέστη',
      'uv', 'ορατότητα', 'υψόμετρο', 'πρόβλεψη', 'forecast',
      'sunny', 'cloudy', 'storm', 'thunder', 'lightning', 'fog',
      'παγετός', 'πάγος', 'χαλάζι', 'μπόρα', 'ομπρέλα', 'αντιηλιακό',
      'σήμερα', 'αύριο', 'απόγευμα', 'πρωί', 'βράδυ', 'εβδομάδα',
      'today', 'tomorrow', 'morning', 'evening', 'weekend'
    ];
    return keywords.any((k) => question.toLowerCase().contains(k));
  }

  static const String _systemPrompt = '''Είσαι έμπειρος μετεωρολόγος που αναλύει τοπικές καιρικές συνθήκες.
Απαντάς ΜΟΝΟ σε ερωτήσεις σχετικές με καιρό και δραστηριότητες που επηρεάζονται από αυτόν.
Αν η ερώτηση είναι ΑΣΧΕΤΗ, απάντα: "🌤️ Μπορώ να απαντήσω μόνο σε ερωτήσεις σχετικές με τον καιρό!"
Δίνεις σύντομες, χρήσιμες απαντήσεις στα Ελληνικά.
Πάντα προσθέτεις: "⚠️ Για δραστηριότητες με κίνδυνο, συμβουλευτείτε ΕΜΥ."''';

  Future<String> askGemini(String apiKey, String weatherContext, String question) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'parts': [{'text': '$_systemPrompt\n\nΔεδομένα καιρού:\n$weatherContext\n\nΕρώτηση: $question'}]}
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 500}
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else if (response.statusCode == 400) {
      throw Exception('Λάθος API key.');
    } else if (response.statusCode == 429) {
      throw Exception('Έχεις ξεπεράσει το όριο.');
    } else {
      throw Exception('Σφάλμα Gemini: ${response.statusCode}');
    }
  }

  Future<String> askClaude(String apiKey, String weatherContext, String question) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5',
        'max_tokens': 500,
        'system': '$_systemPrompt\n\nΔεδομένα:\n$weatherContext',
        'messages': [{'role': 'user', 'content': question}],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } else if (response.statusCode == 401) {
      throw Exception('Λάθος API key.');
    } else {
      throw Exception('Σφάλμα: ${response.statusCode}');
    }
  }

  Future<String> askChatGPT(String apiKey, String weatherContext, String question) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'max_tokens': 500,
        'messages': [
          {'role': 'system', 'content': '$_systemPrompt\n\nΔεδομένα:\n$weatherContext'},
          {'role': 'user', 'content': question}
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else if (response.statusCode == 401) {
      throw Exception('Λάθος API key.');
    } else {
      throw Exception('Σφάλμα: ${response.statusCode}');
    }
  }

  Future<String> ask(String weatherContext, String question) async {
    if (!isWeatherRelated(question)) {
      return '🌤️ Μπορώ να απαντήσω μόνο σε ερωτήσεις σχετικές με τον καιρό!';
    }

    final provider = await getCurrentProvider();
    if (provider == AIProvider.none) throw Exception('no_key');

    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw Exception('no_key');

    if (provider == AIProvider.gemini) return await askGemini(apiKey, weatherContext, question);
    if (provider == AIProvider.claude) return await askClaude(apiKey, weatherContext, question);
    return await askChatGPT(apiKey, weatherContext, question);
  }

  String buildWeatherContext({
    required double temperature,
    required double feelsLike,
    required double humidity,
    required double windSpeed,
    required String windDirection,
    required double pressure,
    required double uvIndex,
    required double visibility,
    required String description,
    required double elevation,
    required double latitude,
    required double longitude,
  }) {
    return '''
📍 Τοποθεσία: $latitude, $longitude (${elevation.toInt()}m)
🌡️ Θερμοκρασία: ${temperature.toStringAsFixed(1)}°C (Αίσθηση: ${feelsLike.toStringAsFixed(1)}°C)
💧 Υγρασία: ${humidity.toInt()}%
🌬️ Άνεμος: ${windSpeed.toStringAsFixed(1)} km/h από $windDirection
🌡️ Πίεση: ${pressure.toStringAsFixed(0)} hPa
☀️ UV Index: ${uvIndex.toStringAsFixed(1)}
👁️ Ορατότητα: ${(visibility / 1000).toStringAsFixed(1)} km
⛅ Συνθήκες: $description
''';
  }
}
