import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/features/home/provider/map_provider.dart';
import 'package:map/features/home/widgets/map_types_screen.dart';

import '../widgets/arrival_dialog.dart';
import '../widgets/current_location_button.dart';
import '../widgets/navigation_details.dart';
import '../widgets/routes_details.dart';
import '../widgets/search_bar_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  @override
  Widget build(BuildContext context) {
    ref.watch(isLoadingProvider);
    final mapType = ref.watch(mapTypeProvider);
    ref.watch(currentLocationProvider);
    final markers = ref.watch(markersProvider);
    final polylines = ref.watch(polylinePointsProvider);
    final showBottomSheet = ref.watch(showBottomSheetProvider);
    final placeName = ref.watch(placeNameProvider);
    final directionEnabled = ref.watch(directionEnabledProvider);
    final sourceLocationName = ref.watch(sourceLocationNameProvider);
    final startNavigation = ref.watch(startNavigationProvider);
    final hasArrived = ref.watch(hasArrivedProvider);
    final locationPermissionGranted = ref.watch(
      locationPermissionGrantedProvider,
    );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            polylines: polylines ?? {},
            markers: markers,
            myLocationEnabled: locationPermissionGranted,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapType: mapType,
            onMapCreated: (controller) => _mapController.complete(controller),
            zoomControlsEnabled: false,
            initialCameraPosition: const CameraPosition(
              // kathmandu lat long
              target: LatLng(27.7172, 85.3240),
              zoom: 15,
            ),
          ),

          // Search BAR
          if (!startNavigation)
            SearchBarWidget(
              mapController: _mapController,
              directionEnabled: directionEnabled,
              showBottomSheet: showBottomSheet,
              placeName: placeName,
              sourceLocationName: sourceLocationName,
            ),

          // CURRENT LOCATION BUTTON
          CurrentLocationButton(
            mapController: _mapController,
            showBottomSheet: showBottomSheet,
          ),

          // change map type button
          if (!startNavigation)
            Positioned(
              top: 150,
              right: 10,
              child: FloatingActionButton(
                heroTag: 'mapTypeBtn',
                onPressed: () => showModalBottomSheet(
                  backgroundColor: Colors.white,
                  useSafeArea: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: .only(
                      topLeft: .circular(12),
                      topRight: .circular(12),
                    ),
                  ),
                  context: context,
                  builder: (context) => MapTypesScreen(),
                ),
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.layers,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),

          // Route Details Bottom Sheet
          if (showBottomSheet && !startNavigation)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RoutesDetails(mapController: _mapController.future),
            ),

          // Navigation Details Panel
          if (startNavigation && !hasArrived)
            NavigationDetails(mapController: _mapController.future),

          // Arrival Message
          if (hasArrived)
            ArrivalDialog(mapController: _mapController, placeName: placeName),
        ],
      ),
    );
  }
}
