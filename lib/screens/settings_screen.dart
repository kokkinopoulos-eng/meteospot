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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Διάλεξε ένα AI Provider'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    String key = '';
    if (_selectedProvider == AIProvider.gemini) key = _geminiController.text.trim();
    if (_selectedProvider == AIProvider.claude) key = _claudeController.text.trim();
    if (_selectedProvider == AIProvider.chatgpt) key = _chatgptController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Βάλε API key για τον επιλεγμένο provider'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    try {
      await _aiService.saveApiKey(_selectedProvider, key);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Σφαλμα: $e'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Ρυθμίσεις αποθηκεύτηκαν!'),
        backgroundColor: Colors.green,
      ));
      // Navigator.pop removed - settings is now a tab
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                    _buildActiveProviderCard(),
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
            Text('AI Μετεωρολόγος',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          SizedBox(height: 8),
          Text(
            'Χρησιμοποίησε το δικό σου AI API key για έξυπνη ανάλυση καιρού, απαντήσεις σε ερωτήσεις και ανάλυση φωτογραφιών ουρανού. Το key αποθηκεύεται κρυπτογραφημένα ΜΟΝΟ στη συσκευή σου.',
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
          border: Border.all(color: isSelected ? Colors.blue : Colors.white24, width: isSelected ? 2 : 1),
        ),
        child: Column(children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildActiveProviderCard() {
    if (_selectedProvider == AIProvider.none) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2744),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Text('👆 Επέλεξε έναν AI Provider παραπάνω',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ),
      );
    }
    if (_selectedProvider == AIProvider.gemini) return _buildGeminiCard();
    if (_selectedProvider == AIProvider.claude) return _buildClaudeCard();
    return _buildChatGPTCard();
  }

  Widget _buildGeminiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🟨', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Google Gemini',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
              child: const Text('ΔΩΡΕΑΝ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoRow('💰', 'Κόστος', 'Δωρεάν με Google account'),
          _buildInfoRow('⚡', 'Όριο', '15 ερωτήσεις/λεπτό'),
          _buildInfoRow('📷', 'Φωτογραφίες', 'Υποστηρίζει ανάλυση ουρανού'),
          _buildInfoRow('🌍', 'Γλώσσες', 'Ελληνικά & Αγγλικά'),
          const SizedBox(height: 12),
          const Text('📋 Πώς να πάρεις key:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          _buildStep('1', 'Πήγαινε στο aistudio.google.com'),
          _buildStep('2', 'Σύνδεσε το Google account σου'),
          _buildStep('3', 'Πάτα "Get API Key" → "Create API Key"'),
          _buildStep('4', 'Αντίγραψε το key και επικόλλησέ το παρακάτω'),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _launchUrl('https://aistudio.google.com/apikey'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.open_in_new, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('Άνοιξε το Google AI Studio',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _geminiController,
            obscureText: !_showGeminiKey,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              hintStyle: const TextStyle(color: Colors.white38),
              labelText: 'Gemini API Key',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(_showGeminiKey ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                onPressed: () => setState(() => _showGeminiKey = !_showGeminiKey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaudeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🟦', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Anthropic Claude',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(width: 8),
            Chip(
              label: Text('Paid', style: TextStyle(color: Colors.white, fontSize: 11)),
              backgroundColor: Colors.orange,
              padding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoRow('💰', 'Κόστος', '~\$0.001 ανά ερώτηση (claude-haiku)'),
          _buildInfoRow('🎁', 'Νέοι χρήστες', '\$5 δωρεάν credits'),
          _buildInfoRow('⭐', 'Ποιότητα', 'Εξαιρετική κατανόηση'),
          _buildInfoRow('📷', 'Φωτογραφίες', 'Υποστηρίζει ανάλυση ουρανού'),
          const SizedBox(height: 12),
          const Text('📋 Πώς να πάρεις key:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          _buildStep('1', 'Πήγαινε στο console.anthropic.com'),
          _buildStep('2', 'Δημιούργησε λογαριασμό'),
          _buildStep('3', 'Settings → API Keys → Create Key'),
          _buildStep('4', 'Αντίγραψε το key και επικόλλησέ το παρακάτω'),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _launchUrl('https://console.anthropic.com'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.open_in_new, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Text('Άνοιξε το Anthropic Console',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ]),
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
              labelText: 'Claude API Key',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(_showClaudeKey ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
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
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🟩', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('OpenAI ChatGPT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(width: 8),
            Chip(
              label: Text('Paid', style: TextStyle(color: Colors.white, fontSize: 11)),
              backgroundColor: Colors.orange,
              padding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoRow('💰', 'Κόστος', '~\$0.0002 ανά ερώτηση (gpt-4o-mini)'),
          _buildInfoRow('🎁', 'Νέοι χρήστες', '\$5 δωρεάν credits'),
          _buildInfoRow('⚡', 'Ταχύτητα', 'Πολύ γρήγορο'),
          _buildInfoRow('📷', 'Φωτογραφίες', 'Υποστηρίζει ανάλυση ουρανού'),
          const SizedBox(height: 12),
          const Text('📋 Πώς να πάρεις key:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          _buildStep('1', 'Πήγαινε στο platform.openai.com'),
          _buildStep('2', 'Δημιούργησε λογαριασμό'),
          _buildStep('3', 'API Keys → Create new secret key'),
          _buildStep('4', 'Αντίγραψε το key και επικόλλησέ το παρακάτω'),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _launchUrl('https://platform.openai.com/api-keys'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.open_in_new, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('Άνοιξε το OpenAI Platform',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
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
              labelText: 'ChatGPT API Key',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(_showChatGPTKey ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                onPressed: () => setState(() => _showChatGPTKey = !_showChatGPTKey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ]),
    );
  }

  Widget _buildStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
      ]),
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
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚖️ Νομική Σημείωση',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text(
            'Gemini® είναι εμπορικό σήμα της Google LLC. Claude® είναι εμπορικό σήμα της Anthropic PBC. ChatGPT® και GPT® είναι εμπορικά σήματα της OpenAI. Το MetAIoSpot δεν συνδέεται, δεν χρηματοδοτείται ούτε εγκρίνεται από αυτές τις εταιρείες.\n\nΟι χρεώσεις API είναι αποκλειστικά ευθύνη σου. Συμμορφώνεσαι με τους όρους χρήσης του κάθε provider. Τα API keys αποθηκεύονται κρυπτογραφημένα μόνο τοπικά στη συσκευή σου και δεν αποστέλλονται σε servers του MetAIoSpot.',
            style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.5),
          ),
        ],
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
