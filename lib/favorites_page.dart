import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'models/product.dart';
import 'l10n/app_strings.dart';
import 'widgets/app_back_button.dart';

class FavoritesPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const FavoritesPage({super.key, required this.onBrowseStores});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final CartManager _cartManager = CartManager();
  String _search = '';

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
            textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header (Branding)
                _buildHeader(),
                const SizedBox(height: 32),
                
                // Content Title and Back Button
                _buildSubHeader(isEmpty),
                
                const SizedBox(height: 24),
                
                if (!isEmpty) ...[
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.cairo(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: context.tr('search_favorites'),
                      hintStyle: GoogleFonts.cairo(color: Colors.white30),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E5BB3).withOpacity(0.12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(child: isEmpty ? _buildEmptyState() : _buildFavoritesList()),
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
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
          child: AppBackIconButton(
            onPressed: widget.onBrowseStores,
          ),
        ),
        Text(
          '${context.tr('nav_favorites')} (${_favoritesManager.count})',
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
    final visible = _favoritesManager.favorites.where((p) {
      if (_search.trim().isEmpty) return true;
      final q = _search.trim().toLowerCase();
      return context.tr(p.name).toLowerCase().contains(q) ||
          (p.code ?? '').toLowerCase().contains(q);
    }).toList();
    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final product = visible[index];
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
                  context.tr(p.name),
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.price}${context.tr('currency_suffix')}',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        _cartManager.addToCart(p);
                        // Show confirmation toast
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E5BB3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: Text(
                              context.tr('added_to_cart'),
                              style: GoogleFonts.cairo(color: Colors.white),
                              textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5BB3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_basket_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('move_to_cart'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    label: Text(
                      context.tr('remove'),
                      style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.normal),
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
          context.tr('favorites_empty'),
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('favorites_empty_sub'),
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
              context.tr('browse_stores'),
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

