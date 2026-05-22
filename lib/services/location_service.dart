import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    // Έλεγχος αν είναι ενεργοποιημένο το GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Το GPS είναι απενεργοποιημένο');
    }

    // Έλεγχος permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Δεν δόθηκε άδεια τοποθεσίας');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Η άδεια τοποθεσίας απορρίφθηκε μόνιμα. '
          'Ενεργοποιήστε την από τις Ρυθμίσεις.');
    }

    // Παίρνουμε τη θέση
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  // Stream για συνεχή ενημέρωση θέσης
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // ενημέρωση κάθε 100m
      ),
    );
  }
}