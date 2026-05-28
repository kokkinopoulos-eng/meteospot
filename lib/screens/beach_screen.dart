import 'package:flutter/material.dart';
import '../services/beach_service.dart';
import '../services/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BeachScreen extends StatefulWidget {
  const BeachScreen({super.key});

  @override
  State<BeachScreen> createState() => _BeachScreenState();
}

class _BeachScreenState extends State<BeachScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AIService _aiService = AIService();

  BeachData? _beachData;
  bool _isLoading = false;
  String? _errorMessage;
  String? _aiAnalysis;
  bool _aiLoading = false;

  Future<void> _searchBeach(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = null; _beachData = null; _aiAnalysis = null; });

    // Geocode
    final geo = await BeachService.geocodePlace(query);
    if (geo == null) {
      setState(() { _isLoading = false; _errorMessage = 'Ξ”ΞµΞ½ Ξ²ΟΞ­ΞΈΞ·ΞΊΞµ Ξ· Ο„ΞΏΟ€ΞΏΞΈΞµΟƒΞ―Ξ±. Ξ”ΞΏΞΊΞ―ΞΌΞ±ΟƒΞµ Ξ»ΞΉΞ³ΟΟ„ΞµΟΞΏ Ξ³ΞµΞ½ΞΉΞΊΞ¬.'; });
      return;
    }

    // Get beach data
    final data = await BeachService.getBeachData(
      geo['name'], geo['latitude'], geo['longitude']
    );

    setState(() {
      _isLoading = false;
      if (data != null) {
        _beachData = data;
        _getAiAnalysis(data);
      } else {
        _errorMessage = 'Ξ”ΞµΞ½ Ξ²ΟΞ­ΞΈΞ·ΞΊΞ±Ξ½ Ξ΄ΞµΞ΄ΞΏΞΌΞ­Ξ½Ξ± ΞΈΞ±Ξ»Ξ¬ΟƒΟƒΞ·Ο‚. Ξ‘Ξ½ Ξ· Ο„ΞΏΟ€ΞΏΞΈΞµΟƒΞ―Ξ± ΞµΞ―Ξ½Ξ±ΞΉ ΞΌΞ±ΞΊΟΞΉΞ¬ Ξ±Ο€Ο ΞΈΞ¬Ξ»Ξ±ΟƒΟƒΞ±, Ξ΄ΞΏΞΊΞ―ΞΌΞ±ΟƒΞµ ΞΊΞ±Ο€ΟΟ„Ξ· Ο€Ξ±ΟΞ±Ξ»ΞΉΞ±ΞΊΞ®.';
      }
    });
  }

  Future<void> _getAiAnalysis(BeachData data) async {
    setState(() { _aiLoading = true; });

    // Try with AI first
    final provider = await _storage.read(key: 'ai_provider');
    final apiKey = await _storage.read(key: '${provider ?? 'gemini'}_api_key');

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final context = 'Ξ Ξ±ΟΞ±Ξ»Ξ―Ξ±: ${data.locationName}\n'
          'ΞΟΞΌΞ±: ${data.waveHeight.toStringAsFixed(1)}m (${data.waveCondition})\n'
          'Ξ†Ξ½ΞµΞΌΞΏΟ‚: ${data.windSpeed.toStringAsFixed(0)} km/h ${data.waveDirectionText}\n'
          'ΞΞµΟΞΌΞΏΞΊΟΞ±ΟƒΞ―Ξ± Ξ½ΞµΟΞΏΟ: ${data.seaTemperature.toStringAsFixed(1)}Β°C\n'
          'Ξ ΞµΟΞ―ΞΏΞ΄ΞΏΟ‚ ΞΊΟΞΌΞ±Ο„ΞΏΟ‚: ${data.wavePeriod.toStringAsFixed(1)}s';
        final question = 'Ξ‘Ξ½Ξ¬Ξ»Ο…ΟƒΞµ Ο„ΞΉΟ‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚ Ξ³ΞΉΞ± ΞΊΞΏΞ»ΟΞΌΟ€ΞΉ, ΟƒΞµΟΟ†, ΞΊΞ±Ο„Ξ¬Ξ΄Ο…ΟƒΞ· ΞΊΞ±ΞΉ ΞµΞ½ΞµΟΞ³ΞµΞ―ΞµΟ‚ ΞΌΞµ Ο€Ξ±ΞΉΞ΄ΞΉΞ¬. Ξ£ΟΞ½Ο„ΞΏΞΌΞ±.';
        final response = await _aiService.ask(context, question);
        setState(() { _aiAnalysis = response; _aiLoading = false; });
        return;
      } catch (_) {}
    }

    // Fallback: rule-based
    setState(() {
      _aiAnalysis = _buildRuleBasedAnalysis(data);
      _aiLoading = false;
    });
  }

  String _buildRuleBasedAnalysis(BeachData data) {
    final parts = <String>[];
    switch (data.swimRating) {
      case 'good': parts.add('β… ΞΞΏΞ»ΟΞΌΟ€ΞΉ: ΞΞ±Ο„Ξ¬Ξ»Ξ»Ξ·Ξ»ΞµΟ‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚'); break;
      case 'warning': parts.add('β  ΞΞΏΞ»ΟΞΌΟ€ΞΉ: Ξ ΟΞΏΟƒΞΏΟ‡Ξ® Ξ»ΟΞ³Ο‰ ΞΊΟ…ΞΌΞ¬Ο„Ο‰Ξ½'); break;
      default: parts.add('β ΞΞΏΞ»ΟΞΌΟ€ΞΉ: Ξ‘ΞΊΞ±Ο„Ξ¬Ξ»Ξ»Ξ·Ξ»ΞµΟ‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚');
    }
    switch (data.surfRating) {
      case 'good': parts.add('π„ Ξ£ΞµΟΟ†: ΞΞ±Ο„Ξ¬Ξ»Ξ»Ξ·Ξ»ΞµΟ‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚'); break;
      case 'ok': parts.add('π„ Ξ£ΞµΟΟ†: ΞΞ­Ο„ΟΞΉΞµΟ‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚'); break;
      default: parts.add('π„ Ξ£ΞµΟΟ†: Ξ‘ΞΊΞ±Ο„Ξ¬Ξ»Ξ»Ξ·Ξ»ΞµΟ‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚');
    }
    if (data.divingRating == 'good') {
      parts.add('π¤Ώ ΞΞ±Ο„Ξ¬Ξ΄Ο…ΟƒΞ·: ΞΞ±Ξ»Ξ­Ο‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚');
    } else {
      parts.add('π¤Ώ ΞΞ±Ο„Ξ¬Ξ΄Ο…ΟƒΞ·: Ξ‘ΞΊΞ±Ο„Ξ¬Ξ»Ξ»Ξ·Ξ»ΞµΟ‚ ΟƒΟ…Ξ½ΞΈΞ®ΞΊΞµΟ‚');
    }
    parts.add('β  Ξ•Ξ½Ξ΄ΞµΞΉΞΊΟ„ΞΉΞΊΞ® Ξ±Ξ½Ξ¬Ξ»Ο…ΟƒΞ·. Ξ£Ο…ΞΌΞ²ΞΏΟ…Ξ»ΞµΟ…Ο„ΞµΞ―Ο„Ξµ Ο„ΞΉΟ‚ Ξ±ΟΞΌΟΞ΄ΞΉΞµΟ‚ Ξ±ΟΟ‡Ξ­Ο‚.');
    return parts.join('\n');;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006994), Color(0xFF00A8CC), Color(0xFF0077B6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Text('\ud83c\udfd6οΈ Ξ Ξ±ΟΞ±Ξ»Ξ―ΞµΟ‚', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006994), Color(0xFF0077B6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '\ud83d\udd0d Ξ‘Ξ½Ξ±Ξ¶Ξ®Ο„Ξ·ΟƒΞµ Ο€Ξ±ΟΞ±Ξ»Ξ―Ξ± (Ο€.Ο‡. Ξ‘Ξ³Ξ―Ξ± Ξ†Ξ½Ξ½Ξ± Ξ•ΟΞ²ΞΏΞΉΞ±)',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _searchBeach,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _searchBeach(_searchController.text),
                  icon: const Icon(Icons.search, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A8CC)))
              : _errorMessage != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ))
                : _beachData == null
                  ? _buildEmptyState()
                  : _buildBeachResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('\ud83c\udfd6οΈ', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Ξ‘Ξ½Ξ±Ξ¶Ξ®Ο„Ξ·ΟƒΞµ ΞΌΞΉΞ± Ο€Ξ±ΟΞ±Ξ»Ξ―Ξ±',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ο€.Ο‡. "Ξ‘Ξ³Ξ―Ξ± Ξ†Ξ½Ξ½Ξ± Ξ•ΟΞ²ΞΏΞΉΞ±" Ξ® "ΞΞ±Ξ»Ξ±ΞΌΞ―Ο„ΟƒΞΉ Ξ§Ξ±Ξ»ΞΊΞΉΞ΄ΞΉΞΊΞ®"',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
          const SizedBox(height: 24),
          // Quick suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              'Ξ‘Ξ³Ξ―Ξ± Ξ†Ξ½Ξ½Ξ±',
              'ΞΞ±Ξ»Ξ±ΞΌΞ―Ο„ΟƒΞΉ',
              'Ξ›ΞΏΟ…Ο„ΟΞ¬ΞΊΞΉ',
              'Ξ΅ΟΞ΄ΞΏΟ‚',
              'ΞΟΞΊΞΏΞ½ΞΏΟ‚',
            ].map((place) => GestureDetector(
              onTap: () {
                _searchController.text = place;
                _searchBeach(place);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006994).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00A8CC).withValues(alpha: 0.5)),
                ),
                child: Text(place, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBeachResults() {
    final d = _beachData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location header
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF00A8CC), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.locationName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main wave card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF006994), Color(0xFF0077B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _waveInfoItem('\ud83c\udf0a', 'ΞΟΞΌΞ±', '${d.waveHeight.toStringAsFixed(1)}m'),
                    _waveInfoItem('\ud83c\udf21οΈ', 'ΞΞµΟΟ', '${d.seaTemperature.toStringAsFixed(1)}Β°C'),
                    _waveInfoItem('\ud83d\udca8', 'Ξ†Ξ½ΞµΞΌΞΏΟ‚', '${d.windSpeed.toStringAsFixed(0)}km/h'),
                    _waveInfoItem('β±', 'Ξ ΞµΟΞ―ΞΏΞ΄ΞΏΟ‚', '${d.wavePeriod.toStringAsFixed(0)}s'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(d.waveCondition,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Activity ratings
          Row(
            children: [
              Expanded(child: _activityCard('\ud83c\udfca', 'ΞΞΏΞ»ΟΞΌΟ€ΞΉ', d.swimRating)),
              const SizedBox(width: 8),
              Expanded(child: _activityCard('\ud83c\udfc4', 'Ξ£ΞµΟΟ†', d.surfRating)),
              const SizedBox(width: 8),
              Expanded(child: _activityCard('\ud83e\udd3f', 'ΞΞ±Ο„Ξ¬Ξ΄Ο…ΟƒΞ·', d.divingRating)),
            ],
          ),
          const SizedBox(height: 16),

          // AI Analysis
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2137),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00A8CC).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('\ud83e\udd16', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('Ξ‘Ξ½Ξ¬Ξ»Ο…ΟƒΞ·',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                _aiLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A8CC), strokeWidth: 2))
                  : Text(_aiAnalysis ?? '', style: const TextStyle(color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waveInfoItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _activityCard(String emoji, String label, String rating) {
    Color color;
    String text;
    switch (rating) {
      case 'good': color = const Color(0xFF2ECC71); text = 'ΞΞ±Ξ»Ο'; break;
      case 'ok': color = const Color(0xFFF39C12); text = 'ΞΞ­Ο„ΟΞΉΞΏ'; break;
      default: color = const Color(0xFFE74C3C); text = 'ΞΞ±ΞΊΟ';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
