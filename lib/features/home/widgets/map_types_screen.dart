import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/features/home/provider/map_provider.dart';
import 'package:map/features/home/widgets/map_types_item.dart';

class MapTypesScreen extends ConsumerWidget {
  @Preview(name: 'Map Types Screen Preview')
  const MapTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapType = ref.watch(mapTypeProvider);
    return Padding(
      padding: .all(8),
      child: Column(
        mainAxisSize: .min,
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        spacing: 20,
        children: [
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
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text('Map Types', style: .new(fontSize: 18, fontWeight: .bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  ref.read(mapTypeProvider.notifier).state = MapType.normal;
                  Navigator.pop(context);
                },
                child: MapTypesItem(
                  mapType: 'Default',
                  imagePath: 'assets/default.png',
                  isSelected: mapType == MapType.normal ? true : false,
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(mapTypeProvider.notifier).state = MapType.satellite;
                  Navigator.pop(context);
                },
                child: MapTypesItem(
                  mapType: 'Satellite',
                  imagePath: 'assets/satellite.png',
                  isSelected: mapType == MapType.satellite ? true : false,
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(mapTypeProvider.notifier).state = MapType.terrain;
                  Navigator.pop(context);
                },
                child: MapTypesItem(
                  mapType: 'Terrain',
                  imagePath: 'assets/terrain.png',
                  isSelected: mapType == MapType.terrain ? true : false,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
