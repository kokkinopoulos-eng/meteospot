import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/beach_service.dart';
import '../services/ai_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoriteSpot {
  final String name;
  final double latitude;
  final double longitude;
  final bool isSkiMode;

  FavoriteSpot({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isSkiMode,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'lat': latitude,
    'lon': longitude,
    'ski': isSkiMode,
  };

  factory FavoriteSpot.fromJson(Map<String, dynamic> j) => FavoriteSpot(
    name: j['name'],
    latitude: j['lat'],
    longitude: j['lon'],
    isSkiMode: j['ski'] ?? false,
  );
}

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
  bool _isSkiMode = false;
  bool _showMap = false;
  LatLng? _selectedPosition;
  List<FavoriteSpot> _favorites = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('beach_favorites') ?? '[]';
    final list = jsonDecode(raw) as List;
    setState(() {
      _favorites = list.map((e) => FavoriteSpot.fromJson(e)).toList();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('beach_favorites', jsonEncode(_favorites.map((f) => f.toJson()).toList()));
  }

  void _toggleFavorite() {
    if (_beachData == null) return;
    setState(() {
      if (_isFavorite) {
        _favorites.removeWhere((f) => f.name == _beachData!.locationName);
        _isFavorite = false;
      } else {
        _favorites.add(FavoriteSpot(
          name: _beachData!.locationName,
          latitude: _beachData!.latitude,
          longitude: _beachData!.longitude,
          isSkiMode: _isSkiMode,
        ));
        _isFavorite = true;
      }
      _saveFavorites();
    });
  }

  void _clearResults() {
    setState(() {
      _beachData = null;
      _errorMessage = null;
      _aiAnalysis = null;
      _searchController.clear();
      _showMap = false;
      _selectedPosition = null;
      _isFavorite = false;
    });
  }

  Future<void> _searchBeach(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _beachData = null;
      _aiAnalysis = null;
      _showMap = false;
      _isFavorite = false;
    });

    final geo = await BeachService.geocodePlace(query);
    if (geo == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '\u0394\u03b5\u03bd \u03b2\u03c1\u03ad\u03b8\u03b7\u03ba\u03b5. \u0395\u03c0\u03af\u03bb\u03b5\u03be\u03b5 \u03c3\u03c4\u03bf\u03bd \u03c7\u03ac\u03c1\u03c4\u03b7.';
        _showMap = true;
      });
      return;
    }

    await _loadData(geo['name'], geo['latitude'], geo['longitude']);
  }

  Future<void> _loadData(String name, double lat, double lon) async {
    if (!lat.isFinite || !lon.isFinite) return;
    setState(() { _isLoading = true; _errorMessage = null; _isFavorite = false; });

    // Geographic restriction
    if (!_isSkiMode) {
      final isSea = await BeachService.isSeaLocation(lat, lon);
      if (!isSea) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ Αυτή η τοποθεσία είναι στη ξηρά! Δοκίμασε παραλιακή τοποθεσία.';
        });
        return;
      }
    } else {
      final isMountain = await BeachService.isMountainLocation(lat, lon);
      if (!isMountain) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ Αυτή η τοποθεσία δεν είναι ορεινή! Δοκίμασε χιονοδρομική περιοχή (Παρνασσός, Βέρμιο...).';
        });
        return;
      }
    }

    final data = _isSkiMode
      ? await BeachService.getSkiData(name, lat, lon)
      : await BeachService.getBeachData(name, lat, lon);

    setState(() {
      _isLoading = false;
      if (data != null) {
        _beachData = data;
        _showMap = false;
        _isFavorite = _favorites.any((f) => f.name == name);
        _getAiAnalysis(data);
      } else {
        _errorMessage = _isSkiMode
          ? '❌ Δεν βρέθηκαν δεδομένα χιονιού. Δοκίμασε ορεινή περιοχή.'
          : '❌ Δεν βρέθηκαν δεδομένα θαλάσσης. Δοκίμασε παραλιακή τοποθεσία.';
      }
    });
  }
  Future<void> _getAiAnalysis(BeachData data) async {
    setState(() { _aiLoading = true; });

    final provider = await _storage.read(key: 'ai_provider');
    final apiKey = await _storage.read(key: '${provider ?? 'gemini'}_api_key');

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final context = _isSkiMode
          ? '\u03a7\u03b9\u03bf\u03bd\u03bf\u03b4\u03c1\u03bf\u03bc\u03b9\u03ba\u03cc: ${data.locationName}\n\u0398\u03b5\u03c1\u03bc\u03bf\u03ba\u03c1\u03b1\u03c3\u03af\u03b1: ${data.seaTemperature.toStringAsFixed(1)}\u00b0C\n\u03a7\u03b9\u03cc\u03bd\u03b9: ${data.waveHeight.toStringAsFixed(0)}cm\n\u0386\u03bd\u03b5\u03bc\u03bf\u03c2: ${data.windSpeed.toStringAsFixed(0)} km/h'
          : '\u03a0\u03b1\u03c1\u03b1\u03bb\u03af\u03b1: ${data.locationName}\n\u039a\u03cd\u03bc\u03b1: ${data.waveHeight.toStringAsFixed(1)}m\n\u0386\u03bd\u03b5\u03bc\u03bf\u03c2: ${data.windSpeed.toStringAsFixed(0)} km/h\n\u0398\u03b5\u03c1\u03bc\u03bf\u03ba\u03c1\u03b1\u03c3\u03af\u03b1 \u03bd\u03b5\u03c1\u03bf\u03cd: ${data.seaTemperature.toStringAsFixed(1)}\u00b0C';
        final question = _isSkiMode
          ? '\u0391\u03bd\u03ac\u03bb\u03c5\u03c3\u03b5 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2 \u03b3\u03b9\u03b1 \u03c3\u03ba\u03b9, snowboard, \u03bf\u03b9\u03ba\u03bf\u03b3\u03ad\u03bd\u03b5\u03b9\u03b1. \u03a3\u03cd\u03bd\u03c4\u03bf\u03bc\u03b1.'
          : '\u0391\u03bd\u03ac\u03bb\u03c5\u03c3\u03b5 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2 \u03b3\u03b9\u03b1 \u03ba\u03bf\u03bb\u03cd\u03bc\u03c0\u03b9, \u03c3\u03b5\u03c1\u03c6, \u03ba\u03b1\u03c4\u03ac\u03b4\u03c5\u03c3\u03b7, drone, \u03c0\u03b1\u03b9\u03b4\u03b9\u03ac. \u03a3\u03cd\u03bd\u03c4\u03bf\u03bc\u03b1.';
        final response = await _aiService.ask(context, question);
        setState(() { _aiAnalysis = response; _aiLoading = false; });
        return;
      } catch (_) {}
    }

    setState(() {
      _aiAnalysis = _isSkiMode ? _buildSkiAnalysis(data) : _buildBeachAnalysis(data);
      _aiLoading = false;
    });
  }

  String _buildBeachAnalysis(BeachData data) {
    final parts = <String>[];
    switch (data.swimRating) {
      case 'good': parts.add('\u2705 \u039a\u03bf\u03bb\u03cd\u03bc\u03c0\u03b9: \u039a\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2'); break;
      case 'warning': parts.add('\u26a0 \u039a\u03bf\u03bb\u03cd\u03bc\u03c0\u03b9: \u03a0\u03c1\u03bf\u03c3\u03bf\u03c7\u03ae \u03bb\u03cc\u03b3\u03c9 \u03ba\u03c5\u03bc\u03ac\u03c4\u03c9\u03bd'); break;
      default: parts.add('\u274c \u039a\u03bf\u03bb\u03cd\u03bc\u03c0\u03b9: \u0391\u03ba\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    }
    switch (data.surfRating) {
      case 'good': parts.add('\ud83c\udfc4 \u03a3\u03b5\u03c1\u03c6: \u039a\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2'); break;
      case 'ok': parts.add('\ud83c\udfc4 \u03a3\u03b5\u03c1\u03c6: \u039c\u03ad\u03c4\u03c1\u03b9\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2'); break;
      default: parts.add('\ud83c\udfc4 \u03a3\u03b5\u03c1\u03c6: \u0391\u03ba\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    }
    parts.add(data.divingRating == 'good'
      ? '\ud83e\udd3f \u039a\u03b1\u03c4\u03ac\u03b4\u03c5\u03c3\u03b7: \u039a\u03b1\u03bb\u03ad\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2'
      : '\ud83e\udd3f \u039a\u03b1\u03c4\u03ac\u03b4\u03c5\u03c3\u03b7: \u0391\u03ba\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    // Drone
    if (data.windSpeed < 30 && data.wavePeriod > 3) {
      parts.add('\ud83d\ude81 Drone: \u039a\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    } else if (data.windSpeed < 50) {
      parts.add('\ud83d\ude81 Drone: \u039c\u03ad\u03c4\u03c1\u03b9\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    } else {
      parts.add('\ud83d\ude81 Drone: \u0391\u03ba\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2 (\u03b9\u03c3\u03c7\u03c5\u03c1\u03cc\u03c2 \u03ac\u03bd\u03b5\u03bc\u03bf\u03c2)');
    }
    parts.add('\n\u26a0 \u0395\u03bd\u03b4\u03b5\u03b9\u03ba\u03c4\u03b9\u03ba\u03ae \u03b1\u03bd\u03ac\u03bb\u03c5\u03c3\u03b7. \u03a3\u03c5\u03bc\u03b2\u03bf\u03c5\u03bb\u03b5\u03c5\u03c4\u03b5\u03af\u03c4\u03b5 \u03c4\u03b9\u03c2 \u03b1\u03c1\u03bc\u03cc\u03b4\u03b9\u03b5\u03c2 \u03b1\u03c1\u03c7\u03ad\u03c2.');
    return parts.join('\n');
  }

  String _buildSkiAnalysis(BeachData data) {
    final parts = <String>[];
    final snow = data.waveHeight;
    final wind = data.windSpeed;
    final temp = data.seaTemperature;
    if (snow > 30 && wind < 40 && temp < 2) {
      parts.add('\u2705 \u03a3\u03ba\u03b9: \u0395\u03be\u03b1\u03b9\u03c1\u03b5\u03c4\u03b9\u03ba\u03ad\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    } else if (snow > 10 && wind < 60) {
      parts.add('\u26a0 \u03a3\u03ba\u03b9: \u039c\u03ad\u03c4\u03c1\u03b9\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    } else {
      parts.add('\u274c \u03a3\u03ba\u03b9: \u0391\u03ba\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    }
    parts.add(snow > 20 && wind < 50
      ? '\ud83c\udfc2 Snowboard: \u039a\u03b1\u03bb\u03ad\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2'
      : '\ud83c\udfc2 Snowboard: \u0391\u03ba\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    // Drone στα χιονοδρομικά
    if (wind < 25 && data.wavePeriod > 5) {
      parts.add('\ud83d\ude81 Drone: \u039a\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    } else {
      parts.add('\ud83d\ude81 Drone: \u0391\u03ba\u03b1\u03c4\u03ac\u03bb\u03bb\u03b7\u03bb\u03b5\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2');
    }
    if (temp < -5) parts.add('\ud83e\udd76 \u03a0\u03bf\u03bb\u03cd \u03ba\u03c1\u03cd\u03bf \u2014 \u03b6\u03b5\u03c3\u03c4\u03ac \u03c1\u03bf\u03cd\u03c7\u03b1 \u03b1\u03c0\u03b1\u03c1\u03b1\u03af\u03c4\u03b7\u03c4\u03b1');
    else if (temp < 0) parts.add('\u2744\ufe0f \u03a0\u03b1\u03b3\u03b5\u03c4\u03cc\u03c2 \u2014 \u03c0\u03c1\u03bf\u03c3\u03bf\u03c7\u03ae \u03c3\u03c4\u03bf\u03c5\u03c2 \u03b4\u03c1\u03cc\u03bc\u03bf\u03c5\u03c2');
    parts.add('\n\u26a0 \u0395\u03bd\u03b4\u03b5\u03b9\u03ba\u03c4\u03b9\u03ba\u03ae \u03b1\u03bd\u03ac\u03bb\u03c5\u03c3\u03b7. \u03a3\u03c5\u03bc\u03b2\u03bf\u03c5\u03bb\u03b5\u03c5\u03c4\u03b5\u03af\u03c4\u03b5 \u03c4\u03b1 \u03c7\u03b9\u03bf\u03bd\u03bf\u03b4\u03c1\u03bf\u03bc\u03b9\u03ba\u03ac \u03ba\u03ad\u03bd\u03c4\u03c1\u03b1.');
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSkiMode
                ? [const Color(0xFF1A237E), const Color(0xFF283593), const Color(0xFF1565C0)]
                : [const Color(0xFF006994), const Color(0xFF00A8CC), const Color(0xFF0077B6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(
          _isSkiMode ? '\ud83c\udfbf \u03a7\u03b9\u03bf\u03bd\u03bf\u03b4\u03c1\u03bf\u03bc\u03b9\u03ba\u03ac' : '\ud83c\udfd6\ufe0f \u03a0\u03b1\u03c1\u03b1\u03bb\u03af\u03b5\u03c2',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_beachData != null) ...[
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isFavorite ? Colors.amber : Colors.white),
              tooltip: _isFavorite ? '\u0391\u03c6\u03b1\u03af\u03c1\u03b5\u03c3\u03b7 \u03b1\u03c0\u03cc \u03b1\u03b3\u03b1\u03c0\u03b7\u03bc\u03ad\u03bd\u03b1' : '\u03a0\u03c1\u03bf\u03c3\u03b8\u03ae\u03ba\u03b7 \u03c3\u03c4\u03b1 \u03b1\u03b3\u03b1\u03c0\u03b7\u03bc\u03ad\u03bd\u03b1',
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearResults,
            ),
          ],
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isSkiMode
                  ? [const Color(0xFF1A237E), const Color(0xFF1565C0)]
                  : [const Color(0xFF006994), const Color(0xFF0077B6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                // Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modeButton('\ud83c\udfd6\ufe0f \u03a0\u03b1\u03c1\u03b1\u03bb\u03af\u03b1', !_isSkiMode, () {
                        setState(() { _isSkiMode = false; _clearResults(); });
                      }),
                      _modeButton('\ud83c\udfbf \u03a7\u03b9\u03bf\u03bd\u03bf\u03b4\u03c1\u03bf\u03bc\u03b9\u03ba\u03cc', _isSkiMode, () {
                        setState(() { _isSkiMode = true; _clearResults(); });
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isSkiMode
                            ? '\ud83d\udd0d \u03a0\u03b1\u03c1\u03bd\u03b1\u03c3\u03c3\u03cc\u03c2, \u0392\u03ad\u03c1\u03bc\u03b9\u03bf...'
                            : '\ud83d\udd0d \u0391\u03b3\u03af\u03b1 \u0386\u03bd\u03bd\u03b1, \u039c\u03cd\u03ba\u03bf\u03bd\u03bf\u03c2...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: _searchBeach,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _searchBeach(_searchController.text),
                      icon: const Icon(Icons.search, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => setState(() {
                        _showMap = !_showMap;
                        if (_showMap) _searchController.clear();
                      }),
                      icon: Icon(Icons.explore,
                        color: _showMap ? Colors.amber : Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: _showMap
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(10),
                      ),
                      tooltip: '\u0395\u03c0\u03b9\u03bb\u03bf\u03b3\u03ae \u03c3\u03c4\u03bf\u03bd \u03c7\u03ac\u03c1\u03c4\u03b7',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator(
                  color: _isSkiMode ? const Color(0xFF1565C0) : const Color(0xFF00A8CC)))
              : _showMap
                ? _buildMapSelector()
                : _beachData != null
                  ? _buildResults()
                  : _errorMessage != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center)))
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(label, style: TextStyle(
          color: Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 12)),
      ),
    );
  }

  Widget _buildMapSelector() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          color: const Color(0xFF0D2137),
          child: const Row(
            children: [
              Icon(Icons.touch_app, color: Color(0xFF00A8CC), size: 16),
              SizedBox(width: 6),
              Expanded(child: Text(
                '\u03a0\u03ac\u03c4\u03b1 \u03c3\u03c4\u03bf\u03bd \u03c7\u03ac\u03c1\u03c4\u03b7 \u03b3\u03b9\u03b1 \u03bd\u03b1 \u03b4\u03b5\u03b9\u03c2 \u03c4\u03b9\u03c2 \u03c3\u03c5\u03bd\u03b8\u03ae\u03ba\u03b5\u03c2',
                style: TextStyle(color: Colors.white70, fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(38.5, 23.5),
              initialZoom: 6.0,
              minZoom: 3.0,
              maxZoom: 14.0,
              onTap: (tapPosition, point) async {
                try {
                  if (!point.latitude.isFinite || !point.longitude.isFinite) return;
                  setState(() {
                    _selectedPosition = point;
                    _showMap = false;
                    _searchController.clear();
                  });
                  final name = await BeachService.reverseGeocode(point.latitude, point.longitude);
                  await _loadData(
                    name != null
                      ? '$name (${point.latitude.toStringAsFixed(3)}\u00b0, ${point.longitude.toStringAsFixed(3)}\u00b0)'
                      : '${point.latitude.toStringAsFixed(3)}\u00b0, ${point.longitude.toStringAsFixed(3)}\u00b0',
                    point.latitude,
                    point.longitude,
                  );
                } catch (_) {
                  setState(() {
                    _errorMessage = '\u03a3\u03c6\u03ac\u03bb\u03bc\u03b1. \u03a0\u03c1\u03bf\u03c3\u03c0\u03ac\u03b8\u03b7\u03c3\u03b5 \u03be\u03b1\u03bd\u03ac.';
                    _showMap = true;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'gr.webdevelopment.metaiospot',
              ),
              if (_selectedPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _selectedPosition!,
                    width: 36, height: 36,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
                  ),
                ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final suggestions = _isSkiMode
      ? ['\u03a0\u03b1\u03c1\u03bd\u03b1\u03c3\u03c3\u03cc\u03c2', '\u0392\u03ad\u03c1\u03bc\u03b9\u03bf', '\u039a\u03b1\u03ca\u03bc\u03b1\u03ba\u03c4\u03c3\u03b1\u03bb\u03ac\u03bd', '\u03a3\u03ad\u03bb\u03b9', '3-5 \u03a0\u03b7\u03b3\u03ac\u03b4\u03b9\u03b1']
      : ['\u0391\u03b3\u03af\u03b1 \u0386\u03bd\u03bd\u03b1', '\u039a\u03b1\u03bb\u03b1\u03bc\u03af\u03c4\u03c3\u03b9', '\u039b\u03bf\u03c5\u03c4\u03c1\u03ac\u03ba\u03b9', '\u03a1\u03cc\u03b4\u03bf\u03c2', '\u039c\u03cd\u03ba\u03bf\u03bd\u03bf\u03c2'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(_isSkiMode ? '\ud83c\udfbf' : '\ud83c\udfd6\ufe0f', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            _isSkiMode ? '\u0391\u03bd\u03b1\u03b6\u03ae\u03c4\u03b7\u03c3\u03b5 \u03c7\u03b9\u03bf\u03bd\u03bf\u03b4\u03c1\u03bf\u03bc\u03b9\u03ba\u03cc' : '\u0391\u03bd\u03b1\u03b6\u03ae\u03c4\u03b7\u03c3\u03b5 \u03c0\u03b1\u03c1\u03b1\u03bb\u03af\u03b1',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('\u03ae \u03c0\u03ac\u03c4\u03b1 \ud83d\uddfa\ufe0f \u03b3\u03b9\u03b1 \u03b5\u03c0\u03b9\u03bb\u03bf\u03b3\u03ae \u03c3\u03c4\u03bf\u03bd \u03c7\u03ac\u03c1\u03c4\u03b7',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions.map((place) => GestureDetector(
              onTap: () { _searchController.text = place; _searchBeach(place); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: (_isSkiMode ? const Color(0xFF1A237E) : const Color(0xFF006994)).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (_isSkiMode ? const Color(0xFF1565C0) : const Color(0xFF00A8CC)).withValues(alpha: 0.5)),
                ),
                child: Text(place, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            )).toList(),
          ),
          // Favorites
          if (_favorites.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.push_pin, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              const Text('\u0391\u03b3\u03b1\u03c0\u03b7\u03bc\u03ad\u03bd\u03b1',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            ..._favorites.map((f) => ListTile(
              dense: true,
              leading: Text(f.isSkiMode ? '\ud83c\udfbf' : '\ud83c\udfd6\ufe0f', style: const TextStyle(fontSize: 20)),
              title: Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                onPressed: () {
                  setState(() { _favorites.remove(f); });
                  _saveFavorites();
                },
              ),
              onTap: () {
                setState(() { _isSkiMode = f.isSkiMode; });
                _loadData(f.name, f.latitude, f.longitude);
              },
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final d = _beachData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.location_on, color: Color(0xFF00A8CC), size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(d.locationName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54, size: 18),
              onPressed: _clearResults),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isSkiMode
                  ? [const Color(0xFF1A237E), const Color(0xFF1565C0)]
                  : [const Color(0xFF006994), const Color(0xFF0077B6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _isSkiMode ? [
                  _infoItem('\u2744\ufe0f', '\u03a7\u03b9\u03cc\u03bd\u03b9', '${d.waveHeight.toStringAsFixed(0)}cm'),
                  _infoItem('\ud83c\udf21\ufe0f', '\u0398\u03b5\u03c1\u03bc.', '${d.seaTemperature.toStringAsFixed(1)}\u00b0C'),
                  _infoItem('\ud83d\udca8', '\u0386\u03bd\u03b5\u03bc\u03bf\u03c2', '${d.windSpeed.toStringAsFixed(0)}km/h'),
                  _infoItem('\ud83d\udc41\ufe0f', '\u039f\u03c1\u03b1\u03c4.', '${d.wavePeriod.toStringAsFixed(0)}km'),
                ] : [
                  _infoItem('\ud83c\udf0a', '\u039a\u03cd\u03bc\u03b1', '${d.waveHeight.toStringAsFixed(1)}m'),
                  _infoItem('\ud83c\udf21\ufe0f', '\u039d\u03b5\u03c1\u03cc', '${d.seaTemperature.toStringAsFixed(1)}\u00b0C'),
                  _infoItem('\ud83d\udca8', '\u0386\u03bd\u03b5\u03bc\u03bf\u03c2', '${d.windSpeed.toStringAsFixed(0)}km/h'),
                  _infoItem('\u23f1', '\u03a0\u03b5\u03c1\u03af\u03bf\u03b4\u03bf\u03c2', '${d.wavePeriod.toStringAsFixed(0)}s'),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_isSkiMode ? d.skiCondition : d.waveCondition,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: _isSkiMode ? [
            Expanded(child: _activityCard('\u26f7\ufe0f', '\u03a3\u03ba\u03b9',
              d.waveHeight > 30 && d.windSpeed < 40 ? 'good' : d.waveHeight > 10 ? 'ok' : 'bad')),
            const SizedBox(width: 6),
            Expanded(child: _activityCard('\ud83c\udfc2', 'Snow',
              d.waveHeight > 20 && d.windSpeed < 50 ? 'good' : d.waveHeight > 10 ? 'ok' : 'bad')),
            const SizedBox(width: 6),
            Expanded(child: _activityCard('\ud83d\ude81', 'Drone',
              d.windSpeed < 25 && d.wavePeriod > 5 ? 'good' : d.windSpeed < 50 ? 'ok' : 'bad')),
          ] : [
            Expanded(child: _activityCard('\ud83c\udfd4\ufe0f', '\u039a\u03bf\u03bb\u03cd\u03bc\u03c0\u03b9', d.swimRating)),
            const SizedBox(width: 6),
            Expanded(child: _activityCard('\ud83c\udfc4', '\u03a3\u03b5\u03c1\u03c6', d.surfRating)),
            const SizedBox(width: 6),
            Expanded(child: _activityCard('\ud83e\udd3f', '\u039a\u03b1\u03c4\u03ac\u03b4\u03c5\u03c3\u03b7', d.divingRating)),
            const SizedBox(width: 6),
            Expanded(child: _activityCard('\ud83d\ude81', 'Drone',
              d.windSpeed < 30 && d.wavePeriod > 3 ? 'good' : d.windSpeed < 50 ? 'ok' : 'bad')),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2137),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00A8CC).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Text('\ud83e\udd16', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('\u0391\u03bd\u03ac\u03bb\u03c5\u03c3\u03b7',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
                const SizedBox(height: 10),
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

  Widget _infoItem(String emoji, String label, String value) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
    ]);
  }

  Widget _activityCard(String emoji, String label, String rating) {
    Color color;
    String text;
    switch (rating) {
      case 'good': color = const Color(0xFF2ECC71); text = '\u039a\u03b1\u03bb\u03cc'; break;
      case 'ok': color = const Color(0xFFF39C12); text = '\u039c\u03ad\u03c4\u03c1\u03b9\u03bf'; break;
      default: color = const Color(0xFFE74C3C); text = '\u039a\u03b1\u03ba\u03cc';
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
      ]),
    );
  }
}
