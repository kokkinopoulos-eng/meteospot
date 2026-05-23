import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/weather_data.dart';

class ChatScreen extends StatefulWidget {
  final WeatherData weatherData;
  const ChatScreen({super.key, required this.weatherData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<String> _quickQuestions = [
    'Να βγω για περπάτημα;',
    'Θα βρέξει σήμερα;',
    'Πόσο κρύο είναι;',
    'Καλός για ψάρεμα;',
    'Πότε θα βελτιωθεί;',
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
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

      final response = await _aiService.ask(context, text);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('no_key')) {
          _messages.add({'role': 'assistant', 'content': '⚙️ Δεν έχεις ρυθμίσει API key.\n\nΠήγαινε στις Ρυθμίσεις (⚙️) και πρόσθεσε Claude ή ChatGPT API key.'});
        } else {
          _messages.add({'role': 'assistant', 'content': '❌ Σφάλμα: ${e.toString().replaceAll("Exception: ", "")}'});
        }
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🤖 Ρώτα τον AI Μετεωρολόγο',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty ? _buildWelcome() : _buildMessages(),
            ),
            _buildQuickQuestions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    final w = widget.weatherData;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(w.weatherEmoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('${w.temperature.toStringAsFixed(1)}°C - ${w.description}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ρώτα με οτιδήποτε για τον καιρό\nστην τοποθεσία σου!',
                style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingIndicator();
        final message = _messages[index];
        final isUser = message['role'] == 'user';
        return _buildMessage(message['content']!, isUser);
      },
    );
  }

  Widget _buildMessage(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(backgroundColor: Colors.blue, radius: 16,
                child: Text('🤖', style: TextStyle(fontSize: 14))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : const Color(0xFF1A2744),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(content,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.blue, radius: 16,
              child: Text('🤖', style: TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [
              SizedBox(width: 40, child: LinearProgressIndicator(color: Colors.blue)),
              SizedBox(width: 8),
              Text('Σκέφτομαι...', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        itemCount: _quickQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(_quickQuestions[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(_quickQuestions[index],
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0D1B2A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ρώτα για τον καιρό...',
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
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
