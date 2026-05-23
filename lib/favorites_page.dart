import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'models/product.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme_mode.dart';
import 'theme/trendy_theme_extension.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';
import 'widgets/gradient_button.dart';

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
      listenable: Listenable.merge([_favoritesManager, AppThemeMode.instance]),
      builder: (context, _) {
        bool isEmpty = _favoritesManager.count == 0;

        return Container(
          color: context.trendy.pageBackground,
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
                    style: GoogleFonts.cairo(color: context.trendy.titleColor),
                    decoration: InputDecoration(
                      hintText: context.tr('search_favorites'),
                      hintStyle: GoogleFonts.cairo(color: context.trendy.hintColor),
                      prefixIcon: Icon(Icons.search, color: context.trendy.subtitleColor),
                      filled: true,
                      fillColor: context.trendy.inputFill,
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
          color: const Color(0xFFA855F7).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trendy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.trendy.titleColor,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.checkroom_rounded, color: Color(0xFF3B82F6), size: 24),
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
            color: context.trendy.titleColor,
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
    final t = context.trendy;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: StoreCoverImage(
              imageUrl: p.imageUrl,
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
                    color: t.titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.price}${context.tr('currency_suffix')}',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: const Color(0xFF3B82F6),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFFA855F7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: Text(
                              context.tr('added_to_cart'),
                              style: GoogleFonts.cairo(color: Colors.white),
                              textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
                            ),
                          ),
                        );
                      } on CartSingleStoreException {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.redAccent,
                            content: Text(
                              context.tr('cart_single_store_error'),
                              style: GoogleFonts.cairo(color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7),
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
                    icon: Icon(Icons.delete_outline, color: t.subtitleColor, size: 18),
                    label: Text(
                      context.tr('remove'),
                      style: TextStyle(color: t.subtitleColor, fontWeight: FontWeight.normal),
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
    final t = context.trendy;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.favorite_border_rounded,
          size: 100,
          color: t.subtitleColor.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 32),
        Text(
          context.tr('favorites_empty'),
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: t.titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('favorites_empty_sub'),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: t.subtitleColor,
          ),
        ),
        const SizedBox(height: 40),
        GradientButton(
          onPressed: widget.onBrowseStores,
          label: context.tr('browse_stores'),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
      ],
    );
  }
}

