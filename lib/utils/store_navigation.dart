import 'package:flutter/material.dart';

import '../data/store_catalog.dart';
import '../models/ratings_manager.dart';
import '../services/location_service.dart';
import '../services/store_location.dart';
import '../store_details_screen.dart';

class StoreNavigation {
  StoreNavigation._();

  static void open(
    BuildContext context, {
    required String storeKey,
    double? userLat,
    double? userLng,
  }) {
    final store = StoreCatalog.findByKey(storeKey);
    if (store == null) return;

    var distText = '--';
    final loc = store['location'] as StoreLocation?;
    if (userLat != null && userLng != null && loc != null) {
      final km = const LocationService().distanceKm(
        fromLat: userLat,
        fromLng: userLng,
        toLat: loc.lat,
        toLng: loc.lng,
      );
      distText = km.toStringAsFixed(1);
    }

    final baseRating = (store['rating'] as num).toDouble();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailsScreen(
          storeName: store['name'] as String,
          storeCategory: store['category'] as String,
          storeRating: RatingsManager().storeRatingOrBase(
            store['name'].toString(),
            baseRating,
          ),
          storeDistance: distText,
          storeImageUrl: store['imageUrl'] as String,
          storeDiscount: store['discount'] as String?,
          storeLocation: loc,
        ),
      ),
    );
  }
}
