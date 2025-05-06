part of 'animation_progress.dart';

class AnimeTransform {
  late final String transId;

  final BaseTransformRecord from;

  final BaseTransformRecord to;

  final double start;

  final double end;

  late final BaseTransformRecord delta;

  AnimeTransform(
    this.from,
    this.to, {
    this.start = 0,
    this.end = 100,
  }) {
    delta = to - from;
    transId =
        hashCode.toString() + DateTime.now().microsecondsSinceEpoch.toString();
  }

  factory AnimeTransform.fromRect(
    Rect from,
    Rect to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromRect(from),
        BaseTransformRecord.fromRect(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromOffset(
    Offset from,
    Offset to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromOffset(from),
        BaseTransformRecord.fromOffset(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromSize(
    Size from,
    Size to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromSize(from),
        BaseTransformRecord.fromSize(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromOpacity(
    double from,
    double to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromOpacity(from),
        BaseTransformRecord.fromOpacity(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromScale(
    double from,
    double to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromScale(from),
        BaseTransformRecord.fromScale(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromColor(
    int from,
    int to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromColor(from),
        BaseTransformRecord.fromColor(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromBorderRadius(
    BorderRadius from,
    BorderRadius to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromBorderRadius(from),
        BaseTransformRecord.fromBorderRadius(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromLine(
    double from,
    double to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromLine(from),
        BaseTransformRecord.fromLine(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromScaleX(
    double from,
    double to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromScaleX(from),
        BaseTransformRecord.fromScaleX(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.fromScaleY(
    double from,
    double to, {
    double start = 0,
    double end = 100,
  }) =>
      AnimeTransform(
        BaseTransformRecord.fromScaleY(from),
        BaseTransformRecord.fromScaleY(to),
        start: start,
        end: end,
      );

  factory AnimeTransform.zero() =>
      AnimeTransform.fromRect(Rect.zero, Rect.zero);

  double get vScale {
    if (from.rect.height == 0) {
      return 1;
    }
    return to.rect.height / from.rect.height;
  }

  double get hScale {
    if (from.rect.width == 0) {
      return 1;
    }
    return to.rect.width / from.rect.width;
  }

  double get vTranslate {
    return to.rect.top - from.rect.top;
  }

  double get hTranslate {
    return to.rect.left - from.rect.left;
  }

  Rect get oldRect => from.rect;

  Rect get newRect => to.rect;

  AnimeTransform operator +(AnimeTransform other) =>
      AnimeTransform(from + other.from, to + other.to);

  AnimeTransform operator -(AnimeTransform other) =>
      AnimeTransform(from - other.from, to - other.to);

  AnimeTransform operator *(double factor) =>
      AnimeTransform(from * factor, to * factor);

  AnimeTransform operator /(double factor) =>
      AnimeTransform(from / factor, to / factor);

  AnimeTransform get toOffset => AnimeTransform.fromRect(
        oldRect,
        Rect.fromLTWH(newRect.left, newRect.top, oldRect.width, oldRect.height),
        start: start,
        end: end,
      );

  AnimeTransform get toSize => AnimeTransform.fromRect(
        oldRect,
        Rect.fromLTWH(oldRect.left, oldRect.top, newRect.width, newRect.height),
        start: start,
        end: end,
      );

  ///反转变化，但不反转进度
  AnimeTransform get reverse => AnimeTransform(to, from);
}
