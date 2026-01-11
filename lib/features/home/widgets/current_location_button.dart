import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../provider/map_provider.dart';

class CurrentLocationButton extends ConsumerWidget {
  final Completer<GoogleMapController> mapController;
  final bool showBottomSheet;

  const CurrentLocationButton({
    super.key,
    required this.mapController,
    required this.showBottomSheet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final directionEnabled = ref.watch(directionEnabledProvider);

    return Positioned(
      bottom: showBottomSheet ? 310 : 100,
      right: 10,
      child: FloatingActionButton(
        heroTag: 'currentLocationBtn',
        onPressed: isLoading
            ? null
            : () async {
                ref.read(isLoadingProvider.notifier).state = true;

                try {
                  // Invalidate to force refresh and get new location
                  ref.invalidate(currentLocationProvider);

                  // Wait for the new location data
                  final currentLocation = await ref.read(
                    currentLocationProvider.future,
                  );

                  if (kDebugMode) {
                    print('Current location received...');
                  }

                  if (currentLocation == null) {
                    ref.read(isLoadingProvider.notifier).state = false;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Current location not available'),
                        ),
                      );
                    }
                    return;
                  }

                  final controller = await mapController.future;
                  await controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(
                          currentLocation.latitude,
                          currentLocation.longitude,
                        ),
                        zoom: 15,
                      ),
                    ),
                  );

                  ref.read(sourceLocationProvider.notifier).state = LatLng(
                    currentLocation.latitude,
                    currentLocation.longitude,
                  );

                  // Mark that location permission is granted
                  ref.read(locationPermissionGrantedProvider.notifier).state =
                      true;

                  // If directionEnabled, reset source name to 'Your location'
                  if (directionEnabled) {
                    ref.read(sourceLocationNameProvider.notifier).state =
                        'Your location';

                    // Trigger route recalculation by refreshing the route provider
                    final destination = ref.read(destinationLocationProvider);
                    if (destination != null) {
                      ref.invalidate(routesProvider);
                    }
                  }

                  ref.read(isLoadingProvider.notifier).state = false;
                } catch (error, stackTrace) {
                  ref.read(isLoadingProvider.notifier).state = false;
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $error')));
                  }
                  if (kDebugMode) {
                    print('Error getting current location: $error');
                    print('Stack trace: $stackTrace');
                  }
                }
              },
        backgroundColor: Colors.white,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                Icons.my_location,
                color: Colors.blue.withValues(alpha: 0.7),
              ),
      ),
    );
  }
}
