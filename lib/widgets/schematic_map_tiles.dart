import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// بلاطات خريطة مخطّطة محلية — نمط قمر (داكن) / شمس (فاتح 3D).
class SchematicTileProvider extends TileProvider {
  SchematicTileProvider({required this.isLight});

  final bool isLight;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return SchematicTileImage(coordinates: coordinates, isLight: isLight);
  }
}

class SchematicTileImage extends ImageProvider<SchematicTileImage> {
  const SchematicTileImage({
    required this.coordinates,
    required this.isLight,
  });

  final TileCoordinates coordinates;
  final bool isLight;

  @override
  Future<SchematicTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    SchematicTileImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_load(key));
  }

  Future<ImageInfo> _load(SchematicTileImage key) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintSchematicMapTile(
      canvas: canvas,
      size: const Size(256, 256),
      coordinates: key.coordinates,
      isLight: key.isLight,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(256, 256);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) {
    if (other is! SchematicTileImage) return false;
    return coordinates == other.coordinates && isLight == other.isLight;
  }

  @override
  int get hashCode => Object.hash(coordinates, isLight);
}

void paintSchematicMapTile({
  required Canvas canvas,
  required Size size,
  required TileCoordinates coordinates,
  required bool isLight,
}) {
  final tileX = coordinates.x;
  final tileY = coordinates.y;
  final originWorldX = tileX * 256.0;
  final originWorldY = tileY * 256.0;

  if (isLight) {
    _paintLightTile(canvas, size, originWorldX, originWorldY);
  } else {
    _paintDarkTile(canvas, size, originWorldX, originWorldY);
  }
}

void _paintLightTile(Canvas canvas, Size size, double ox, double oy) {
  const bg = Color(0xFFE9EDF2);
  canvas.drawRect(Offset.zero & size, Paint()..color = bg);

  _drawRoadGrid(
    canvas: canvas,
    ox: ox,
    oy: oy,
    minor: const Color(0xFFDDE3EA),
    major: const Color(0xFFD0D8E1),
    minorWidth: 10,
    majorWidth: 14,
    minorStep: 72,
    majorStep: 216,
  );

  const cell = 68.0;
  for (var wy = (oy ~/ cell).floor() * cell; wy < oy + 256 + cell; wy += cell) {
    for (var wx = (ox ~/ cell).floor() * cell; wx < ox + 256 + cell; wx += cell) {
      final hash = _worldHash(wx.toInt(), wy.toInt());
      if (hash % 5 == 0) continue;

      final w = cell * (0.72 + (hash % 3) * 0.1);
      final h = cell * (0.58 + ((hash >> 2) % 3) * 0.12);
      final left = wx - ox + ((hash >> 4) % 8);
      final top = wy - oy + ((hash >> 7) % 8);

      if (left + w < -6 || top + h < -6 || left > 262 || top > 262) continue;

      _drawLightBlock(canvas, left, top, w, h, hash);
    }
  }
}

void _paintDarkTile(Canvas canvas, Size size, double ox, double oy) {
  const bg = Color(0xFF1A212B);
  canvas.drawRect(Offset.zero & size, Paint()..color = bg);

  _drawRoadGrid(
    canvas: canvas,
    ox: ox,
    oy: oy,
    minor: const Color(0xFF252E3B),
    major: const Color(0xFF2E3847),
    minorWidth: 5,
    majorWidth: 7,
    minorStep: 64,
    majorStep: 192,
  );

  const cell = 58.0;
  for (var wy = (oy ~/ cell).floor() * cell; wy < oy + 256 + cell; wy += cell) {
    for (var wx = (ox ~/ cell).floor() * cell; wx < ox + 256 + cell; wx += cell) {
      final hash = _worldHash(wx.toInt(), wy.toInt());
      if (hash % 6 == 0) continue;

      final w = cell * (0.78 + (hash % 4) * 0.07);
      final h = cell * (0.68 + ((hash >> 2) % 4) * 0.08);
      final left = wx - ox + ((hash >> 4) % 6);
      final top = wy - oy + ((hash >> 7) % 6);

      if (left + w < -4 || top + h < -4 || left > 260 || top > 260) continue;

      _drawDarkBlock(canvas, left, top, w, h);
    }
  }
}

void _drawRoadGrid({
  required Canvas canvas,
  required double ox,
  required double oy,
  required Color minor,
  required Color major,
  required double minorWidth,
  required double majorWidth,
  required int minorStep,
  required int majorStep,
}) {
  final minorPaint = Paint()
    ..color = minor
    ..strokeWidth = minorWidth
    ..strokeCap = StrokeCap.square;

  final majorPaint = Paint()
    ..color = major
    ..strokeWidth = majorWidth
    ..strokeCap = StrokeCap.square;

  for (var wx = (ox ~/ minorStep) * minorStep; wx < ox + 256; wx += minorStep) {
    final lx = wx - ox;
    canvas.drawLine(Offset(lx, 0), Offset(lx, 256), minorPaint);
  }
  for (var wy = (oy ~/ minorStep) * minorStep; wy < oy + 256; wy += minorStep) {
    final ly = wy - oy;
    canvas.drawLine(Offset(0, ly), Offset(256, ly), minorPaint);
  }

  for (var wx = (ox ~/ majorStep) * majorStep; wx < ox + 256; wx += majorStep) {
    final lx = wx - ox;
    canvas.drawLine(Offset(lx, 0), Offset(lx, 256), majorPaint);
  }
  for (var wy = (oy ~/ majorStep) * majorStep; wy < oy + 256; wy += majorStep) {
    final ly = wy - oy;
    canvas.drawLine(Offset(0, ly), Offset(256, ly), majorPaint);
  }
}

void _drawLightBlock(Canvas canvas, double left, double top, double w, double h, int hash) {
  final depth = 7.0 + (hash % 5) * 2.5;
  final skew = depth * 0.55;

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 3, top + h - 3, w - 2, 7),
      const Radius.circular(2),
    ),
    Paint()..color = const Color(0x1A000000),
  );

  final side = Path()
    ..moveTo(left + w, top)
    ..lineTo(left + w + skew, top - depth)
    ..lineTo(left + w + skew, top + h - depth)
    ..lineTo(left + w, top + h)
    ..close();
  canvas.drawPath(side, Paint()..color = const Color(0xFFCCD4DD));

  final front = Path()
    ..moveTo(left, top + h)
    ..lineTo(left + skew, top + h - depth)
    ..lineTo(left + w + skew, top + h - depth)
    ..lineTo(left + w, top + h)
    ..close();
  canvas.drawPath(front, Paint()..color = const Color(0xFFD8DFE7));

  final roof = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top - depth, w, h),
    const Radius.circular(2),
  );
  canvas.drawRRect(roof, Paint()..color = Colors.white);
  canvas.drawRRect(
    roof,
    Paint()
      ..color = const Color(0xFFE3E8EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9,
  );
}

void _drawDarkBlock(Canvas canvas, double left, double top, double w, double h) {
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, w, h),
    const Radius.circular(2),
  );
  canvas.drawRRect(rect, Paint()..color = const Color(0xFF2B3645));
  canvas.drawRRect(
    rect,
    Paint()
      ..color = const Color(0xFF384556)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  canvas.drawLine(
    Offset(left + 2, top + 2),
    Offset(left + w - 2, top + 2),
    Paint()
      ..color = const Color(0xFF3A4658)
      ..strokeWidth = 1.2,
  );
}

int _worldHash(int x, int y) {
  return (x * 374761393 + y * 668265263) & 0x7fffffff;
}
