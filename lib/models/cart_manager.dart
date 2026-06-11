import 'package:flutter/material.dart';

import '../services/api/api_exception.dart';
import '../services/api/cart_api.dart';
import '../services/product_line_enricher.dart';
import 'auth_session.dart';
import 'cart_item.dart';
import 'product.dart';

class _PendingVariantMeta {
  const _PendingVariantMeta({
    required this.productName,
    required this.color,
    required this.size,
    this.variantId,
  });

  final String productName;
  final String color;
  final String size;
  final int? variantId;
}

/// يُرمى عند محاولة إضافة منتج من متجر مختلف عن منتجات السلة الحالية.
class CartSingleStoreException implements Exception {
  const CartSingleStoreException();
}

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final CartApi _api = CartApi();
  final ProductLineEnricher _enricher = ProductLineEnricher();
  final List<CartItem> _items = [];
  final Map<int, String> _imageByProductId = {};
  final Map<String, String> _imageByProductName = {};
  final Map<String, int> _productIdByName = {};
  final Map<int, _PendingVariantMeta> _metaByApiItemId = {};
  final List<_PendingVariantMeta> _pendingVariantMeta = [];
  bool _loading = false;
  String? _error;
  double _deliveryFee = 0;
  bool _usesApi = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  String? get error => _error;
  double get deliveryFee => _deliveryFee;
  bool get usesApi => _usesApi;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  String? get currentStoreKey =>
      _items.isEmpty ? null : _items.first.product.storeName;

  /// GET /api/cart
  Future<void> syncFromApi() async {
    if (!AuthSession.instance.isAuthenticated) {
      _usesApi = false;
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final contents = await _api.fetchCart();
      _items
        ..clear()
        ..addAll(contents.items);
      _deliveryFee = contents.summary.deliveryFee;
      _usesApi = true;
      _applyImageCache();
      _applyPendingVariantMeta();
      await _enrichCartLines();
    } on ApiException catch (e) {
      _error = e.message;
      _usesApi = false;
    } catch (e) {
      _error = e.toString();
      _usesApi = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(
    Product product, {
    String color = 'أسود',
    String size = 'M',
    int quantity = 1,
    int? variantId,
  }) async {
    _rememberProductImage(product);

    if (AuthSession.instance.isAuthenticated && variantId != null) {
      _pendingVariantMeta.add(
        _PendingVariantMeta(
          productName: product.name,
          color: color,
          size: size,
          variantId: variantId,
        ),
      );
      await _api.addItem(variantId: variantId, quantity: quantity);
      await syncFromApi();
      return;
    }

    final index = _items.indexWhere(
      (item) =>
          item.product.name == product.name &&
          item.selectedColor == color &&
          item.selectedSize == size,
    );

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      if (_items.isNotEmpty && _items.first.product.storeName != product.storeName) {
        throw const CartSingleStoreException();
      }
      _items.add(
        CartItem(
          product: product,
          selectedColor: color,
          selectedSize: size,
          quantity: quantity,
          variantId: variantId,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> updateQuantity(CartItem item, int delta) async {
    _error = null;
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      await removeFromCart(item);
      return;
    }

    final maxStock = item.availableStock;
    if (maxStock != null && maxStock > 0 && newQty > maxStock) {
      _error = 'max_quantity_reached';
      notifyListeners();
      return;
    }

    if (_usesApi && item.apiItemId != null) {
      await _api.updateItem(itemId: item.apiItemId!, quantity: newQty);
      await syncFromApi();
      return;
    }

    item.quantity = newQty;
    notifyListeners();
  }

  Future<void> updateAttributes(CartItem item, {String? color, String? size}) async {
    final newColor = (color != null && color.isNotEmpty) ? color : item.selectedColor;
    final newSize = (size != null && size.isNotEmpty) ? size : item.selectedSize;
    if (newColor == item.selectedColor && newSize == item.selectedSize) return;

    if (_usesApi) {
      _error = 'cart_edit_variant_not_supported';
      notifyListeners();
      return;
    }

    final duplicateIndex = _items.indexWhere(
      (i) =>
          i != item &&
          i.product.name == item.product.name &&
          i.selectedColor == newColor &&
          i.selectedSize == newSize,
    );

    if (duplicateIndex >= 0) {
      _items[duplicateIndex].quantity += item.quantity;
      _items.remove(item);
    } else {
      item.selectedColor = newColor;
      item.selectedSize = newSize;
    }
    notifyListeners();
  }

  Future<void> removeFromCart(CartItem item) async {
    if (_usesApi && item.apiItemId != null) {
      await _api.removeItem(item.apiItemId!);
      await syncFromApi();
      return;
    }

    _items.remove(item);
    notifyListeners();
  }

  Future<void> clearCart() async {
    if (_usesApi) {
      for (final item in List<CartItem>.from(_items)) {
        if (item.apiItemId != null) {
          await _api.removeItem(item.apiItemId!);
        }
      }
      await syncFromApi();
      return;
    }

    _items.clear();
    notifyListeners();
  }

  /// يحفظ صورة المنتج محلياً — GET /api/cart لا يُرجع صوراً.
  void cacheProductImage(Product product) => _rememberProductImage(product);

  void _rememberProductImage(Product product) {
    if (product.id != null && product.name.isNotEmpty) {
      _productIdByName[product.name] = product.id!;
    }
    if (product.imageUrl.isEmpty) return;
    if (product.id != null) _imageByProductId[product.id!] = product.imageUrl;
    if (product.name.isNotEmpty) _imageByProductName[product.name] = product.imageUrl;
  }

  void _applyImageCache() {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.product.imageUrl.isNotEmpty) continue;

      final byId = item.product.id != null ? _imageByProductId[item.product.id!] : null;
      final cached = byId ?? _imageByProductName[item.product.name];
      if (cached == null || cached.isEmpty) continue;

      _items[i] = CartItem(
        product: item.product.copyWith(imageUrl: cached),
        selectedColor: item.selectedColor,
        selectedSize: item.selectedSize,
        quantity: item.quantity,
        variantId: item.variantId,
        apiItemId: item.apiItemId,
        availableStock: item.availableStock,
      );
    }
  }

  void _applyPendingVariantMeta() {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final apiId = item.apiItemId;
      if (apiId != null && _metaByApiItemId.containsKey(apiId)) {
        final meta = _metaByApiItemId[apiId]!;
        _items[i] = CartItem(
          product: item.product,
          selectedColor: item.selectedColor.isNotEmpty ? item.selectedColor : meta.color,
          selectedSize: item.selectedSize.isNotEmpty ? item.selectedSize : meta.size,
          quantity: item.quantity,
          variantId: item.variantId ?? meta.variantId,
          apiItemId: item.apiItemId,
          availableStock: item.availableStock,
        );
        continue;
      }

      if (item.selectedColor.isNotEmpty && item.selectedSize.isNotEmpty) continue;

      final name = item.product.name.trim();
      final queueIndex = _pendingVariantMeta.indexWhere((m) => m.productName.trim() == name);
      if (queueIndex < 0) continue;

      final meta = _pendingVariantMeta.removeAt(queueIndex);
      if (apiId != null) _metaByApiItemId[apiId] = meta;

      _items[i] = CartItem(
        product: item.product,
        selectedColor: item.selectedColor.isNotEmpty ? item.selectedColor : meta.color,
        selectedSize: item.selectedSize.isNotEmpty ? item.selectedSize : meta.size,
        quantity: item.quantity,
        variantId: item.variantId ?? meta.variantId,
        apiItemId: item.apiItemId,
        availableStock: item.availableStock,
      );
    }
  }

  Future<void> _enrichCartLines() async {
    if (_items.isEmpty) return;

    for (var i = 0; i < _items.length; i++) {
      try {
        final enriched = await _enricher.enrichLine(_items[i]);
        _items[i] = enriched;
        if (enriched.product.imageUrl.isNotEmpty) {
          _rememberProductImage(enriched.product);
        }
      } on ApiException {
        // نُبقي العنصر كما هو.
      }
    }
  }
}
