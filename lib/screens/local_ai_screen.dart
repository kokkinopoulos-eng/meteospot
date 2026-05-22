import 'package:flutter/material.dart';
import '../services/local_ai_service.dart';
import '../models/weather_data.dart';
import '../services/ai_service.dart';

class LocalAIScreen extends StatefulWidget {
  final WeatherData weatherData;
  const LocalAIScreen({super.key, required this.weatherData});

  @override
  State<LocalAIScreen> createState() => _LocalAIScreenState();
}

class _LocalAIScreenState extends State<LocalAIScreen> {
  final LocalAIService _localAI = LocalAIService();
  final AIService _aiService = AIService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isModelDownloaded = false;
  bool _isDownloading = false;
  bool _isInitializing = false;
  double _downloadProgress = 0.0;

  final List<String> _quickQuestions = [
    'Να βγω για περπάτημα;',
    'Θα βρέξει σήμερα;',
    'Πόσο κρύο είναι;',
    'Καλός για ψάρεμα;',
  ];

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    final downloaded = await _localAI.isModelDownloaded();
    setState(() => _isModelDownloaded = downloaded);
  }

  Future<void> _downloadModel() async {
    setState(() => _isDownloading = true);
    await _localAI.downloadModel(
      onProgress: (progress) => setState(() => _downloadProgress = progress),
      onComplete: () => setState(() {
        _isDownloading = false;
        _isModelDownloaded = true;
      }),
      onError: (error) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Σφάλμα: $error'), backgroundColor: Colors.red),
        );
      },
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      if (!_localAI.isInitialized) {
        setState(() => _isInitializing = true);
        await _localAI.initialize();
        setState(() => _isInitializing = false);
      }

      final w = widget.weatherData;
      final context = _aiService.buildWeatherContext(
        temperature: w.temperature,
        feelsLike: w.feelsLike,
        humidity: w.humidity,
        windSpeed: w.windSpeed,
        windDirection: w.windDirectionText,
        pressure: w.pressure,
        uvIndex: w.uvIndex,
        visibility: w.visibility,
        description: w.description,
        elevation: w.elevation,
        latitude: w.latitude,
        longitude: w.longitude,
      );

      final response = await _localAI.ask(context, text);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Σφάλμα: ${e.toString()}'});
        _isLoading = false;
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🤖 Local AI (Offline)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !_isModelDownloaded ? _buildDownloadScreen() : _buildChatScreen(),
    );
  }

  Widget _buildDownloadScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          const Text('Local AI Model',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Δουλεύει χωρίς internet!\n⚠️ Μέγεθος: ~1.5GB - Συνιστάται WiFi',
              style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          if (_isDownloading) ...[
            LinearProgressIndicator(value: _downloadProgress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
            const SizedBox(height: 8),
            Text('${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70)),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadModel,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Κατέβασμα Μοντέλου',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        if (_isInitializing)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.withValues(alpha: 0.2),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
              SizedBox(width: 8),
              Text('Φόρτωση μοντέλου...', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('🤖', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('Local AI έτοιμο!',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Δουλεύει χωρίς internet.\nΡώτα με για τον καιρό!',
                      style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          CircleAvatar(backgroundColor: Colors.green, radius: 16,
                              child: Text('🤖', style: TextStyle(fontSize: 14))),
                          SizedBox(width: 8),
                          Text('Σκέφτομαι...', style: TextStyle(color: Colors.white54)),
                        ]),
                      );
                    }
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            const CircleAvatar(backgroundColor: Colors.green, radius: 16,
                                child: Text('🤖', style: TextStyle(fontSize: 14))),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.blue : const Color(0xFF1A2744),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(msg['content']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickQuestions.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _sendMessage(_quickQuestions[index]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2744),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(_quickQuestions[index],
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0D1B2A),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ρώτα offline...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1A2744),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendMessage(_controller.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _localAI.dispose();
    super.dispose();
  }
}
