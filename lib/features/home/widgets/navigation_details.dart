import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../provider/map_provider.dart';

class NavigationDetails extends ConsumerWidget {
  final Future<GoogleMapController> mapController;

  const NavigationDetails({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = ref.watch(distanceProvider);
    final duration = ref.watch(durationProvider);
    final currentTime = DateFormat('h:mm a').format(DateTime.now());

    return Positioned(
      top: 50,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'Current Time',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            // Divider
            Container(height: 40, width: 1, color: Colors.grey.shade300),

            // Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  distance.isNotEmpty
                      ? '${(double.parse(distance) / 1000).toStringAsFixed(2)} km'
                      : '0 km',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  'Remaining',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            // Duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duration.isNotEmpty
                      ? '${(double.parse(duration) / 60).toStringAsFixed(0)} min'
                      : '0 min',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'ETA',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            // Close button
            InkWell(
              onTap: () async {
                // Stop navigation and return to normal map
                ref.read(startNavigationProvider.notifier).state = false;
                ref.read(directionEnabledProvider.notifier).state = false;
                ref.read(showBottomSheetProvider.notifier).state = false;
                ref.read(polylinePointsProvider.notifier).state = null;
                ref.read(markersProvider.notifier).state = {};
                ref.read(mapBearingProvider.notifier).state = 0.0;

                // Reset camera to default view
                final controller = await mapController;
                final currentLoc = ref.read(currentUserLocationProvider);
                if (currentLoc != null) {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: currentLoc,
                        zoom: 15,
                        bearing: 0,
                        tilt: 0,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.red, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
