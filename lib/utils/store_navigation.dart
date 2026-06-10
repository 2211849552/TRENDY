import 'package:flutter/material.dart';

import '../data/store_catalog.dart';
import '../data/store_delivery.dart';
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
    Map<String, dynamic>? storeData,
  }) {
    final store = storeData ?? StoreCatalog.findByKey(storeKey);
    if (store == null) return;

    var distText = '--';
    double? liveKm;
    final loc = store['location'] as StoreLocation?;
    if (userLat != null && userLng != null && loc != null) {
      liveKm = const LocationService().distanceKm(
        fromLat: userLat,
        fromLng: userLng,
        toLat: loc.lat,
        toLng: loc.lng,
      );
      distText = liveKm.toStringAsFixed(1);
    }

    final baseRating = (store['rating'] as num).toDouble();
    final deliveryFee = StoreDelivery.feeFor(
      store,
      distanceKm: liveKm ?? (store['displayDistanceKm'] as num?)?.toDouble(),
    );

    final resolvedKey = store['name'] as String;
    final displayName = store['displayName'] as String?;
    final category = store['category'] as String? ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailsScreen(
          storeName: resolvedKey,
          storeDisplayName: displayName,
          storeId: int.tryParse('${store['id'] ?? ''}'),
          storeCategory: category,
          storeRating: RatingsManager().storeRatingOrBase(
            resolvedKey,
            baseRating,
          ),
          storeDistance: distText,
          storeImageUrl: '${store['imageUrl'] ?? ''}',
          storeDiscount: store['discount'] as String?,
          storeLocation: loc,
          storeMapUrl: store['googleMapUrl'] as String?,
          isElectronic: store['isElectronic'] as bool? ?? false,
          deliveryFee: deliveryFee,
        ),
      ),
    );
  }
}
