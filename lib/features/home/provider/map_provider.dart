import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/features/home/repository/map_reposotiry.dart';
import 'package:map/services/location_service.dart';

// address search page providers

// user input
final userInputStateProvider = StateProvider<String>((ref) => '');

// map repository provider
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository();
});

// autocomplete results provider
final autoCompleteResultsProvider = FutureProvider<List<dynamic>>((ref) async {
  final userInput = ref.watch(userInputStateProvider);
  if (userInput.isEmpty) {
    return [];
  }
  final mapRepository = ref.read(mapRepositoryProvider);
  final results = await mapRepository.getAutocomplete(userInput);

  return results;
});

// map screen providers

// location permission granted provider
final locationPermissionGrantedProvider = StateProvider<bool>((ref) => false);

// current location provider
final locationProvider = Provider((ref) => LocationService());

final currentLocationProvider = FutureProvider<LatLng?>((ref) async {
  final locationService = ref.read(locationProvider);
  return locationService.getCurrentLocation();
});

// isLoading
final isLoadingProvider = StateProvider<bool>((ref) => false);

// map type provider
final mapTypeProvider = StateProvider<MapType>((ref) => MapType.normal);

// markers provider
final markersProvider = StateProvider<Set<Marker>>((ref) => {});

//  source Location
final sourceLocationProvider = StateProvider<LatLng?>((ref) => null);
// destination Location
final destinationLocationProvider = StateProvider<LatLng?>((ref) => null);

// mode (bicycle has better coverage than walk for longer distances)
final modeProvider = StateProvider<String>((ref) => 'walk');
// polyline points provider
final polylinePointsProvider = StateProvider<Set<Polyline>?>((ref) => null);

//  routes provider
final routesProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final source = ref.watch(sourceLocationProvider);
  final destination = ref.watch(destinationLocationProvider);
  final mode = ref.watch(modeProvider);
  final mapRepository = ref.read(mapRepositoryProvider);
  // Geoapify expects latitude,longitude format in waypoints parameter
  final waypoints =
      "${source?.latitude},${source?.longitude}|${destination?.latitude},${destination?.longitude}";
  return await mapRepository.getRoutes(waypoints, mode);
});

// distance provider
final distanceProvider = StateProvider<String>((ref) => '');

// duration provider
final durationProvider = StateProvider<String>((ref) => '');

// polyline coordinates provider
final polylineCoordinatesProvider = StateProvider<List<LatLng>>((ref) => []);

// show bottom sheet provider
final showBottomSheetProvider = StateProvider<bool>((ref) => false);

// name of place provider
final placeNameProvider = StateProvider<String>((ref) => '');

// source location name provider
final sourceLocationNameProvider = StateProvider<String>(
  (ref) => 'Your location',
);

// street address provider
final streetAddressProvider = StateProvider<String>((ref) => '');

// coordinates provider
final coordinatesProvider = StateProvider<List<dynamic>>((ref) => []);

// directionEnabled provider
final directionEnabledProvider = StateProvider<bool>((ref) => false);

// start navigation provider
final startNavigationProvider = StateProvider<bool>((ref) => false);

// current user location during navigation
final currentUserLocationProvider = StateProvider<LatLng?>((ref) => null);

// passed polyline points (with opacity)
final passedPolylineProvider = StateProvider<Set<Polyline>>((ref) => {});

// remaining polyline points (pure blue)
final remainingPolylineProvider = StateProvider<Set<Polyline>>((ref) => {});

// has arrived at destination
final hasArrivedProvider = StateProvider<bool>((ref) => false);

// bearing/rotation for navigation
final mapBearingProvider = StateProvider<double>((ref) => 0.0);
