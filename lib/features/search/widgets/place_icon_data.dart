import 'package:flutter/material.dart';

class PlaceIconData {
  static IconData getPlaceIcon(String? category) {
  if (category == null || category.isEmpty) return Icons.place;

  final type = category.split('.').last.toLowerCase();

  switch (type) {
    case 'restaurant':
    case 'cafe':
      return Icons.restaurant;
    case 'college':
    case 'school':
    case 'university':
      return Icons.school;
    case 'hospital':
      return Icons.local_hospital;
    case 'atm':
      return Icons.account_balance;
    case 'park':
    case 'tourism':
      return Icons.park;
    case 'hotel':
    case 'motel':
      return Icons.hotel;
    case 'shop':
    case 'shopping_mall':
      return Icons.store;
    case 'building':
      return Icons.business;
    default:
      return Icons.place; // fallback
  }
}
}