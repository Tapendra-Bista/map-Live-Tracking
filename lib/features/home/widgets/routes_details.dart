import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../services/location_service.dart';
import '../provider/map_provider.dart';

class RoutesDetails extends ConsumerStatefulWidget {
  final Future<GoogleMapController> mapController;

  const RoutesDetails({super.key, required this.mapController});

  @override
  ConsumerState<RoutesDetails> createState() => _RoutesDetailsState();
}

class _RoutesDetailsState extends ConsumerState<RoutesDetails> {
  StreamSubscription<LatLng>? _locationSubscription;
  LocationService? _locationService;

  @override
  void initState() {
    super.initState();
    // Listen to route changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(routesProvider, (previous, next) {
        next.whenData((routeData) {
          if (routeData != null && mounted) {
            // Update distance and duration
            ref.read(distanceProvider.notifier).state =
                routeData['properties']['distance'].toString();
            ref.read(durationProvider.notifier).state =
                routeData['properties']['time'].toString();

            // Update polyline if direction is enabled
            if (ref.read(directionEnabledProvider)) {
              final coordinates =
                  routeData['geometry']['coordinates'][0] as List;
              ref.read(coordinatesProvider.notifier).state = coordinates;

              final polylinePoints = coordinates
                  .map<LatLng>((point) => LatLng(point[1], point[0]))
                  .toList();

              ref.read(polylinePointsProvider.notifier).state = {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: polylinePoints,
                  color: Colors.blueAccent,
                  width: 4,
                ),
              };
            }

            if (kDebugMode) {
              print('Route updated for mode: ${ref.read(modeProvider)}');
            }
          }
        });
      });

      // Listen to navigation state changes
      ref.listenManual(startNavigationProvider, (previous, next) {
        if (next && !previous!) {
          _startLocationTracking();
        } else if (!next && previous!) {
          _stopLocationTracking();
        }
      });
    });
  }

  void _startLocationTracking() {
    _locationService = ref.read(locationProvider);
    final routePoints = ref.read(coordinatesProvider);

    if (routePoints.isEmpty) return;

    final allRoutePoints = routePoints
        .map<LatLng>((point) => LatLng(point[1], point[0]))
        .toList();

    final destination = allRoutePoints.last;
    final mode = ref.read(modeProvider);

    // Average speeds in km/h for different modes
    final speedMap = {'walk': 5.0, 'bicycle': 15.0, 'drive': 40.0};
    final averageSpeed = speedMap[mode] ?? 5.0;

    // Set initial camera position at start of navigation
    final currentLoc =
        ref.read(currentUserLocationProvider) ??
        ref.read(sourceLocationProvider);
    if (currentLoc != null && allRoutePoints.length > 1) {
      final initialBearing = _calculateBearing(currentLoc, allRoutePoints[1]);
      widget.mapController.then((controller) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLoc,
              zoom: 18.5,
              bearing: initialBearing,
              tilt: 60,
            ),
          ),
        );
      });
    }

    _locationSubscription = _locationService!.startLocationTracking().listen((
      currentLocation,
    ) {
      if (!mounted) return;

      ref.read(currentUserLocationProvider.notifier).state = currentLocation;

      // Check if arrived at destination (within 20 meters)
      final distanceToDestination = _calculateRealDistance(
        currentLocation,
        destination,
      );

      if (distanceToDestination < 20) {
        ref.read(hasArrivedProvider.notifier).state = true;
        _stopLocationTracking();
        return;
      }

      // Find closest point on route to current location
      int closestIndex = _findClosestPointIndex(
        currentLocation,
        allRoutePoints,
      );

      // Split route into passed and remaining segments
      final passedPoints = allRoutePoints.sublist(0, closestIndex + 1);
      final remainingPoints = allRoutePoints.sublist(closestIndex);

      // Calculate remaining distance
      double remainingDistance = 0;
      for (int i = 0; i < remainingPoints.length - 1; i++) {
        remainingDistance += _calculateRealDistance(
          remainingPoints[i],
          remainingPoints[i + 1],
        );
      }

      // Update distance and duration
      ref.read(distanceProvider.notifier).state = remainingDistance
          .toStringAsFixed(0);

      // Calculate estimated time based on remaining distance and average speed
      final remainingTimeMinutes =
          (remainingDistance / 1000) / averageSpeed * 60;
      ref.read(durationProvider.notifier).state = (remainingTimeMinutes * 60)
          .toStringAsFixed(0); // Convert to seconds

      // Update polylines with different colors
      final passedPolyline = {
        if (passedPoints.length > 1)
          Polyline(
            polylineId: const PolylineId('passed_route'),
            points: passedPoints,
            color: Colors.blue.withValues(alpha: 0.4),
            width: 4,
          ),
      };

      final remainingPolyline = {
        if (remainingPoints.length > 1)
          Polyline(
            polylineId: const PolylineId('remaining_route'),
            points: remainingPoints,
            color: Colors.blue,
            width: 4,
          ),
      };

      ref.read(passedPolylineProvider.notifier).state = passedPolyline;
      ref.read(remainingPolylineProvider.notifier).state = remainingPolyline;

      // Combine polylines for display
      ref.read(polylinePointsProvider.notifier).state = {
        ...passedPolyline,
        ...remainingPolyline,
      };

      // Calculate bearing to next point and update camera
      if (closestIndex < allRoutePoints.length - 1) {
        final nextPoint = allRoutePoints[closestIndex + 1];
        final bearing = _calculateBearing(currentLocation, nextPoint);
        ref.read(mapBearingProvider.notifier).state = bearing;

        // Update camera to follow user with rotation
        // User location at bottom, looking toward destination at top
        widget.mapController.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: currentLocation,
                zoom: 18.5,
                bearing: bearing,
                tilt: 60,
              ),
            ),
          );
        });
      }
    });
  }

  int _findClosestPointIndex(LatLng currentLocation, List<LatLng> routePoints) {
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < routePoints.length; i++) {
      final distance = _calculateDistance(currentLocation, routePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    final lat1 = point1.latitude;
    final lon1 = point1.longitude;
    final lat2 = point2.latitude;
    final lon2 = point2.longitude;

    return ((lat2 - lat1) * (lat2 - lat1)) + ((lon2 - lon1) * (lon2 - lon1));
  }

  // Calculate real distance in meters using Haversine formula
  double _calculateRealDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;

    return (bearing + 360) % 360;
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService?.stopLocationTracking();
    _locationService = null;
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeName = ref.watch(placeNameProvider);
    final streetAddress = ref.watch(streetAddressProvider);
    final directionEnabled = ref.watch(directionEnabledProvider);
    final selectedMode = ref.watch(modeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .only(topLeft: .circular(20), topRight: .circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: .symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: .min,
          mainAxisAlignment: .start,
          crossAxisAlignment: .start,
          children: [
            SizedBox(height: 10),
            Center(
              child: SizedBox(
                height: 5,
                width: 45,
                child: Divider(
                  radius: .circular(20),
                  thickness: 5,
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(
                  placeName,
                  style: TextStyle(fontSize: 18, fontWeight: .bold),
                ),

                IconButton(
                  style: .new(backgroundColor: .all(Colors.grey.shade200)),
                  onPressed: directionEnabled
                      ? () {
                          ref.read(directionEnabledProvider.notifier).state =
                              false;
                          ref.read(polylinePointsProvider.notifier).state =
                              null;
                        }
                      : () {
                          ref.read(showBottomSheetProvider.notifier).state =
                              false;
                          ref.read(markersProvider.notifier).state = {};
                        },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              streetAddress,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (directionEnabled) ...[
              Text(
                'Distance: ${(double.parse(ref.watch(distanceProvider)) / 1000).toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Duration: ${(double.parse(ref.watch(durationProvider)) / 60).toStringAsFixed(0)} min',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            SizedBox(height: 20),
            directionEnabled
                ? Column(
                    mainAxisAlignment: .start,
                    crossAxisAlignment: .start,

                    children: [
                      Row(
                        mainAxisAlignment: .spaceEvenly,
                        children: [
                          _ModeButton(
                            label: 'Walk',
                            icon: Icons.directions_walk,
                            mode: 'walk',
                            isSelected: selectedMode == 'walk',
                            onTap: () {
                              ref.read(modeProvider.notifier).state = 'walk';
                              // Refetch route with new mode
                              ref.invalidate(routesProvider);
                            },
                          ),
                          _ModeButton(
                            label: 'Drive',
                            icon: Icons.directions_car,
                            mode: 'drive',
                            isSelected: selectedMode == 'drive',
                            onTap: () {
                              ref.read(modeProvider.notifier).state = 'drive';
                              ref.invalidate(routesProvider);
                            },
                          ),
                          _ModeButton(
                            label: 'Bike',
                            icon: Icons.directions_bike,
                            mode: 'bicycle',
                            isSelected: selectedMode == 'bicycle',
                            onTap: () {
                              ref.read(modeProvider.notifier).state = 'bicycle';
                              ref.invalidate(routesProvider);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      Center(
                        child: Container(
                          height: 45,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: .circular(32),
                          ),
                          child: Center(
                            child: InkWell(
                              onTap: () {
                                ref
                                        .read(startNavigationProvider.notifier)
                                        .state =
                                    true;
                              },
                              child: Text(
                                'Start',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      height: 45,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: .circular(32),
                      ),
                      child: Center(
                        child: InkWell(
                          onTap: () {
                            final coordinates = ref.read(coordinatesProvider);
                            final polylinePoints = coordinates
                                .map<LatLng>(
                                  (point) => LatLng(point[1], point[0]),
                                )
                                .toList();

                            ref.read(polylinePointsProvider.notifier).state = {
                              Polyline(
                                polylineId: const PolylineId('route'),
                                points: polylinePoints,
                                color: Colors.blueAccent,
                                width: 4,
                              ),
                            };
                            ref.read(directionEnabledProvider.notifier).state =
                                true;
                          },
                          child: Row(
                            mainAxisAlignment: .center,
                            spacing: 10,
                            children: [
                              Icon(
                                Icons.directions,
                                size: 16,
                                color: Colors.white,
                              ),
                              Text(
                                'Directions',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
