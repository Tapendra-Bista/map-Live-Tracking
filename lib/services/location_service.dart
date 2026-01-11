import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;
      LocationData locationData;

      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }

      locationData = await location.getLocation();
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
      return LatLng(27.7172, 85.3240);
    } // Placeholder
  }

  // Start continuous location tracking
  Stream<LatLng> startLocationTracking() {
    final controller = StreamController<LatLng>();

    _locationSubscription = location.onLocationChanged.listen(
      (LocationData currentLocation) {
        if (currentLocation.latitude != null &&
            currentLocation.longitude != null) {
          controller.add(
            LatLng(currentLocation.latitude!, currentLocation.longitude!),
          );
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Location tracking error: $error');
        }
      },
    );

    return controller.stream;
  }

  // Stop location tracking
  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }
}
