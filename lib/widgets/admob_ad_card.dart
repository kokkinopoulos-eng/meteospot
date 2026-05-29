import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/weather_data.dart';

class AdmobAdCard extends StatefulWidget {
  final WeatherData weatherData;
  const AdmobAdCard({super.key, required this.weatherData});

  @override
  State<AdmobAdCard> createState() => _AdmobAdCardState();
}

class _AdmobAdCardState extends State<AdmobAdCard> {
  NativeAd? _nativeAd;
  bool _adLoaded = false;

  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  List<String> _getKeywords() {
    final w = widget.weatherData;
    final keywords = <String>['weather', 'forecast'];
    if (w.uvIndex > 5) keywords.addAll(['sunscreen', 'sunglasses', 'uv protection']);
    if (w.weatherCode >= 61 && w.weatherCode <= 67) keywords.addAll(['rain', 'umbrella', 'raincoat', 'delivery']);
    if (w.temperature > 35) keywords.addAll(['heat', 'air conditioning', 'fan', 'cooling']);
    if (w.temperature < 5) keywords.addAll(['cold', 'heating', 'winter clothes']);
    if (w.windSpeed > 40) keywords.addAll(['wind', 'car insurance', 'storm']);
    if (w.weatherCode >= 71 && w.weatherCode <= 77) keywords.addAll(['snow', 'winter', 'boots']);
    return keywords;
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final request = AdRequest(keywords: _getKeywords());
    _nativeAd = NativeAd(
      adUnitId: _testAdUnitId,
      request: request,
      factoryId: 'listTile',
      listener: NativeAdListener(
        onAdLoaded: (_) => setState(() => _adLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_adLoaded || _nativeAd == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF162035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('SPONSORED',
                  style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 0.5)),
            ),
          ),
          SizedBox(
            height: 120,
            child: AdWidget(ad: _nativeAd!),
          ),
        ],
      ),
    );
  }
}
