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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _beachData = null;
      _aiAnalysis = null;
    });

    final geo = await BeachService.geocodePlace(query);
    if (geo == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Δεν βρέθηκε η τοποθεσία. Δοκίμασε λιγότερο γενικά.';
      });
      return;
    }

    final data = await BeachService.getBeachData(
      geo['name'], geo['latitude'], geo['longitude']
    );

    setState(() {
      _isLoading = false;
      if (data != null) {
        _beachData = data;
        _getAiAnalysis(data);
      } else {
        _errorMessage = 'Δεν βρέθηκαν δεδομένα θαλάσσης. Αν η τοποθεσία είναι μακριά από θάλασσα, δοκίμασε κάποια παραλιακή.';
      }
    });
  }

  Future<void> _getAiAnalysis(BeachData data) async {
    setState(() { _aiLoading = true; });

    final provider = await _storage.read(key: 'ai_provider');
    final apiKey = await _storage.read(key: '${provider ?? 'gemini'}_api_key');

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final context = 'Παραλία: ${data.locationName}\n'
          'Κύμα: ${data.waveHeight.toStringAsFixed(1)}m (${data.waveCondition})\n'
          'Άνεμος: ${data.windSpeed.toStringAsFixed(0)} km/h ${data.waveDirectionText}\n'
          'Θερμοκρασία νερού: ${data.seaTemperature.toStringAsFixed(1)}°C\n'
          'Περίοδος κύματος: ${data.wavePeriod.toStringAsFixed(1)}s';
        const question = 'Ανάλυσε τις συνθήκες για κολύμπι, σερφ, κατάδυση και δραστηριότητες με παιδιά. Σύντομα.';
        final response = await _aiService.ask(context, question);
        setState(() { _aiAnalysis = response; _aiLoading = false; });
        return;
      } catch (_) {}
    }

    setState(() {
      _aiAnalysis = _buildRuleBasedAnalysis(data);
      _aiLoading = false;
    });
  }

  String _buildRuleBasedAnalysis(BeachData data) {
    final parts = <String>[];

    switch (data.swimRating) {
      case 'good':
        parts.add('✅ Κολύμπι: Κατάλληλες συνθήκες');
        break;
      case 'warning':
        parts.add('⚠ Κολύμπι: Προσοχή λόγω κυμάτων');
        break;
      default:
        parts.add('❌ Κολύμπι: Ακατάλληλες συνθήκες');
    }

    switch (data.surfRating) {
      case 'good':
        parts.add('🏄 Σερφ: Κατάλληλες συνθήκες');
        break;
      case 'ok':
        parts.add('🏄 Σερφ: Μέτριες συνθήκες');
        break;
      default:
        parts.add('🏄 Σερφ: Ακατάλληλες συνθήκες');
    }

    if (data.divingRating == 'good') {
      parts.add('🤿 Κατάδυση: Καλές συνθήκες');
    } else {
      parts.add('🤿 Κατάδυση: Ακατάλληλες συνθήκες');
    }

    parts.add('\n⚠ Ενδεικτική ανάλυση. Συμβουλευτείτε τις αρμόδιες αρχές.');
    return parts.join('\n');
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
        title: const Text('🏖️ Παραλίες',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
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
                      hintText: '🔍 Αναζήτησε παραλία (π.χ. Αγία Άννα Εύβοια)',
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
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A8CC)))
              : _errorMessage != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center),
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
          const Text('🏖️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Αναζήτησε μια παραλία',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('π.χ. "Αγία Άννα Εύβοια" ή "Καλαμίτσι Χαλκιδική"',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: ['Αγία Άννα', 'Καλαμίτσι', 'Λουτράκι', 'Ρόδος', 'Μύκονος']
              .map((place) => GestureDetector(
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
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF00A8CC), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.locationName,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    _waveInfoItem('🌊', 'Κύμα', '${d.waveHeight.toStringAsFixed(1)}m'),
                    _waveInfoItem('🌡️', 'Νερό', '${d.seaTemperature.toStringAsFixed(1)}°C'),
                    _waveInfoItem('💨', 'Άνεμος', '${d.windSpeed.toStringAsFixed(0)}km/h'),
                    _waveInfoItem('⏱', 'Περίοδος', '${d.wavePeriod.toStringAsFixed(0)}s'),
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
          Row(
            children: [
              Expanded(child: _activityCard('🏊', 'Κολύμπι', d.swimRating)),
              const SizedBox(width: 8),
              Expanded(child: _activityCard('🏄', 'Σερφ', d.surfRating)),
              const SizedBox(width: 8),
              Expanded(child: _activityCard('🤿', 'Κατάδυση', d.divingRating)),
            ],
          ),
          const SizedBox(height: 16),
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
                    Text('🤖', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('Ανάλυση',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                _aiLoading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFF00A8CC), strokeWidth: 2))
                  : Text(_aiAnalysis ?? '',
                      style: const TextStyle(color: Colors.white70, height: 1.5)),
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
        Text(value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _activityCard(String emoji, String label, String rating) {
    Color color;
    String text;
    switch (rating) {
      case 'good':
        color = const Color(0xFF2ECC71);
        text = 'Καλό';
        break;
      case 'ok':
        color = const Color(0xFFF39C12);
        text = 'Μέτριο';
        break;
      default:
        color = const Color(0xFFE74C3C);
        text = 'Κακό';
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
