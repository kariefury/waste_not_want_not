import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pantry_item.dart';

/// On-device data layer.
///
/// Privacy architecture:
/// In production, replace with a privacy-preserving backend:
///   - Local mesh / peer-to-peer (BLE / Wi-Fi Direct)
///   - E2E-encrypted relay keyed by geohash prefix
///   - Onion-routed queries to decorrelate IPs from locations
///
/// This prototype simulates shared data on-device.
class LocalDataService {
  static const _contributionsKey = 'my_contributions';
  static const _sharedPantryKey  = 'shared_pantry';
  static const _aliasKey         = 'user_alias';

  static Future<String?> getAlias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_aliasKey);
  }

  static Future<void> setAlias(String alias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aliasKey, alias);
  }

  static Future<List<PantryItem>> getMyContributions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_contributionsKey) ?? [];
    return raw
        .map((s) => PantryItem.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> addContribution(PantryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_contributionsKey) ?? [];
    raw.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_contributionsKey, raw);

    final shared = prefs.getStringList(_sharedPantryKey) ?? [];
    shared.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_sharedPantryKey, shared);
  }

  static Future<void> removeContribution(String itemId) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getStringList(_contributionsKey) ?? [];
    raw.removeWhere((s) {
      final decoded = jsonDecode(s) as Map<String, dynamic>;
      return decoded['id'] == itemId;
    });
    await prefs.setStringList(_contributionsKey, raw);

    final shared = prefs.getStringList(_sharedPantryKey) ?? [];
    shared.removeWhere((s) {
      final decoded = jsonDecode(s) as Map<String, dynamic>;
      return decoded['id'] == itemId;
    });
    await prefs.setStringList(_sharedPantryKey, shared);
  }

  static Future<List<PantryItem>> getSharedPantry({
    double? userLat,
    double? userLng,
    double maxDistanceKm = 5.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_sharedPantryKey) ?? [];
    final items =
        raw.map((s) => PantryItem.fromJson(jsonDecode(s))).toList();

    if (userLat != null && userLng != null) {
      items.retainWhere((item) {
        final d = _distanceKm(userLat, userLng, item.latitude, item.longitude);
        item.distanceLabel = _distLabel(d);
        return d <= maxDistanceKm;
      });
      items.sort((a, b) {
        final dA = _distanceKm(userLat, userLng, a.latitude, a.longitude);
        final dB = _distanceKm(userLat, userLng, b.latitude, b.longitude);
        return dA.compareTo(dB);
      });
    }
    return items;
  }

  static Future<void> seedSampleData(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seeded') == true) return;

    final samples = _sampleItems(lat, lng);
    final shared = prefs.getStringList(_sharedPantryKey) ?? [];
    for (final item in samples) {
      shared.add(jsonEncode(item.toJson()));
    }
    await prefs.setStringList(_sharedPantryKey, shared);
    await prefs.setBool('seeded', true);
  }

  static double _distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  static String _distLabel(double km) {
    if (km < 0.2) return 'A short walk';
    if (km < 1) return '${(km * 1000).round()} m away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  static List<PantryItem> _sampleItems(double lat, double lng) {
    return [
      PantryItem(
        name: 'Organic bananas',
        category: FoodCategory.produce,
        quantity: 6,
        unit: 'bananas',
        notes: 'Slightly spotty — perfect for banana bread!',
        contributorAlias: 'Neighbour A',
        pickupAddress: '12 Elm Street',
        pickupInstructions: 'On the porch table',
        latitude: lat + 0.003,
        longitude: lng - 0.002,
        radiusKm: 3,
        expiresBy: DateTime.now().add(const Duration(days: 2)),
      ),
      PantryItem(
        name: 'Sourdough loaf',
        category: FoodCategory.bakery,
        quantity: 1,
        unit: 'loaf',
        notes: 'Baked this morning — too many loaves!',
        contributorAlias: 'Baker on 5th',
        pickupAddress: '5 Oak Avenue, side gate',
        pickupInstructions: 'Ring doorbell',
        latitude: lat - 0.004,
        longitude: lng + 0.003,
        radiusKm: 5,
      ),
      PantryItem(
        name: 'Canned chickpeas',
        category: FoodCategory.canned,
        quantity: 4,
        unit: 'cans',
        notes: 'Bought too many — still sealed.',
        contributorAlias: 'Pantry Pat',
        pickupAddress: '88 Maple Lane',
        pickupInstructions: 'Basket by front door',
        latitude: lat + 0.001,
        longitude: lng + 0.005,
        radiusKm: 2,
      ),
      PantryItem(
        name: 'Free-range eggs',
        category: FoodCategory.dairy,
        quantity: 12,
        unit: 'eggs',
        notes: 'Our hens are overachievers',
        contributorAlias: 'Sunny Coop',
        pickupAddress: '3 Birch Court',
        pickupInstructions: 'Come to the backyard gate',
        latitude: lat - 0.002,
        longitude: lng - 0.004,
        radiusKm: 3,
      ),
      PantryItem(
        name: 'Jasmine rice',
        category: FoodCategory.grains,
        quantity: 2,
        unit: 'kg',
        notes: 'Unopened bag, best before next month.',
        contributorAlias: 'Rice & Shine',
        pickupAddress: '41 Cedar Road',
        pickupInstructions: 'Leave a text when you arrive',
        latitude: lat + 0.005,
        longitude: lng + 0.001,
        radiusKm: 4,
      ),
      PantryItem(
        name: 'Homemade strawberry jam',
        category: FoodCategory.condiments,
        quantity: 3,
        unit: 'jars',
        notes: 'Made with local strawberries, sealed properly.',
        contributorAlias: 'Jam Lady',
        pickupAddress: '7 Willow Way',
        pickupInstructions: 'On the windowsill',
        latitude: lat - 0.003,
        longitude: lng + 0.002,
        radiusKm: 3,
      ),
    ];
  }
}
