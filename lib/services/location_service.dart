import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rientro/core/constants/app_constants.dart';

/// Servizio per gestione posizione
class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Controlla e richiede permessi
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Controlla se i permessi sono stati concessi
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  /// Ottieni posizione corrente
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPerms = await checkAndRequestPermission();
      if (!hasPerms) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: AppConstants.locationTimeoutSeconds),
      );
    } catch (e) {
      return null;
    }
  }

  /// Ottieni posizione come GeoPoint Firestore
  Future<GeoPoint?> getCurrentGeoPoint() async {
    final position = await getCurrentPosition();
    if (position == null) return null;
    return GeoPoint(position.latitude, position.longitude);
  }

  /// Ottieni ultima posizione conosciuta (più veloce)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Stream delle posizioni
  Stream<Position> getPositionStream({
    int distanceFilter = 50, // metri
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Avvia tracking continuo
  void startTracking({
    required Function(GeoPoint) onLocation,
    int distanceFilter = 100,
  }) {
    _positionSubscription?.cancel();
    _positionSubscription = getPositionStream(
      distanceFilter: distanceFilter,
    ).listen((position) {
      onLocation(GeoPoint(position.latitude, position.longitude));
    });
  }

  /// Ferma tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calcola distanza tra due punti (in metri)
  double calculateDistance(GeoPoint from, GeoPoint to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Ottieni indirizzo da coordinate (reverse geocoding)
  Future<String?> getAddressFromGeoPoint(GeoPoint point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      
      if (placemarks.isEmpty) return null;
      
      final place = placemarks.first;
      
      // Formatta indirizzo in modo leggibile
      final parts = <String>[];
      if (place.street != null && place.street!.isNotEmpty) {
        parts.add(place.street!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add(place.locality!);
      }
      
      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      return null;
    }
  }

  /// Ottieni coordinate da indirizzo (geocoding)
  Future<GeoPoint?> getGeoPointFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;
      
      return GeoPoint(
        locations.first.latitude,
        locations.first.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Genera link Google Maps per una posizione
  String getGoogleMapsLink(GeoPoint point) {
    return 'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}';
  }

  /// Genera link Apple Maps per una posizione
  String getAppleMapsLink(GeoPoint point) {
    return 'https://maps.apple.com/?q=${point.latitude},${point.longitude}';
  }

  /// Verifica se utente è arrivato a destinazione
  bool hasArrivedAtDestination(
    GeoPoint current,
    GeoPoint destination, {
    double thresholdMeters = 100,
  }) {
    final distance = calculateDistance(current, destination);
    return distance <= thresholdMeters;
  }

  /// Dispose
  void dispose() {
    stopTracking();
  }
}

