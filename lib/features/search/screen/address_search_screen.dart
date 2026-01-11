import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/features/home/provider/map_provider.dart';
import 'package:map/features/search/widgets/place_icon_data.dart'; // Ensure this contains your updated providers

class AddressSearchScreen extends ConsumerStatefulWidget {
  const AddressSearchScreen({
    super.key,
    required this.mapController,
    this.isChangingSource = false,
  });
  final Completer<GoogleMapController> mapController;
  final bool isChangingSource;

  @override
  ConsumerState<AddressSearchScreen> createState() =>
      _AddressSearchScreenState();
}

class _AddressSearchScreenState extends ConsumerState<AddressSearchScreen> {
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  // Debouncer logic: waits for user to stop typing for 500ms before calling API
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(userInputStateProvider.notifier).state = query;
      ref.read(autoCompleteResultsProvider.future);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autocompleteResults = ref.watch(autoCompleteResultsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: .circular(32),
          ),
          child: TextField(
            controller: searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search here',
              hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
              prefixIcon: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        ref.read(userInputStateProvider.notifier).state = "";
                      },
                      icon: const Icon(
                        CupertinoIcons.clear_circled,
                        color: Colors.black54,
                      ),
                    ),
              border: .none,
              contentPadding: const .symmetric(vertical: 10),
            ),
          ),
        ),
      ),

      body: autocompleteResults.when(
        data: (results) {
          if (kDebugMode) {
            print('Results received: ${results.length} items');
            print('Results type: ${results.runtimeType}');
            if (results.isNotEmpty) {
              print('First result: ${results[0]}');
            }
          }

          if (results.isEmpty) {
            return const Center(child: Text("Search for your destination"));
          }
          return ListView.builder(
            padding: .symmetric(vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final String category = result["category"] ?? "";
              final String name = result["name"] ?? "Unknown";
              final String street = result["street"] ?? "";
              final String district = result["district"] ?? "";
              final String postcode = result["postcode"] ?? "";
              final String city = result["city"] ?? "";
              final String country = result["country"] ?? "";
              final String description =
                  "$name, $street, $district, $city $postcode, $country";
              final lat = result["lat"];

              final lon = result["lon"];
              return ListTile(
                leading: Icon(
                  PlaceIconData.getPlaceIcon(category),
                  color: Colors.grey,
                  size: 25,
                ),
                title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  description,
                  style: const TextStyle(fontSize: 10),
                ),
                onTap: () async {
                  final BuildContext dialogContext = this.context;

                  // If changing source location
                  if (widget.isChangingSource) {
                    // Set the new source location
                    ref.read(sourceLocationProvider.notifier).state = LatLng(
                      lat,
                      lon,
                    );

                    // Save the source location name
                    ref.read(sourceLocationNameProvider.notifier).state = name;

                    // Get the existing destination
                    final destinationLocation = ref.read(
                      destinationLocationProvider,
                    );

                    if (destinationLocation == null) {
                      if (kDebugMode) {
                        print('ERROR: Destination location is null!');
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Destination not set'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }

                    if (kDebugMode) {
                      print('=== Changing Source Location ===');
                      print('New Source: $lat, $lon');
                      print(
                        'Existing Destination: ${destinationLocation.latitude}, ${destinationLocation.longitude}',
                      );
                    }

                    // Keep the destination marker
                    ref.read(markersProvider.notifier).state = {
                      Marker(
                        markerId: const MarkerId('TargetLocation'),
                        position: destinationLocation,
                      ),
                    };
                  } else {
                    // Changing destination - original behavior
                    // Check if source location is set
                    final sourceLocation = ref.read(sourceLocationProvider);
                    if (sourceLocation == null) {
                      if (kDebugMode) {
                        print(
                          'ERROR: Source location is null! Please get your current location first.',
                        );
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please get your current location first',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }

                    if (kDebugMode) {
                      print('=== Starting Route Request ===');
                      print(
                        'Source: ${sourceLocation.latitude}, ${sourceLocation.longitude}',
                      );
                      print('Destination: $lat, $lon');
                    }

                    // Set destination location
                    ref.read(destinationLocationProvider.notifier).state =
                        LatLng(lat, lon);

                    // Set destination marker
                    ref.read(markersProvider.notifier).state = {
                      Marker(
                        markerId: const MarkerId('TargetLocation'),
                        position: LatLng(lat, lon),
                      ),
                    };

                    // Update place name
                    ref.read(placeNameProvider.notifier).state = name;
                    ref.read(streetAddressProvider.notifier).state = street;
                  }

                  try {
                    // Fetch route data
                    final routeData = await ref.read(routesProvider.future);

                    if (kDebugMode) {
                      print('Route response received: ${routeData != null}');
                    }

                    if (routeData != null) {
                      final coordinates =
                          routeData['geometry']['coordinates'][0] as List;
                      ref.read(coordinatesProvider.notifier).state =
                          coordinates;

                      // Set distance and duration
                      ref.read(distanceProvider.notifier).state =
                          routeData['properties']['distance'].toString();
                      ref.read(durationProvider.notifier).state =
                          routeData['properties']['time'].toString();
                    } else {
                      if (kDebugMode) {
                        print('✗ Route data is null - Check API response');
                      }
                      // Show error to user
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No route found. Try a different location or mode.',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } catch (e, stackTrace) {
                    if (kDebugMode) {
                      print('✗ Error fetching route: $e');
                      print('Stack trace: $stackTrace');
                    }
                  }

                  // Animate camera to the selected location
                  final controller = await widget.mapController.future;
                  await controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: LatLng(lat, lon), zoom: 15),
                    ),
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    // Trigger bottom sheet on MapScreen after pop
                    ref.read(showBottomSheetProvider.notifier).state = true;
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
