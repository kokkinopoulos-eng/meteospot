import 'dart:math';

class SunMoonData {
  final DateTime sunrise;
  final DateTime sunset;
  final double moonPhase;
  final String moonPhaseName;
  final String moonEmoji;
  final Duration dayLength;

  SunMoonData({
    required this.sunrise,
    required this.sunset,
    required this.moonPhase,
    required this.moonPhaseName,
    required this.moonEmoji,
    required this.dayLength,
  });
}

class SunMoonService {
  SunMoonData calculate(double latitude, double longitude, DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final latRad = latitude * pi / 180;
    final declination = 0.4093 * sin(2 * pi * (dayOfYear - 81) / 365);
    final hourAngle = acos(-tan(latRad) * tan(declination));
    final solarNoon = 12 - longitude / 15;
    final sunriseHour = solarNoon - hourAngle * 12 / pi;
    final sunsetHour = solarNoon + hourAngle * 12 / pi;
    final tzOffset = DateTime.now().timeZoneOffset;
    final sunrise = DateTime(date.year, date.month, date.day)
        .add(Duration(milliseconds: (sunriseHour * 3600000).round()))
        .add(tzOffset);
    final sunset = DateTime(date.year, date.month, date.day)
        .add(Duration(milliseconds: (sunsetHour * 3600000).round()))
        .add(tzOffset);
    final dayLength = sunset.difference(sunrise);
    final knownNewMoon = DateTime(2000, 1, 6, 18, 14);
    final daysSince = date.difference(knownNewMoon).inMilliseconds / 86400000.0;
    final lunarCycle = 29.53058867;
    final phase = (daysSince % lunarCycle) / lunarCycle;
    String phaseName;
    String emoji;
    if (phase < 0.03 || phase > 0.97) {
      phaseName = '\u039D\u03AD\u03B1 \u03A3\u03B5\u03BB\u03AE\u03BD\u03B7';
      emoji = '\u{1F311}';
    } else if (phase < 0.22) {
      phaseName = '\u0391\u03CD\u03BE\u03BF\u03C5\u03C3\u03B1 \u039C\u03B7\u03BD\u03BF\u03B5\u03B9\u03B4\u03AE\u03C2';
      emoji = '\u{1F312}';
    } else if (phase < 0.28) {
      phaseName = '\u03A0\u03C1\u03CE\u03C4\u03BF \u03A4\u03AD\u03C4\u03B1\u03C1\u03C4\u03BF';
      emoji = '\u{1F313}';
    } else if (phase < 0.47) {
      phaseName = '\u0391\u03CD\u03BE\u03BF\u03C5\u03C3\u03B1 \u0391\u03BC\u03C6\u03AF\u03BA\u03C5\u03C1\u03C4\u03B7';
      emoji = '\u{1F314}';
    } else if (phase < 0.53) {
      phaseName = '\u03A0\u03B1\u03BD\u03C3\u03AD\u03BB\u03B7\u03BD\u03BF\u03C2';
      emoji = '\u{1F315}';
    } else if (phase < 0.72) {
      phaseName = '\u03A6\u03B8\u03AF\u03BD\u03BF\u03C5\u03C3\u03B1 \u0391\u03BC\u03C6\u03AF\u03BA\u03C5\u03C1\u03C4\u03B7';
      emoji = '\u{1F316}';
    } else if (phase < 0.78) {
      phaseName = '\u03A4\u03B5\u03BB\u03B5\u03C5\u03C4\u03B1\u03AF\u03BF \u03A4\u03AD\u03C4\u03B1\u03C1\u03C4\u03BF';
      emoji = '\u{1F317}';
    } else {
      phaseName = '\u03A6\u03B8\u03AF\u03BD\u03BF\u03C5\u03C3\u03B1 \u039C\u03B7\u03BD\u03BF\u03B5\u03B9\u03B4\u03AE\u03C2';
      emoji = '\u{1F318}';
    }
    return SunMoonData(
      sunrise: sunrise,
      sunset: sunset,
      moonPhase: phase,
      moonPhaseName: phaseName,
      moonEmoji: emoji,
      dayLength: dayLength,
    );
  }
}
