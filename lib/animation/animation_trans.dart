part of 'animation_progress.dart';

///为变化增加进度属性
class AnimationTransProgress {
  final Set<_AnimationTransProgress> _trans = {};

  AnimationTransProgress operator +(AnimationTransProgress other) {
    _trans.addAll(other._trans);
    return this;
  }

  AnimationTrans progress(double progress) {
    AnimationTrans result = AnimationTrans.zero();
    for (var trans in _trans) {
      ///正向进度处理,仅为一个点时视为正向处理
      if (trans.start <= trans.end) {
        result += _positiveProcess(progress, trans);
      }

      ///反向进度处理
      if (trans.start > trans.end) {
        result += _negativeProcess(progress, trans);
      }
    }
    return result;
  }

  AnimationTrans _positiveProcess(
      double progress, _AnimationTransProgress trans) {
    if (progress >= trans.end) {
      return trans.trans;
    }
    if (progress <= trans.start) {
      return AnimationTrans.zero();
    }
    final factor = (progress - trans.start) / (trans.end - trans.start);
    return trans.trans * factor;
  }

  AnimationTrans _negativeProcess(
      double progress, _AnimationTransProgress trans) {
    if (progress <= trans.start) {
      return trans.trans;
    }
    if (progress >= trans.end) {
      return AnimationTrans.zero();
    }
    final factor = (trans.end - progress) / (trans.start - trans.end);
    return trans.trans * factor;
  }
}

class _AnimationTransProgress {
  final AnimationTrans trans;
  final int start;
  final int end;

  _AnimationTransProgress(
    this.trans, {
    this.start = 0,
    this.end = 100,
  });
}

///表示所有变化的偏移量
class AnimationTrans {
  String _transId = "";

  String get transId => _transId;

  double width = 0;

  double height = 0;

  Offset offset = Offset.zero;

  double scale = 0;

  double scaleX = 0;

  double scaleY = 0;

  BorderRadius borderRadius = BorderRadius.zero;

  List<int> _color = [0, 0, 0, 0];

  Color get color => Color.fromARGB(_color[0], _color[1], _color[2], _color[3]);

  double line = 0;

  double opacity = 0;

  AnimationTrans() {
    _transId =
        hashCode.toString() + DateTime.now().microsecondsSinceEpoch.toString();
  }

  AnimationTransProgress progress(int start, int end) {
    final vector = AnimationTransProgress();
    vector._trans.add(_AnimationTransProgress(this, start: start, end: end));
    return vector;
  }

  factory AnimationTrans.zero() => AnimationTrans();

  AnimationTrans operator +(AnimationTrans other) => AnimationTrans()
    ..width = width + other.width
    ..height = height + other.height
    ..offset = offset + other.offset
    ..scale = scale + other.scale
    ..scaleX = scaleX + other.scaleX
    ..scaleY = scaleY + other.scaleY
    ..borderRadius = borderRadius + other.borderRadius
    .._color = [
      _color[0] + other._color[0],
      _color[1] + other._color[1],
      _color[2] + other._color[2],
      _color[3] + other._color[3]
    ]
    ..line = line + other.line
    ..opacity = line + other.opacity;

  AnimationTrans operator -(AnimationTrans other) => AnimationTrans()
    ..width = width - other.width
    ..height = height - other.height
    ..offset = offset - other.offset
    ..scale = scale - other.scale
    ..scaleX = scaleX - other.scaleX
    ..scaleY = scaleY - other.scaleY
    ..borderRadius = borderRadius - other.borderRadius
    .._color = [
      _color[0] - other._color[0],
      _color[1] - other._color[1],
      _color[2] - other._color[2],
      _color[3] - other._color[3]
    ]
    ..line = line - other.line
    ..opacity = line - other.opacity;

  AnimationTrans operator *(double factor) => AnimationTrans()
    ..width = width * factor
    ..height = height * factor
    ..offset = offset * factor
    ..scale = scale * factor
    ..scaleX = scaleX * factor
    ..scaleY = scaleY * factor
    ..borderRadius = borderRadius * factor
    .._color = [
      (_color[0] * factor).toInt(),
      (_color[1] * factor).toInt(),
      (_color[2] * factor).toInt(),
      (_color[3] * factor).toInt()
    ]
    ..line = line * factor
    ..opacity = line * factor;

  AnimationTrans operator /(double factor) => AnimationTrans()
    ..width = width / factor
    ..height = height / factor
    ..offset = offset / factor
    ..scale = scale / factor
    ..scaleX = scaleX / factor
    ..scaleY = scaleY / factor
    ..borderRadius = borderRadius / factor
    .._color = [
      _color[0] ~/ factor,
      _color[1] ~/ factor,
      _color[2] ~/ factor,
      _color[3] ~/ factor
    ]
    ..line = line / factor
    ..opacity = line / factor;
}
