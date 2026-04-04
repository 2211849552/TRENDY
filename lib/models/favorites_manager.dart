import 'package:flutter/material.dart';
import 'product.dart';

class FavoritesManager extends ChangeNotifier {
  // Singleton Pattern
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final List<Product> _favorites = [];

  List<Product> get favorites => List.unmodifiable(_favorites);

  int get count => _favorites.length;

  void toggleFavorite(Product product) {
    if (isFavorite(product)) {
      _favorites.removeWhere((p) => p.name == product.name);
    } else {
      _favorites.add(product);
    }
    notifyListeners();
  }

  bool isFavorite(Product product) {
    return _favorites.any((p) => p.name == product.name);
  }

  void remove(Product product) {
    _favorites.removeWhere((p) => p.name == product.name);
    notifyListeners();
  }
}
