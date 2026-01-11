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
    final currentLocation = ref.watch(currentLocationProvider);
    final directionEnabled = ref.watch(directionEnabledProvider);

    return Positioned(
      bottom: showBottomSheet ? 310 : 100,
      right: 10,
      child: FloatingActionButton(
        heroTag: 'currentLocationBtn',
        onPressed: isLoading
            ? null
            : () async {
                ref.read(currentLocationProvider);
                currentLocation.when(
                  data: (data) async {
                    if (kDebugMode) {
                      print(' current location received...');
                    }
                    if (data == null) {
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
                    try {
                      final controller = await mapController.future;
                      await controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(data.latitude, data.longitude),
                            zoom: 15,
                          ),
                        ),
                      );
                      ref.read(sourceLocationProvider.notifier).state = LatLng(
                        data.latitude,
                        data.longitude,
                      );

                      // If directionEnabled, reset source name to 'Your location'
                      if (directionEnabled) {
                        ref.read(sourceLocationNameProvider.notifier).state =
                            'Your location';

                  

                        // Trigger route recalculation by refreshing the route provider
                        final destination = ref.read(
                          destinationLocationProvider,
                        );
                        if (destination != null) {
                          ref.invalidate(routesProvider);
                        }
                      }
                    } finally {
                      ref.read(isLoadingProvider.notifier).state = false;
                    }
                  },
                  error: (error, stackTrace) {
                    ref.read(isLoadingProvider.notifier).state = false;
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $error')));
                    }
                    if (kDebugMode) {
                      print('error current location...');
                    }
                  },
                  loading: () {
                    if (kDebugMode) {
                      print('Loading current location...');
                    }
                    ref.read(isLoadingProvider.notifier).state = true;
                  },
                );
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
