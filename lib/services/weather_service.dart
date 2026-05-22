import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> getWeather(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,'
      'uv_index,visibility'
      '&wind_speed_unit=kmh'
      '&timezone=auto',
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromOpenMeteo(json, lat, lon);
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather: $e');
    }
  }

  // Hourly forecast για τις επόμενες 24 ώρες
  Future<List<Map<String, dynamic>>> getHourlyForecast(
      double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&hourly=temperature_2m,precipitation_probability,weather_code'
      '&forecast_days=1'
      '&timezone=auto',
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final hourly = json['hourly'] as Map<String, dynamic>;
        final times = hourly['time'] as List;
        final temps = hourly['temperature_2m'] as List;
        final precip = hourly['precipitation_probability'] as List;
        final codes = hourly['weather_code'] as List;

        return List.generate(times.length, (i) => {
          'time': times[i],
          'temperature': temps[i],
          'precipitation_probability': precip[i],
          'weather_code': codes[i],
        });
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}