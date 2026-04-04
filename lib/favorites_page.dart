import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'models/product.dart';

class FavoritesPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const FavoritesPage({super.key, required this.onBrowseStores});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final CartManager _cartManager = CartManager();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _favoritesManager,
      builder: (context, _) {
        bool isEmpty = _favoritesManager.count == 0;

        return Container(
          color: const Color(0xFF0A1931),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header (Branding)
                _buildHeader(),
                const SizedBox(height: 32),
                
                // Content Title and Back Button
                _buildSubHeader(isEmpty),
                
                const SizedBox(height: 24),
                
                Expanded(
                  child: isEmpty ? _buildEmptyState() : _buildFavoritesList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E5BB3).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trendy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.checkroom_rounded, color: Colors.blueAccent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(bool isEmpty) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: widget.onBrowseStores,
          icon: const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
          label: const Text(
            'رجوع',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        Text(
          'المفضلة (${_favoritesManager.count})',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      itemCount: _favoritesManager.count,
      itemBuilder: (context, index) {
        final product = _favoritesManager.favorites[index];
        return _buildFavoriteCard(product);
      },
    );
  }

  Widget _buildFavoriteCard(Product p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              p.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.price} د.ل',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Transfer to Cart Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5BB3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ).child(
                    onPressed: () {
                      try {
                        _cartManager.addToCart(p);
                        // Show confirmation toast
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E5BB3),
                            content: Text(
                              'تم نقل المنتج للسلة',
                              style: GoogleFonts.cairo(color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      } catch (e) {
                        // Error if from different store
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.redAccent,
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                              style: GoogleFonts.cairo(color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('نقل للسلة', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Remove Link
                Center(
                  child: TextButton.icon(
                    onPressed: () => _favoritesManager.remove(p),
                    icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 18),
                    label: const Text(
                      'إزالة',
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.normal),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.favorite_border_rounded,
          size: 100,
          color: Colors.white.withOpacity(0.6),
        ),
        const SizedBox(height: 32),
        Text(
          'قائمة المفضلة فارغة',
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ابدأ بإضافة المنتجات التي تعجبك إلى المفضلة',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 140,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onBrowseStores,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5BB3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'تصفح المتاجر',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

extension ElevatedButtonExtension on ButtonStyle {
  Widget child({required VoidCallback onPressed, required Widget child}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: this,
      child: child,
    );
  }
}
