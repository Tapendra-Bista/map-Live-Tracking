import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../search/screen/address_search_screen.dart';
import '../provider/map_provider.dart';

class SearchBarWidget extends ConsumerWidget {
  final Completer<GoogleMapController> mapController;
  final bool directionEnabled;
  final bool showBottomSheet;
  final String placeName;
  final String sourceLocationName;

  const SearchBarWidget({
    super.key,
    required this.mapController,
    required this.directionEnabled,
    required this.showBottomSheet,
    required this.placeName,
    required this.sourceLocationName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: 40,
      left: 25,
      right: 25,
      child: InkWell(
        onTap: directionEnabled
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddressSearchScreen(
                      mapController: mapController,
                      isChangingSource: false,
                    ),
                  ),
                );
              },
        child: Container(
          height: directionEnabled ? 100 : 45,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(directionEnabled ? 12 : 32),
          ),
          child: showBottomSheet
              ? directionEnabled
                    ? _DirectionSearchContent(
                        mapController: mapController,
                        sourceLocationName: sourceLocationName,
                        placeName: placeName,
                      )
                    : _SimpleSearchContent(placeName: placeName)
              : _DefaultSearchContent(),
        ),
      ),
    );
  }
}

class _DirectionSearchContent extends StatelessWidget {
  final Completer<GoogleMapController> mapController;
  final String sourceLocationName;
  final String placeName;

  const _DirectionSearchContent({
    required this.mapController,
    required this.sourceLocationName,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddressSearchScreen(
                  mapController: mapController,
                  isChangingSource: true,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 15,
            children: [
              Container(
                width: 16,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  sourceLocationName,
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 15,
          children: [
            const Icon(Icons.more_vert, color: Colors.grey, size: 16),
            Divider(
              radius: BorderRadius.circular(20),
              thickness: 1,
              color: Colors.grey,
            ),
          ],
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddressSearchScreen(
                  mapController: mapController,
                  isChangingSource: false,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 15,
            children: [
              const Icon(Icons.location_pin, color: Colors.red, size: 16),
              Text(
                placeName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleSearchContent extends ConsumerWidget {
  final String placeName;

  const _SimpleSearchContent({required this.placeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(placeName, maxLines: 1, overflow: TextOverflow.ellipsis),
        IconButton(
          onPressed: () {
            ref.read(showBottomSheetProvider.notifier).state = false;
            ref.read(markersProvider.notifier).state = {};
          },
          icon: Icon(Icons.close, color: Colors.black.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _DefaultSearchContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 10,
      children: [
        Image.asset('assets/map_logo.png', height: 25, width: 25),
        Text(
          'Search here',
          style: TextStyle(
            fontSize: 17,
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
