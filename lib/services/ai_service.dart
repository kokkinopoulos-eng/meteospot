import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AIProvider { claude, chatgpt, none }

class AIService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _claudeKeyName = 'claude_api_key';
  static const String _chatgptKeyName = 'chatgpt_api_key';
  static const String _providerKeyName = 'ai_provider';

  Future<void> saveApiKey(AIProvider provider, String key) async {
    final keyName = provider == AIProvider.claude ? _claudeKeyName : _chatgptKeyName;
    await _storage.write(key: keyName, value: key);
    await _storage.write(key: _providerKeyName, value: provider.name);
  }

  Future<String?> getApiKey(AIProvider provider) async {
    final keyName = provider == AIProvider.claude ? _claudeKeyName : _chatgptKeyName;
    return await _storage.read(key: keyName);
  }

  Future<AIProvider> getCurrentProvider() async {
    final provider = await _storage.read(key: _providerKeyName);
    if (provider == AIProvider.claude.name) return AIProvider.claude;
    if (provider == AIProvider.chatgpt.name) return AIProvider.chatgpt;
    return AIProvider.none;
  }

  Future<void> deleteApiKey(AIProvider provider) async {
    final keyName = provider == AIProvider.claude ? _claudeKeyName : _chatgptKeyName;
    await _storage.delete(key: keyName);
  }

  // Keyword filter - ΠΡΙΝ το API call
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
Απαντάς ΜΟΝΟ σε ερωτήσεις που σχετίζονται με:
- Καιρό, κλίμα, ατμοσφαιρικά φαινόμενα
- Δραστηριότητες που επηρεάζονται από τον καιρό (ψάρεμα, περπάτημα, οδήγηση κλπ)

Αν η ερώτηση είναι ΑΣΧΕΤΗ με καιρό, απάντα ΜΟΝΟ:
"🌤️ Μπορώ να απαντήσω μόνο σε ερωτήσεις σχετικές με τον καιρό!"

ΠΟΤΕ μην απαντάς σε:
- Πολιτικά, θρησκευτικά, προσωπικά θέματα
- Ιατρικές συμβουλές
- Οτιδήποτε άσχετο με μετεωρολογία

Δίνεις σύντομες, χρήσιμες απαντήσεις στα Ελληνικά.
Πάντα προσθέτεις: "⚠️ Για δραστηριότητες με κίνδυνο, συμβουλευτείτε ΕΜΥ."''';

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
        'system': '$_systemPrompt\n\nΤα δεδομένα καιρού:\n$weatherContext',
        'messages': [
          {'role': 'user', 'content': question}
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } else if (response.statusCode == 401) {
      throw Exception('Λάθος API key. Έλεγξε τις ρυθμίσεις.');
    } else if (response.statusCode == 429) {
      throw Exception('Έχεις ξεπεράσει το όριο χρήσης. Δοκίμασε αργότερα.');
    } else {
      throw Exception('Σφάλμα Claude API: ${response.statusCode}');
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
          {
            'role': 'system',
            'content': '$_systemPrompt\n\nΤα δεδομένα καιρού:\n$weatherContext'
          },
          {'role': 'user', 'content': question}
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else if (response.statusCode == 401) {
      throw Exception('Λάθος API key. Έλεγξε τις ρυθμίσεις.');
    } else if (response.statusCode == 429) {
      throw Exception('Έχεις ξεπεράσει το όριο χρήσης. Δοκίμασε αργότερα.');
    } else {
      throw Exception('Σφάλμα ChatGPT API: ${response.statusCode}');
    }
  }

  Future<String> ask(String weatherContext, String question) async {
    // Layer 1: Client-side keyword filter
    if (!isWeatherRelated(question)) {
      return '🌤️ Μπορώ να απαντήσω μόνο σε ερωτήσεις σχετικές με τον καιρό!';
    }

    final provider = await getCurrentProvider();
    if (provider == AIProvider.none) {
      throw Exception('no_key');
    }

    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('no_key');
    }

    if (provider == AIProvider.claude) {
      return await askClaude(apiKey, weatherContext, question);
    } else {
      return await askChatGPT(apiKey, weatherContext, question);
    }
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
📍 Τοποθεσία: $latitude, $longitude (${elevation.toInt()}m υψόμετρο)
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
