import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// يعرض صورة من API (`logo` / `banner_image`) أو من assets محلية.
class StoreCoverImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// عرض الشعار دائرياً (حقل `logo` من GET /api/stores).
  final bool asLogo;

  const StoreCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.asLogo = false,
  });

  static bool isAssetPath(String url) => url.startsWith('assets/');

  static bool isRemoteUrl(String url) {
    final trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static bool hasDisplayableUrl(String url) => url.trim().isNotEmpty;

  static ImageProvider? imageProvider(String url) {
    if (!hasDisplayableUrl(url)) return null;
    if (isAssetPath(url)) return AssetImage(url);
    return NetworkImage(url);
  }

  @override
  State<StoreCoverImage> createState() => _StoreCoverImageState();
}

class _StoreCoverImageState extends State<StoreCoverImage> {
  Uint8List? _bytes;
  bool _loadingRemote = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadRemote();
  }

  @override
  void didUpdateWidget(covariant StoreCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _bytes = null;
      _failed = false;
      _loadingRemote = false;
      _loadRemote();
    }
  }

  Future<void> _loadRemote() async {
    final url = widget.imageUrl.trim();
    if (!StoreCoverImage.isRemoteUrl(url)) return;

    // على الويب: img HTML يتجاوز قيود CORS لمسار /storage/
    if (kIsWeb) {
      if (mounted) setState(() => _loadingRemote = true);
      return;
    }

    if (mounted) setState(() => _loadingRemote = true);
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() {
          _bytes = response.bodyBytes;
          _loadingRemote = false;
          _failed = false;
        });
      } else {
        setState(() {
          _loadingRemote = false;
          _failed = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRemote = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!StoreCoverImage.hasDisplayableUrl(widget.imageUrl)) {
      return _wrap(_placeholder());
    }

    final effectiveFit = widget.asLogo ? BoxFit.contain : widget.fit;
    Widget image;

    if (StoreCoverImage.isAssetPath(widget.imageUrl)) {
      image = Image.asset(
        widget.imageUrl,
        fit: effectiveFit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (_bytes != null) {
      image = Image.memory(
        _bytes!,
        fit: effectiveFit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (!kIsWeb && _loadingRemote) {
      image = _loadingIndicator(null);
    } else if (kIsWeb) {
      image = Image.network(
        widget.imageUrl,
        fit: effectiveFit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingIndicator(progress);
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (!_failed) {
      image = Image.network(
        widget.imageUrl,
        fit: effectiveFit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingIndicator(progress);
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      image = _placeholder();
    }

    return _wrap(image);
  }

  Widget _wrap(Widget image) {
    if (widget.asLogo) {
      final logoSize = widget.width ?? widget.height ?? 88.0;
      return ClipOval(
        child: Container(
          width: logoSize,
          height: logoSize,
          color: const Color(0xFF1E1B2E),
          padding: const EdgeInsets.all(8),
          child: image,
        ),
      );
    }
    if (widget.width != null || widget.height != null) {
      return image;
    }
    return SizedBox.expand(child: image);
  }

  Widget _loadingIndicator(ImageChunkEvent? progress) {
    return Center(
      child: CircularProgressIndicator(
        value: progress?.expectedTotalBytes != null
            ? progress!.cumulativeBytesLoaded / progress.expectedTotalBytes!
            : null,
        color: const Color(0xFF3B82F6),
        strokeWidth: 2,
      ),
    );
  }

  Widget _placeholder() {
    final iconSize = widget.asLogo ? 36.0 : 40.0;
    final child = Icon(Icons.storefront_outlined, color: const Color(0xFF94A3B8), size: iconSize);
    if (widget.asLogo) {
      final logoSize = widget.width ?? widget.height ?? 88.0;
      return ClipOval(
        child: Container(
          width: logoSize,
          height: logoSize,
          color: const Color(0xFF1E1B2E),
          child: Center(child: child),
        ),
      );
    }
    return Container(
      color: const Color(0xFF1E1B2E),
      width: widget.width,
      height: widget.height,
      child: Center(child: child),
    );
  }
}
