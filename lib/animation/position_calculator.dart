part of 'animation_progress.dart';

///以topLeft为坐标原点
class PositionCalculator {
  final Rect boxRect;
  final Size panel;
  Offset? _scaleOrigin;
  EdgeInsets? _boxMargin;
  EdgeInsets? _boxPadding;

  EdgeInsets get margin => _boxMargin ?? EdgeInsets.zero;

  EdgeInsets get padding => _boxPadding ?? EdgeInsets.zero;

  Offset get scaleOrigin => _scaleOrigin ?? Offset.zero;

  PositionCalculator({
    required this.boxRect,
    required this.panel,
    EdgeInsets? boxMargin,
    EdgeInsets? boxPadding,
    Offset? boxOrigin,
  })  : _boxPadding = boxPadding,
        _boxMargin = boxMargin,
        _scaleOrigin = boxOrigin;

  Rect verticalContain2(
    double maxScale, {
    double minWidth = 0,
    double minHeight = 0,
  }) {
    Rect rect = Rect.fromLTWH(
      boxRect.left - padding.horizontal / 2,
      boxRect.top - padding.vertical / 2,
      max(minWidth, boxRect.width + padding.horizontal / 2),
      max(minHeight, boxRect.height + padding.vertical / 2),
    );

    ///是否进行进行缩放
    double scale = scaleContain(maxScale);
    final newOrigin =
        scaleOrigin + Offset(boxRect.width / 2, boxRect.height / 2);
    Rect resizeRect = Rect.fromLTWH(
      rect.left + newOrigin.dx * (1 - scale),
      rect.top + newOrigin.dy * (1 - scale),
      rect.width * scale,
      rect.height * scale,
    );

    ///是否进行位移
    Rect translateRect = resizeRect;
    if (resizeRect.top < margin.top) {
      ///上部溢出，需要向下位移
      final translateY = margin.top - resizeRect.top;
      translateRect = resizeRect.translate(0, translateY);
    } else if (resizeRect.bottom > panel.height - margin.bottom) {
      ///下部溢出，需要向上位移
      final translateY = panel.height - margin.bottom - resizeRect.bottom;
      translateRect = resizeRect.translate(0, translateY);
    }

    return translateRect;
  }

  /// - 组件是否要缩放
  /// - 组件是否要位移
  AnimeTransform verticalContain(
    double maxScale, {
    double minWidth = 0,
    double minHeight = 0,
  }) {
    Rect rect = Rect.fromLTWH(
      boxRect.left - padding.horizontal / 2,
      boxRect.top - padding.vertical / 2,
      max(minWidth, boxRect.width + padding.horizontal / 2),
      max(minHeight, boxRect.height + padding.vertical / 2),
    );

    ///是否进行进行缩放
    double scale = scaleContain(maxScale);
    final newOrigin =
        scaleOrigin + Offset(boxRect.width / 2, boxRect.height / 2);
    Rect resizeRect = Rect.fromLTWH(
      rect.left + newOrigin.dx * (1 - scale),
      rect.top + newOrigin.dy * (1 - scale),
      rect.width * scale,
      rect.height * scale,
    );

    ///是否进行位移
    Rect translateRect = resizeRect;
    if (resizeRect.top < margin.top) {
      ///上部溢出，需要向下位移
      final translateY = margin.top - resizeRect.top;
      translateRect = resizeRect.translate(0, translateY);
    } else if (resizeRect.bottom > panel.height - margin.bottom) {
      ///下部溢出，需要向上位移
      final translateY = panel.height - margin.bottom - resizeRect.bottom;
      translateRect = resizeRect.translate(0, translateY);
    }

    return AnimeTransform(
      BaseTransformRecord.fromRect(boxRect),
      BaseTransformRecord.fromRect(translateRect),
    );
  }

  double scaleContain(double maxScale) {
    Rect rect = Rect.fromLTWH(
      boxRect.left - padding.horizontal / 2,
      boxRect.top - padding.vertical / 2,
      boxRect.width + padding.horizontal / 2,
      boxRect.height + padding.vertical / 2,
    );

    final totalHeight = rect.height * maxScale + margin.vertical;

    if (totalHeight < panel.height) {
      return maxScale;
    }

    if (rect.height != 0) {
      return (panel.height - margin.vertical) / rect.height;
    }

    return 0.001;
  }

  void correctMargin(EdgeInsets? margin) {
    _boxMargin = margin;
  }

  void correctPadding(EdgeInsets? padding) {
    _boxPadding = padding;
  }

  void correctOrigin(Offset? origin) {
    _scaleOrigin = origin;
  }
}
