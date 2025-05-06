part of 'animation_progress.dart';

class AnimationBoxCustom<T> {
  final String name;

  final T value;

  final T Function(T self, T other) operatorAdd;

  final T Function(T self, T other) operatorMinus;

  final T Function(T self, double other) operatorMultiply;

  final T Function(T self, double other) operatorDivide;

  ///如果右值为空，则始终保留左值的复制
  AnimationBoxCustom<T>? operateCustom(String operator,
      {T? other, double? factor}) {
    switch (operator) {
      case '+':
        if (other != null) {
          return copy(operatorAdd(value, other));
        }
        return copy(value);
      case '-':
        if (other != null) {
          return copy(operatorMinus(value, other));
        }
        return copy(value);
      case '*':
        if (factor != null) {
          return copy(operatorMultiply(value, factor));
        }
        return copy(value);
      case '/':
        if (factor != null) {
          return copy(operatorDivide(value, factor));
        }
        return copy(value);
    }
    return null;
  }

  AnimationBoxCustom({
    required this.name,
    required this.value,
    required this.operatorAdd,
    required this.operatorMinus,
    required this.operatorMultiply,
    required this.operatorDivide,
  });

  AnimationBoxCustom<T> copy(
    T? newValue,
  ) =>
      AnimationBoxCustom<T>(
        name: this.name,
        value: newValue ?? this.value,
        operatorAdd: operatorAdd,
        operatorMinus: operatorMinus,
        operatorMultiply: operatorMultiply,
        operatorDivide: operatorDivide,
      );
}

///基础的动画属性盒子，如果需要更多属性，
///考虑调用[setCustom]自定义新的属性字段
class AnimationBox {
  double _width = 0;

  double _height = 0;

  Offset _offset = Offset.zero;

  double _line = 0;

  double _opacity = 1;

  double _scale = 1;

  bool _visible = true;

  bool get visible => _visible;

  double get width => _width > 0 ? _width : 0;

  double get height => _height > 0 ? _height : 0;

  double get opacity => clampDouble(_opacity, 0, 1);

  double get line => _line;

  double get scale => _scale > 0 ? _scale : 0;

  Offset get offset => _offset;

  Map<String, AnimationBoxCustom>? _custom;

  AnimationBox();

  void setVisible(bool visible) {
    _visible = visible;
  }

  void setCustom<T>(AnimationBoxCustom<T> value) {
    _custom ??= {};
    _custom?[value.name] = value;
  }

  T? getCustom<T>(String name) {
    final value = _custom?[name]?.value;
    if (value is T) {
      return value;
    }
    return null;
  }

  ///操作自定义box属性值
  ///如果右值为空，则始终保留左值的复制，反之不成立
  Map<String, AnimationBoxCustom>? operateCustom(String operator,
      {AnimationBox? box, double? factor}) {
    final keys = _custom?.keys;
    if (keys == null || keys.isEmpty) {
      return null;
    }
    final Map<String, AnimationBoxCustom<dynamic>> newCustom = {};
    for (var key in keys) {
      final selfObj = _custom?[key];
      final otherObj = box?._custom?[key];
      if (otherObj != null && selfObj != null) {
        assert(
          selfObj.value.runtimeType == otherObj.value.runtimeType,
          'The same name\'s object must have a same type\'s value.',
        );
      }
      final newVal = selfObj?.operateCustom(operator,
          other: otherObj?.value, factor: factor);
      if (newVal != null) {
        newCustom[key] = newVal;
      }
    }
    return newCustom;
  }

  factory AnimationBox.zero() => AnimationBox.box(opacity: 0, scale: 0);

  factory AnimationBox.box({
    double width = 0,
    double height = 0,
    double line = 0,
    Offset offset = Offset.zero,
    double opacity = 1,
    double scale = 1,
    bool visible = true,
    List<AnimationBoxCustom>? custom,
  }) =>
      AnimationBox()
        .._scale = scale
        .._width = width
        .._height = height
        .._offset = offset
        .._line = line
        .._opacity = opacity
        .._visible = visible
        .._custom = custom == null
            ? null
            : Map.fromEntries(custom.map((e) => MapEntry(e.name, e)));

  AnimationBox copy({
    double? width,
    double? height,
    double? line,
    Offset? offset,
    double? opacity,
    double? scale,
    bool? visible,
    List<AnimationBoxCustom>? custom,
  }) =>
      AnimationBox.box(
        width: width ?? _width,
        height: height ?? _height,
        line: line ?? _line,
        offset: offset ?? _offset,
        opacity: opacity ?? _opacity,
        scale: scale ?? _scale,
        visible: visible ?? _visible,
        custom: custom ?? _custom?.values.toList(),
      );

  AnimationBox operator +(AnimationBox box) => AnimationBox()
    .._width = _width + box._width
    .._height = _height + box._height
    .._offset = _offset + box._offset
    .._line = _line + box._line
    .._opacity = _opacity + box._opacity
    .._scale = _scale + box._scale
    .._visible = _visible
    .._custom = operateCustom('+', box: box);

  AnimationBox operator -(AnimationBox box) => AnimationBox()
    .._width = _width - box._width
    .._height = _height - box._height
    .._offset = _offset - box._offset
    .._line = _line - box._line
    .._opacity = _opacity - box._opacity
    .._scale = _scale - box._scale
    .._visible = _visible
    .._custom = operateCustom('-', box: box);

  AnimationBox operator *(double factor) => AnimationBox()
    .._width = _width * factor
    .._height = _height * factor
    .._offset = _offset * factor
    .._line = _line * factor
    .._opacity = _opacity * factor
    .._scale = _scale * factor
    .._visible = _visible
    .._custom = operateCustom('*', factor: factor);

  AnimationBox operator /(double factor) => AnimationBox()
    .._width = _width / factor
    .._height = _height / factor
    .._offset = _offset / factor
    .._line = _line / factor
    .._opacity = _opacity / factor
    .._scale = _scale / factor
    .._visible = _visible
    .._custom = operateCustom('/', factor: factor);
}

extension AnimationBoxQuickWidget on AnimationBox {
  Widget wSizedBox({
    required Widget child,
    bool asMaxHeight = false,
    bool asMaxWidth = false,
    bool asMinHeight = false,
    bool asMinWidth = false,
  }) =>
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: asMaxWidth ? width : double.infinity,
          minWidth: asMinWidth ? width : 0,
          maxHeight: asMaxHeight ? height : double.infinity,
          minHeight: asMinHeight ? height : 0,
        ),
        child: SizedBox(
          width: asMaxWidth || asMinWidth ? null : width,
          height: asMaxHeight || asMinHeight ? null : height,
          child: child,
        ),
      );

  Widget wVisibility({required Widget child}) =>
      Visibility(visible: visible, child: child);

  Widget wOpacity({required Widget child}) =>
      Opacity(opacity: opacity, child: child);

  Widget wScale({required Widget child, Alignment? alignment}) =>
      Transform.scale(scale: scale, alignment: alignment, child: child);

  Widget wTranslate({required Widget child}) =>
      Transform.translate(offset: offset, child: child);

  Widget wPositioned({
    required Widget child,
    Alignment alignment = Alignment.topLeft,
  }) =>
      Positioned(
        top: alignment.y == -1 ? offset.dy : null,
        left: alignment.x == -1 ? offset.dy : null,
        bottom: alignment.y == 1 ? offset.dy : null,
        right: alignment.x == 1 ? offset.dy : null,
        child: child,
      );

  BorderRadius get wBoarderRadiusAll => BorderRadius.all(Radius.circular(line));

  Widget wBackdropFilterBlur({required Widget child}) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: line, sigmaY: line), child: child);
}
