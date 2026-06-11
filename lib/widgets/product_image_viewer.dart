import 'package:flutter/material.dart';

import 'store_cover_image.dart';

/// عرض صورة أو معرض صور المنتج كاملة مع تكبير.
class ProductImageViewer {
  ProductImageViewer._();

  static Future<void> show(BuildContext context, {required String imageUrl}) {
    return showGallery(context, imageUrls: [imageUrl]);
  }

  /// معرض كل صور المنتج — GET /api/products/{id} → images[]
  static Future<void> showGallery(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    final urls = imageUrls.where((u) => u.trim().isNotEmpty).toList();
    if (urls.isEmpty) return Future.value();

    final screen = MediaQuery.sizeOf(context);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _GalleryDialog(
        imageUrls: urls,
        initialIndex: initialIndex.clamp(0, urls.length - 1),
        screenHeight: screen.height,
        screenWidth: screen.width,
      ),
    );
  }
}

class _GalleryDialog extends StatefulWidget {
  const _GalleryDialog({
    required this.imageUrls,
    required this.initialIndex,
    required this.screenHeight,
    required this.screenWidth,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final double screenHeight;
  final double screenWidth;

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int next) {
    if (next < 0 || next >= widget.imageUrls.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    return Dialog(
      backgroundColor: const Color(0xFF121026),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.screenWidth - 32,
          maxHeight: widget.screenHeight * 0.85,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, 44, 12, urls.length > 1 ? 36 : 12),
              child: PageView.builder(
                controller: _controller,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  minScale: 0.85,
                  maxScale: 4,
                  child: Center(
                    child: StoreCoverImage(
                      key: ValueKey(urls[i]),
                      imageUrl: urls[i],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: widget.screenHeight * 0.72,
                    ),
                  ),
                ),
              ),
            ),
            if (urls.length > 1) ...[
              Positioned(
                left: 4,
                top: 0,
                bottom: 36,
                child: Center(
                  child: _DialogArrow(
                    icon: Icons.chevron_left,
                    onTap: () => _goTo(_index - 1),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 0,
                bottom: 36,
                child: Center(
                  child: _DialogArrow(
                    icon: Icons.chevron_right,
                    onTap: () => _goTo(_index + 1),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${urls.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogArrow extends StatelessWidget {
  const _DialogArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(icon, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
