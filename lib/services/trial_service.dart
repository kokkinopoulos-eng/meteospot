import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrialService {
  static const String _purchasedKey = 'app_purchased';
  static const String _firstSeenKey = 'first_seen_date';
  static const int trialDays = 3;

  // Check if app is purchased
  static Future<bool> isPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_purchasedKey) ?? false;
  }

  // Mark as purchased
  static Future<void> setPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_purchasedKey, true);
  }

  // Get trial status
  static Future<TrialStatus> getTrialStatus() async {
    // If purchased, always full access
    if (await isPurchased()) {
      return TrialStatus(isActive: true, isPurchased: true, daysLeft: 999);
    }

    final prefs = await SharedPreferences.getInstance();

    // Get install date from Android
    DateTime installDate;
    try {
      await PackageInfo.fromPlatform();
      // Use firstInstallTime if available via shared prefs fallback
      final storedInstall = prefs.getString('install_date');
      if (storedInstall != null) {
        installDate = DateTime.parse(storedInstall);
      } else {
        installDate = DateTime.now();
        await prefs.setString('install_date', installDate.toIso8601String());
      }
    } catch (_) {
      installDate = DateTime.now();
    }

    // Get first seen date (more reliable than install)
    String? firstSeenStr = prefs.getString(_firstSeenKey);
    DateTime firstSeen;
    if (firstSeenStr == null) {
      // First launch - use earlier of install date or now
      firstSeen = installDate.isBefore(DateTime.now()) ? installDate : DateTime.now();
      await prefs.setString(_firstSeenKey, firstSeen.toIso8601String());
    } else {
      firstSeen = DateTime.parse(firstSeenStr);
    }

    final daysPassed = DateTime.now().difference(firstSeen).inDays;
    final daysLeft = trialDays - daysPassed;

    return TrialStatus(
      isActive: daysLeft > 0,
      isPurchased: false,
      daysLeft: daysLeft > 0 ? daysLeft : 0,
      firstSeen: firstSeen,
    );
  }
}

class TrialStatus {
  final bool isActive;
  final bool isPurchased;
  final int daysLeft;
  final DateTime? firstSeen;

  TrialStatus({
    required this.isActive,
    required this.isPurchased,
    required this.daysLeft,
    this.firstSeen,
  });

  bool get hasFullAccess => isActive || isPurchased;
}
