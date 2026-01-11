import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../provider/map_provider.dart';

class ArrivalDialog extends ConsumerWidget {
  final Completer<GoogleMapController> mapController;
  final String placeName;

  const ArrivalDialog({
    super.key,
    required this.mapController,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'You have arrived!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  placeName,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    // Reset navigation state
                    ref.read(hasArrivedProvider.notifier).state = false;
                    ref.read(startNavigationProvider.notifier).state = false;
                    ref.read(directionEnabledProvider.notifier).state = false;
                    ref.read(showBottomSheetProvider.notifier).state = false;
                    ref.read(polylinePointsProvider.notifier).state = null;
                    ref.read(markersProvider.notifier).state = {};
                    ref.read(mapBearingProvider.notifier).state = 0.0;

                    // Reset camera to default view
                    final controller = await mapController.future;
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
