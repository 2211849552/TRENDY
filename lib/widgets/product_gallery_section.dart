import 'package:flutter/material.dart';

import '../data/product_images.dart';
import '../theme/trendy_theme_extension.dart';
import 'product_image_viewer.dart';
import 'store_cover_image.dart';

/// معرض صور المنتج — مصغّرات على الجانب + صورة رئيسية كبيرة مع أسهم تنقّل.
class ProductGallerySection extends StatefulWidget {
  final String imageUrl;
  final List<String> imageUrls;
  final String productKey;
  final String? storeName;

  const ProductGallerySection({
    super.key,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.productKey,
    this.storeName,
  });

  @override
  State<ProductGallerySection> createState() => _ProductGallerySectionState();
}

class _ProductGallerySectionState extends State<ProductGallerySection> {
  int _selectedIndex = 0;

  List<String> get _displayUrls {
    if (widget.imageUrls.isNotEmpty) return widget.imageUrls;
    if (widget.imageUrl.trim().isNotEmpty) return [widget.imageUrl];
    return [ProductImages.forProductKey(widget.productKey)];
  }

  bool get _usesRemoteGallery =>
      _displayUrls.any((url) => StoreCoverImage.isRemoteUrl(url));

  @override
  void didUpdateWidget(covariant ProductGallerySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageUrls != widget.imageUrls) {
      _selectedIndex = 0;
    }
  }

  void _selectIndex(int index) {
    final urls = _displayUrls;
    if (index < 0 || index >= urls.length) return;
    setState(() => _selectedIndex = index);
  }

  void _next() => _selectIndex((_selectedIndex + 1) % _displayUrls.length);

  void _previous() {
    final len = _displayUrls.length;
    _selectIndex((_selectedIndex - 1 + len) % len);
  }

  @override
  Widget build(BuildContext context) {
    final urls = _displayUrls;
    if (_selectedIndex >= urls.length) _selectedIndex = 0;

    final showFull = _usesRemoteGallery
        ? true
        : ProductImages.showsFullPhoto(widget.productKey, storeName: widget.storeName);
    final galleryHeight = MediaQuery.sizeOf(context).height * (showFull ? 0.52 : 0.42);
    final photoBg = showFull ? context.trendy.inputFill : const Color(0xFF1E1B2E);
    const thumbSize = 56.0;
    final currentUrl = urls[_selectedIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: galleryHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (urls.length > 1) ...[
              SizedBox(
                width: thumbSize + 4,
                child: ListView.separated(
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () => _selectIndex(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? Colors.black : Colors.black26,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: StoreCoverImage(
                          key: ValueKey('thumb_${index}_${urls[index]}'),
                          imageUrl: urls[index],
                          fit: BoxFit.cover,
                          width: thumbSize,
                          height: thumbSize,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  color: photoBg,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        onTap: () => ProductImageViewer.showGallery(
                          context,
                          imageUrls: urls,
                          initialIndex: _selectedIndex,
                        ),
                        child: StoreCoverImage(
                          key: ValueKey('main_$currentUrl'),
                          imageUrl: currentUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: galleryHeight,
                        ),
                      ),
                      if (urls.length > 1) ...[
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _GalleryArrowButton(
                              icon: Icons.chevron_left,
                              onTap: _previous,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _GalleryArrowButton(
                              icon: Icons.chevron_right,
                              onTap: _next,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Text(
                            '${_selectedIndex + 1} / ${urls.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryArrowButton extends StatelessWidget {
  const _GalleryArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(icon, color: Colors.black87, size: 28),
          ),
        ),
      ),
    );
  }
}
