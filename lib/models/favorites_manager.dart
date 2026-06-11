import 'package:flutter/material.dart';

import '../services/api/api_exception.dart';
import '../services/api/products_api.dart';
import '../services/api/wishlist_api.dart';
import 'auth_session.dart';
import 'cart_manager.dart';
import 'product.dart';

class FavoritesManager extends ChangeNotifier {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final WishlistApi _api = WishlistApi();
  final ProductsApi _productsApi = ProductsApi();
  final List<Product> _favorites = [];
  bool _loading = false;
  String? _error;

  List<Product> get favorites => List.unmodifiable(_favorites);
  int get count => _favorites.length;
  bool get isLoading => _loading;
  String? get error => _error;

  /// GET /api/wishlist
  Future<void> syncFromApi() async {
    if (!AuthSession.instance.isAuthenticated) {
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.fetchWishlist();
      _favorites
        ..clear()
        ..addAll(list);
      await _enrichMissingImages();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Product product) async {
    if (product.id != null && AuthSession.instance.isAuthenticated) {
      if (isFavorite(product)) {
        await _api.removeProduct(product.id!);
      } else {
        await _api.addProduct(product.id!);
      }
      await syncFromApi();
      return;
    }

    if (isFavorite(product)) {
      _favorites.removeWhere((p) => _sameProduct(p, product));
    } else {
      _favorites.add(product);
    }
    notifyListeners();
  }

  bool isFavorite(Product product) {
    return _favorites.any((p) => _sameProduct(p, product));
  }

  Future<void> remove(Product product) async {
    if (product.id != null && AuthSession.instance.isAuthenticated) {
      await _api.removeProduct(product.id!);
      await syncFromApi();
      return;
    }

    _favorites.removeWhere((p) => _sameProduct(p, product));
    notifyListeners();
  }

  /// POST /api/wishlist/{productId}/move-to-cart — body: variant_id
  Future<void> moveToCart({
    required Product product,
    required int variantId,
  }) async {
    if (product.id == null || product.id! <= 0) {
      throw ApiException('Product id is required.');
    }
    await _api.moveToCart(productId: product.id!, variantId: variantId);
    CartManager().cacheProductImage(product);
    await CartManager().syncFromApi();
    await syncFromApi();
  }

  bool _sameProduct(Product a, Product b) {
    if (a.id != null && b.id != null) return a.id == b.id;
    return a.name == b.name && a.storeName == b.storeName;
  }

  Future<void> _enrichMissingImages() async {
    for (var i = 0; i < _favorites.length; i++) {
      final product = _favorites[i];
      if (product.imageUrl.isNotEmpty || product.id == null) continue;
      try {
        final details = await _productsApi.fetchProductDetails(product.id!);
        if (details.imageUrl.isEmpty) continue;
        _favorites[i] = details.copyWith(
          storeName: product.storeName.isNotEmpty ? product.storeName : details.storeName,
          imageUrls: details.imageUrls.isNotEmpty ? details.imageUrls : product.imageUrls,
        );
      } on ApiException {
        // نُبقي المنتج بدون صورة.
      }
    }
  }
}
