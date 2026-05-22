import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AIService _aiService = AIService();
  final _claudeController = TextEditingController();
  final _chatgptController = TextEditingController();
  AIProvider _selectedProvider = AIProvider.none;
  bool _isLoading = true;
  bool _showClaudeKey = false;
  bool _showChatGPTKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = await _aiService.getCurrentProvider();
    final claudeKey = await _aiService.getApiKey(AIProvider.claude);
    final chatgptKey = await _aiService.getApiKey(AIProvider.chatgpt);
    setState(() {
      _selectedProvider = provider;
      if (claudeKey != null) _claudeController.text = claudeKey;
      if (chatgptKey != null) _chatgptController.text = chatgptKey;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_claudeController.text.isNotEmpty) {
      await _aiService.saveApiKey(AIProvider.claude, _claudeController.text.trim());
    }
    if (_chatgptController.text.isNotEmpty) {
      await _aiService.saveApiKey(AIProvider.chatgpt, _chatgptController.text.trim());
    }
    if (_selectedProvider != AIProvider.none) {
      await _aiService.saveApiKey(_selectedProvider, 
        _selectedProvider == AIProvider.claude 
          ? _claudeController.text.trim() 
          : _chatgptController.text.trim());
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '⚙️ Ρυθμίσεις AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
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
                  _buildClaudeCard(),
                  const SizedBox(height: 16),
                  _buildChatGPTCard(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
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
            'Βάλε το δικό σου API key για να χρησιμοποιήσεις AI ανάλυση καιρού. '
            'Το key αποθηκεύεται κρυπτογραφημένα μόνο στη συσκευή σου.',
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
          Row(
            children: [
              Expanded(
                child: _buildProviderButton(
                  '🟦 Claude',
                  'Anthropic',
                  AIProvider.claude,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProviderButton(
                  '🟩 ChatGPT',
                  'OpenAI',
                  AIProvider.chatgpt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderButton(String name, String company, AIProvider provider) {
    final isSelected = _selectedProvider == provider;
    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(company, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildClaudeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🟦', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Claude API Key',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _launchUrl('https://console.anthropic.com'),
            child: const Text(
              '📎 Πάρε key από console.anthropic.com',
              style: TextStyle(color: Colors.blue, fontSize: 13, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _claudeController,
            obscureText: !_showClaudeKey,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'sk-ant-...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(_showClaudeKey ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54),
                onPressed: () => setState(() => _showClaudeKey = !_showClaudeKey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatGPTCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🟩', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('ChatGPT API Key',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _launchUrl('https://platform.openai.com/api-keys'),
            child: const Text(
              '📎 Πάρε key από platform.openai.com',
              style: TextStyle(color: Colors.blue, fontSize: 13, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chatgptController,
            obscureText: !_showChatGPTKey,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'sk-...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(_showChatGPTKey ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54),
                onPressed: () => setState(() => _showChatGPTKey = !_showChatGPTKey),
              ),
            ),
          ),
        ],
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
        child: const Text(
          'Αποθήκευση',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _launchUrl(String url) {
    // TODO: implement url launcher
  }

  @override
  void dispose() {
    _claudeController.dispose();
    _chatgptController.dispose();
    super.dispose();
  }
}