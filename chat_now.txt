import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _hasApiKey = false;

  final List<String> _quickQuestions = [
    'Θα βρέξει σήμερα;',
    'Να βγω για περπάτημα;',
    'Καιρός για παραλία;',
    'Συνθήκες για σκι;',
    'Καλό για drone;',
    'Καλός για ψάρεμα;',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await _aiService.hasApiKey();
    setState(() => _hasApiKey = hasKey);
  }

  String get _weatherContext {
    final w = widget.weatherData;
    return _aiService.buildWeatherContext(
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
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text, 'type': 'text'});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.ask(_weatherContext, text);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response, 'type': 'text'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'type': 'text',
          'content': e.toString().contains('no_key')
              ? '⚙️ Δεν εχεις ρυθμισει API key.\n\nΠηγαινε στις ρυθμισεις (⚙️) και προσθεσε Gemini, Claude η ChatGPT key.'
              : '❌ Σφάλμα: ${e.toString().replaceAll("Exception: ", "")}',
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _takePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Χρειάζεται άδεια κάμερας.'), backgroundColor: Colors.orange));
        return;
      }
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo == null) return;

      setState(() {
        _messages.add({'role': 'user', 'content': photo.path, 'type': 'photo'});
        _isLoading = true;
      });
      _scrollToBottom();

      final file = File(photo.path);
      final response = await _aiService.analyzePhoto(_weatherContext, file);

      setState(() {
        _messages.add({'role': 'assistant', 'content': response, 'type': 'text'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'type': 'text',
          'content': e.toString().contains('no_key')
              ? '⚙️ Χρειαζεσαι API key για αναλυση φωτογραφιας.'
              : '❌ Σφάλμα: ${e.toString().replaceAll("Exception: ", "")}',
        });
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
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🤖 AI Μετεωρολόγος',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              final aiMessages = _messages.where((m) => m['role'] == 'assistant').toList();
              if (aiMessages.isEmpty) return;
              final last = aiMessages.last['content'] as String;
              SharePlus.instance.share(ShareParams(text: 'MetAIoSpot AI:\n$last'));
            },
            tooltip: 'Κοινοποίηση',
          ),
          if (_hasApiKey)
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              tooltip: 'Φωτογράφισε τον ουρανό',
              onPressed: _takePhoto,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_hasApiKey) _buildNoKeyBanner(),
            Expanded(child: _messages.isEmpty ? _buildWelcome() : _buildMessages()),
            _buildQuickQuestions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoKeyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withValues(alpha: 0.2),
      child: const Row(children: [
        Icon(Icons.warning_amber, color: Colors.orange, size: 16),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Δεν έχεις API key. Πήγαινε στις ⚙️ Ρυθμίσεις.',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ),
      ]),
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
            const Text('Ρώτα με για τον καιρό!',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            if (_hasApiKey) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.camera_alt, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Text('Πάτα 📷 για ανάλυση ουρανού',
                      style: TextStyle(color: Colors.blue, fontSize: 13)),
                ]),
              ),
            ],
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
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        if (msg['type'] == 'photo') return _buildPhotoMessage(msg['content'] as String);
        return _buildMessage(msg['content'] as String, isUser);
      },
    );
  }

  Widget _buildPhotoMessage(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(path), width: 200, height: 150, fit: BoxFit.cover),
                ),
                const SizedBox(height: 4),
                const Text('📷 Φωτογραφία ουρανού',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
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
      child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.blue, radius: 16,
            child: Text('🤖', style: TextStyle(fontSize: 14))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1A2744), borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            SizedBox(width: 40, child: LinearProgressIndicator(color: Colors.blue)),
            SizedBox(width: 8),
            Text('Αναλύω...', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ]),
        ),
      ]),
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
      child: Row(children: [
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
      ]),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
