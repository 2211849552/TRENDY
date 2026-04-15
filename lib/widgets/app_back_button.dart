import 'package:flutter/material.dart';

/// سهم رجوع يتبع اتجاه الواجهة: في RTL يشير نحو اليمين، في LTR نحو اليسار.
/// يُثبَّت [textDirection] على LTR لأن تعكس الويب/المتصفح لـ [BackButtonIcon] غالبًا ما يعطي سهمًا خاطئًا مع «رجوع».
class _DirectionalBackArrow extends StatelessWidget {
  const _DirectionalBackArrow({this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
      size: size,
      color: color,
      textDirection: TextDirection.ltr,
    );
  }
}

/// زر رجوع موحّد، ألوان من ثيم التطبيق.
class AppBackIconButton extends StatelessWidget {
  const AppBackIconButton({
    super.key,
    this.onPressed,
    this.iconSize,
  });

  final VoidCallback? onPressed;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      iconSize: iconSize,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: const _DirectionalBackArrow(),
    );
  }
}

/// صف «رجوع» مع نص (إشعارات، محفظة، …).
class AppBackLink extends StatelessWidget {
  const AppBackLink({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);
    return InkWell(
      onTap: onPressed ?? () => Navigator.maybePop(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: 20, color: c),
              child: const _DirectionalBackArrow(),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: c,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر نصي مع أيقونة رجوع موحّدة.
class AppBackTextButton extends StatelessWidget {
  const AppBackTextButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);
    return TextButton.icon(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      style: TextButton.styleFrom(foregroundColor: c),
      icon: _DirectionalBackArrow(size: 18, color: c),
      label: Text(label),
    );
  }
}
