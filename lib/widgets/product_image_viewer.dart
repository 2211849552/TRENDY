import 'package:flutter/material.dart';

import 'store_cover_image.dart';

/// عرض الصورة كاملة مع إمكانية التكبير.
class ProductImageViewer {
  ProductImageViewer._();

  static Future<void> show(BuildContext context, {required String imageUrl}) {
  final screen = MediaQuery.sizeOf(context);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF121026),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screen.width - 32, maxHeight: screen.height * 0.85),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 44, 12, 12),
                child: InteractiveViewer(
                  minScale: 0.85,
                  maxScale: 4,
                  child: Center(
                    child: StoreCoverImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: screen.height * 0.72,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
