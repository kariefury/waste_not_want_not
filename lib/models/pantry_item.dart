import 'package:uuid/uuid.dart';

/// Categories for pantry items — kept simple and icon-friendly.
enum FoodCategory {
  produce('Produce', '🥬'),
  dairy('Dairy', '🧀'),
  bakery('Bakery', '🍞'),
  canned('Canned', '🥫'),
  grains('Grains', '🌾'),
  frozen('Frozen', '🧊'),
  beverages('Beverages', '🥤'),
  snacks('Snacks', '🍪'),
  condiments('Condiments', '🫙'),
  other('Other', '📦');

  const FoodCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// A single food item being shared.
class PantryItem {
  PantryItem({
    String? id,
    required this.name,
    required this.category,
    required this.quantity,
    this.unit = '',
    this.notes = '',
    this.expiresBy,
    required this.contributorAlias,
    required this.pickupAddress,
    required this.pickupInstructions,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final FoodCategory category;
  final int quantity;
  final String unit;
  final String notes;
  final DateTime? expiresBy;
  final String contributorAlias;   // no real names required
  final String pickupAddress;
  final String pickupInstructions;
  final double latitude;
  final double longitude;
  final double radiusKm;           // how far this is visible
  final DateTime createdAt;

  /// Distance text for display — computed externally and attached.
  String? distanceLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'quantity': quantity,
        'unit': unit,
        'notes': notes,
        'expiresBy': expiresBy?.toIso8601String(),
        'contributorAlias': contributorAlias,
        'pickupAddress': pickupAddress,
        'pickupInstructions': pickupInstructions,
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
        id: json['id'],
        name: json['name'],
        category: FoodCategory.values[json['category']],
        quantity: json['quantity'],
        unit: json['unit'] ?? '',
        notes: json['notes'] ?? '',
        expiresBy: json['expiresBy'] != null
            ? DateTime.parse(json['expiresBy'])
            : null,
        contributorAlias: json['contributorAlias'],
        pickupAddress: json['pickupAddress'],
        pickupInstructions: json['pickupInstructions'] ?? '',
        latitude: json['latitude'],
        longitude: json['longitude'],
        radiusKm: (json['radiusKm'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// Items collected by the user for pickup.
class CartItem {
  CartItem({required this.pantryItem, this.claimedQuantity = 1});

  final PantryItem pantryItem;
  int claimedQuantity;
}

/// Grouped pickup summary for checkout.
class PickupStop {
  PickupStop({
    required this.address,
    required this.alias,
    required this.instructions,
    required this.items,
  });

  final String address;
  final String alias;
  final String instructions;
  final List<CartItem> items;
}
