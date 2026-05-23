import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AIService _aiService = AIService();
  final _geminiController = TextEditingController();
  final _claudeController = TextEditingController();
  final _chatgptController = TextEditingController();
  AIProvider _selectedProvider = AIProvider.none;
  bool _isLoading = true;
  bool _showGeminiKey = false;
  bool _showClaudeKey = false;
  bool _showChatGPTKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = await _aiService.getCurrentProvider();
    final geminiKey = await _aiService.getApiKey(AIProvider.gemini);
    final claudeKey = await _aiService.getApiKey(AIProvider.claude);
    final chatgptKey = await _aiService.getApiKey(AIProvider.chatgpt);
    setState(() {
      _selectedProvider = provider;
      if (geminiKey != null) _geminiController.text = geminiKey;
      if (claudeKey != null) _claudeController.text = claudeKey;
      if (chatgptKey != null) _chatgptController.text = chatgptKey;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_selectedProvider == AIProvider.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Διάλεξε ένα AI Provider'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String key = '';
    if (_selectedProvider == AIProvider.gemini) key = _geminiController.text.trim();
    if (_selectedProvider == AIProvider.claude) key = _claudeController.text.trim();
    if (_selectedProvider == AIProvider.chatgpt) key = _chatgptController.text.trim();

    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Βάλε API key για τον επιλεγμένο provider'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _aiService.saveApiKey(_selectedProvider, key);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ρυθμίσεις αποθηκεύτηκαν!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Δεν μπορώ να ανοίξω: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('⚙️ Ρυθμίσεις AI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildProviderSelector(),
                    const SizedBox(height: 16),
                    _buildGeminiCard(),
                    const SizedBox(height: 16),
                    _buildClaudeCard(),
                    const SizedBox(height: 16),
                    _buildChatGPTCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                    _buildDisclaimer(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('ℹ️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Πώς λειτουργεί;',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          SizedBox(height: 8),
          Text(
            'Διάλεξε έναν AI provider. Το Gemini είναι ΔΩΡΕΑΝ με Google account. Το key αποθηκεύεται κρυπτογραφημένα στη συσκευή.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Επέλεξε AI Provider:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildProviderButton('🟨 Gemini', 'FREE', AIProvider.gemini, isFree: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildProviderButton('🟦 Claude', 'Paid', AIProvider.claude)),
            const SizedBox(width: 8),
            Expanded(child: _buildProviderButton('🟩 GPT', 'Paid', AIProvider.chatgpt)),
          ]),
        ],
      ),
    );
  }

  Widget _buildProviderButton(String name, String badge, AIProvider provider, {bool isFree = false}) {
    final isSelected = _selectedProvider == provider;
    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isFree ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  Widget _buildGeminiCard() {
    final isActive = _selectedProvider == AIProvider.gemini;
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2744),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? Colors.green : Colors.transparent, width: isActive ? 2 : 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🟨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Google Gemini API Key',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: const Text('FREE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            InkWell(
              onTap: isActive ? () => _launchUrl('https://aistudio.google.com/apikey') : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('📎 Πάρε ΔΩΡΕΑΝ key από aistudio.google.com',
                    style: TextStyle(color: Colors.green, fontSize: 13, decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 4),
            const Text('💡 Χρειάζεται μόνο Google account',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: _geminiController,
              enabled: isActive,
              obscureText: !_showGeminiKey,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'AIza...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_showGeminiKey ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                  onPressed: isActive ? () => setState(() => _showGeminiKey = !_showGeminiKey) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaudeCard() {
    final isActive = _selectedProvider == AIProvider.claude;
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2744),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? Colors.blue : Colors.transparent, width: isActive ? 2 : 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Text('🟦', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Anthropic Claude API Key',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            InkWell(
              onTap: isActive ? () => _launchUrl('https://console.anthropic.com') : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('📎 Πάρε key από console.anthropic.com',
                    style: TextStyle(color: Colors.blue, fontSize: 13, decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _claudeController,
              enabled: isActive,
              obscureText: !_showClaudeKey,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_showClaudeKey ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                  onPressed: isActive ? () => setState(() => _showClaudeKey = !_showClaudeKey) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatGPTCard() {
    final isActive = _selectedProvider == AIProvider.chatgpt;
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2744),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? Colors.green : Colors.transparent, width: isActive ? 2 : 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Text('🟩', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('OpenAI ChatGPT API Key',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            InkWell(
              onTap: isActive ? () => _launchUrl('https://platform.openai.com/api-keys') : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('📎 Πάρε key από platform.openai.com',
                    style: TextStyle(color: Colors.blue, fontSize: 13, decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chatgptController,
              enabled: isActive,
              obscureText: !_showChatGPTKey,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'sk-...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_showChatGPTKey ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                  onPressed: isActive ? () => setState(() => _showChatGPTKey = !_showChatGPTKey) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Αποθήκευση',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Trademarks: Claude® is a trademark of Anthropic. ChatGPT® is a trademark of OpenAI. Gemini® is a trademark of Google. MetAIoSpot is not affiliated with, sponsored by, or endorsed by these companies. You are responsible for all API costs and compliance with each provider\'s terms of service.',
        style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.4),
      ),
    );
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _claudeController.dispose();
    _chatgptController.dispose();
    super.dispose();
  }
}
