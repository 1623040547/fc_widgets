part of 'animation_progress.dart';

class BaseTransformRecord {
  final Offset origin;

  final Rect rect;

  final double opacity;

  final double scale;

  final double scaleX;

  final double scaleY;

  final double line;

  final BorderRadius borderRadius;

  final int color;

  BaseTransformRecord({
    required this.rect,
    this.origin = Offset.zero,
    this.color = 0,
    this.borderRadius = BorderRadius.zero,
    this.scale = 0,
    this.opacity = 0,
    this.line = 0,
    this.scaleX = 0,
    this.scaleY = 0,
  });

  factory BaseTransformRecord.fromRect(Rect rect) =>
      BaseTransformRecord(rect: rect);

  factory BaseTransformRecord.fromSize(Size size) =>
      BaseTransformRecord(rect: Rect.fromLTWH(0, 0, size.width, size.height));

  factory BaseTransformRecord.fromOffset(Offset offset) =>
      BaseTransformRecord(rect: Rect.fromLTWH(offset.dx, offset.dy, 0, 0));

  factory BaseTransformRecord.fromRadius(double radius) => BaseTransformRecord(
        rect: Rect.zero,
      );

  factory BaseTransformRecord.fromOrigin(Offset origin) =>
      BaseTransformRecord(rect: Rect.zero, origin: origin);

  factory BaseTransformRecord.fromOpacity(double opacity) =>
      BaseTransformRecord(rect: Rect.zero, opacity: opacity);

  factory BaseTransformRecord.fromScale(double scale) =>
      BaseTransformRecord(rect: Rect.zero, scale: scale);

  factory BaseTransformRecord.fromColor(int color) =>
      BaseTransformRecord(rect: Rect.zero, color: color);

  factory BaseTransformRecord.fromBorderRadius(BorderRadius borderRadius) =>
      BaseTransformRecord(rect: Rect.zero, borderRadius: borderRadius);

  factory BaseTransformRecord.fromLine(double line) =>
      BaseTransformRecord(rect: Rect.zero, line: line);

  factory BaseTransformRecord.fromScaleX(double scaleX) =>
      BaseTransformRecord(rect: Rect.zero, scaleX: scaleX);

  factory BaseTransformRecord.fromScaleY(double scaleY) =>
      BaseTransformRecord(rect: Rect.zero, scaleY: scaleY);

  BaseTransformRecord operator +(BaseTransformRecord other) =>
      BaseTransformRecord(
        rect: Rect.fromLTWH(
          rect.left + other.rect.left,
          rect.top + other.rect.top,
          rect.width + other.rect.width,
          rect.height + other.rect.height,
        ),
        origin: origin + other.origin,
        opacity: opacity + other.opacity,
        color: color + other.color,
        borderRadius: borderRadius + other.borderRadius,
        scale: scale + other.scale,
        scaleX: scaleX + other.scaleX,
        scaleY: scaleY + other.scaleY,
        line: line + other.line,
      );

  BaseTransformRecord operator -(BaseTransformRecord other) =>
      BaseTransformRecord(
        rect: Rect.fromLTWH(
          rect.left - other.rect.left,
          rect.top - other.rect.top,
          rect.width - other.rect.width,
          rect.height - other.rect.height,
        ),
        origin: origin - other.origin,
        opacity: opacity - other.opacity,
        color: color - other.color,
        borderRadius: borderRadius - other.borderRadius,
        scale: scale - other.scale,
        scaleX: scaleX - other.scaleX,
        scaleY: scaleY - other.scaleY,
        line: line - other.line,
      );

  BaseTransformRecord operator *(double factor) => BaseTransformRecord(
        rect: Rect.fromLTWH(
          rect.left * factor,
          rect.top * factor,
          rect.width * factor,
          rect.height * factor,
        ),
        origin: origin * factor,
        opacity: opacity * factor,
        color: (color * factor).toInt(),
        borderRadius: borderRadius * factor,
        scale: scale * factor,
        scaleX: scaleX * factor,
        scaleY: scaleY * factor,
        line: line * factor,
      );

  BaseTransformRecord operator /(double factor) => BaseTransformRecord(
        rect: Rect.fromLTWH(
          rect.left / factor,
          rect.top / factor,
          rect.width / factor,
          rect.height / factor,
        ),
        origin: origin / factor,
        opacity: opacity / factor,
        color: color ~/ factor,
        borderRadius: borderRadius / factor,
        scale: scale / factor,
        scaleX: scaleX / factor,
        scaleY: scaleY / factor,
        line: line / factor,
      );
}
