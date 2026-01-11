import 'package:flutter/material.dart';

class MapTypesItem extends StatelessWidget {
  const MapTypesItem({
    super.key,
    required this.mapType,
    required this.imagePath,
    required this.isSelected,
  });
  final String mapType;
  final String imagePath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      spacing: 5,
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: .circular(8),
            border: isSelected
                ? Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                    width: 2,
                  )
                : null,
          ),
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
        Text(mapType, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
