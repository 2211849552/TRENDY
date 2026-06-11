import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'models/product.dart';
import 'models/auth_session.dart';
import 'l10n/app_strings.dart';
import 'services/api/api_exception.dart';
import 'services/api/products_api.dart';
import 'theme/app_theme_mode.dart';
import 'theme/trendy_theme_extension.dart';
import 'widgets/app_back_button.dart';
import 'widgets/store_cover_image.dart';
import 'widgets/gradient_button.dart';
import 'widgets/trendy_brand.dart';
import 'widgets/variant_picker_sheet.dart';

class FavoritesPage extends StatefulWidget {
  final VoidCallback onBrowseStores;

  const FavoritesPage({super.key, required this.onBrowseStores});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final CartManager _cartManager = CartManager();
  final ProductsApi _productsApi = ProductsApi();
  String _search = '';
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    _favoritesManager.syncFromApi();
  }

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
    return const Center(
      child: TrendyBrandBadge(
        textSize: 24,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 12,
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
    const imageHeight = 280.0;

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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              height: imageHeight,
              width: double.infinity,
              color: t.inputFill,
              alignment: Alignment.center,
              child: StoreCoverImage(
                imageUrl: p.imageUrl,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
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
                    onPressed: _moving ? null : () => _moveFavoriteToCart(context, p),
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

  Future<void> _moveFavoriteToCart(BuildContext context, Product product) async {
    if (!AuthSession.instance.isAuthenticated) {
      _showSnack(context, context.tr('cart_login_prompt'), isError: true);
      return;
    }
    if (product.id == null || product.id! <= 0) {
      try {
        await _cartManager.addToCart(product);
        _showSnack(context, context.tr('added_to_cart'));
      } on CartSingleStoreException {
        _showSnack(context, context.tr('cart_single_store_error'), isError: true);
      }
      return;
    }

    setState(() => _moving = true);
    try {
      final variants = await _productsApi.fetchProductVariants(product.id!);
      if (!mounted) return;
      if (variants.isEmpty) {
        _showSnack(context, context.tr('out_of_stock'), isError: true);
        return;
      }

      final picked = await VariantPickerSheet.show(
        context,
        productName: product.name,
        variants: variants,
      );
      if (picked == null || !mounted) return;

      await _favoritesManager.moveToCart(product: product, variantId: picked.id);
      if (!mounted) return;
      _showSnack(context, context.tr('added_to_cart'));
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(context, e.message, isError: true);
    } on CartSingleStoreException {
      if (!mounted) return;
      _showSnack(context, context.tr('cart_single_store_error'), isError: true);
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFA855F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white),
          textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
        ),
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

