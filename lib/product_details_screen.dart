import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/product.dart';
import 'models/favorites_manager.dart';
import 'models/cart_manager.dart';
import 'l10n/app_strings.dart';
import 'locale/app_locale.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final CartManager _cartManager = CartManager();
  String _selectedColor = 'black';
  String _selectedSize = 'M';
  int _quantity = 1;

  final List<String> _colors = ['black', 'navy', 'grey'];
  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Directionality(
            textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image and Back Button
                _buildProductImage(),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category/Rating Banner
                      _buildMainHeader(),
                      const SizedBox(height: 24),
                      
                      // Price Section
                      _buildPriceSection(),
                      const SizedBox(height: 32),
                      
                      // Description
                      _buildDescriptionBox(),
                      const SizedBox(height: 32),
                      
                      // Color Selection
                      _buildSelectionLabel(context.tr('color')),
                      const SizedBox(height: 16),
                      _buildColorSelector(),
                      const SizedBox(height: 32),
                      
                      // Size Selection
                      _buildSelectionLabel(context.tr('size')),
                      const SizedBox(height: 16),
                      _buildSizeSelector(),
                      const SizedBox(height: 32),
                      
                      // Quantity Selection
                      _buildSelectionLabel(context.tr('quantity')),
                      const SizedBox(height: 16),
                      _buildQuantitySelector(),
                      
                      const SizedBox(height: 48),
                      
                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Stack(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            image: DecorationImage(
              image: NetworkImage(widget.product.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Back Button
        Positioned(
          top: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(widget.product.name),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E5BB3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.tr(widget.product.category),
                      style: GoogleFonts.cairo(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.product.rating}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Text(
              '${widget.product.price}${context.tr('currency_suffix')}',
              style: GoogleFonts.cairo(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            if (widget.product.originalPrice != null) ...[
              const SizedBox(width: 16),
              Text(
                '${widget.product.originalPrice}${context.tr('currency_suffix')}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white24,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
            if (widget.product.discount != null && widget.product.discount!.isNotEmpty) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D1FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.product.discount} ${context.tr('sort_offers').split(' ')[0]}',
                  style: const TextStyle(color: Color(0xFF00D1FF), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.isOutOfStock ? context.tr('out_of_stock') : context.tr('available'),
          style: TextStyle(
            color: widget.product.isOutOfStock ? Colors.redAccent : Colors.greenAccent, 
            fontWeight: FontWeight.bold, 
            fontSize: 14
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        context.tr('product_description_placeholder'),
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: Colors.white70,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSelectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildColorSelector() {
    return Row(
      children: _colors.map((color) {
        bool isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            margin: EdgeInsets.only(left: context.isRtl ? 0 : 12, right: context.isRtl ? 12 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E5BB3) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
            ),
            child: Text(
              context.tr(color),
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector() {
    return Row(
      children: _sizes.map((size) {
        bool isSelected = _selectedSize == size;
        return GestureDetector(
          onTap: () => setState(() => _selectedSize = size),
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E5BB3) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
            ),
            child: Text(
              size,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white54, size: 20),
            onPressed: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_quantity',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blueAccent, size: 20),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    bool isFav = _favoritesManager.isFavorite(widget.product);
    
    return Row(
      children: [
        // Add to Cart Button (Now on the Right/Start of Row)
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: widget.product.isOutOfStock ? null : () {
                try {
                  _cartManager.addToCart(
                    widget.product,
                    color: _selectedColor,
                    size: _selectedSize,
                    quantity: _quantity,
                  );

                  // Show "تم إضافة المنتج للسلة" toast
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF1E5BB3).withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height - 100,
                        left: 20,
                        right: 20,
                      ),
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            context.tr('added_to_cart_msg'),
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  // Show error if from different store
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('nav_cart'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Favorite Button (Now on the Left/End of Row)
        GestureDetector(
          onTap: () {
            _favoritesManager.toggleFavorite(widget.product);
            
            if (_favoritesManager.isFavorite(widget.product)) {
              // Show "تم الإضافة للمفضلة" toast
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1E5BB3).withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height - 100,
                    left: 20,
                    right: 20,
                  ),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('added_to_fav'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFav ? const Color(0xFF1E5BB3) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isFav ? Colors.blueAccent : Colors.white10),
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
