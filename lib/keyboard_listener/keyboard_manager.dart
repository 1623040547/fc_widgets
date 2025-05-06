import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

part 'keyboard_root_binding.dart';

final keyboardManager = KeyboardManager.instance;

///键盘高度标记
///在键盘高度变化时，通过比较上一键盘高度与当前键盘高度，
///我们为此创建一个标记值，用于表示键盘高度的前后变化。
///此时，这些标记值能够构成一个标记序列，我们通过标记序列中的标记值，
///推断出当前键盘的运动形式，并使用[KeyboardMotionMark]表示
enum KeyboardHeightMark {
  ///大于之前
  large(1),

  ///小于之前
  small(2),

  ///等于之前,均为0
  equalInZero(3),

  ///等于之前，不为0
  equalNonZero(4),
  ;

  final int code;

  const KeyboardHeightMark(this.code);

  bool get isEqual => this == equalInZero || this == equalNonZero;
}

///键盘运动标记，由[_motionFeatures]中[KeyboardHeightMark]特征序列提取而来
enum KeyboardMotionMark {
  ///向上运动
  up,

  ///向下运动
  down,

  ///位于最底部
  bottom,

  ///位于最顶部
  top,

  ///非零处转向
  through,

  ///零处向上转向
  throughUp,

  ///中途向上转向
  halfThroughUp,

  ///中途向下转向
  halfThroughDown,
  ;

  bool get isTop => this == top;

  bool get isBottom => this == bottom;

  bool get isUp => this == up;

  bool get isDown => this == down;

  bool get isThroughUp => this == throughUp;

  bool get isHalfThroughUp => this == halfThroughUp;

  bool get isThrough => this == through;

  bool get isHalfThroughDown => this == halfThroughDown;
}

///由[KeyboardHeightMark]的序列识别[KeyboardMotionMark]
const Map<int, KeyboardMotionMark> _motionFeatures = {
  //
  11: KeyboardMotionMark.up,
  //
  22: KeyboardMotionMark.down,
  //
  114: KeyboardMotionMark.top,
  414: KeyboardMotionMark.top,
  424: KeyboardMotionMark.top,
  214: KeyboardMotionMark.top,
  //
  223: KeyboardMotionMark.bottom,
  423: KeyboardMotionMark.bottom,
  123: KeyboardMotionMark.bottom,
  //
  233: KeyboardMotionMark.throughUp,
  333: KeyboardMotionMark.up,
  331: KeyboardMotionMark.up,
  //
  221: KeyboardMotionMark.halfThroughUp,
  241: KeyboardMotionMark.up,
  314: KeyboardMotionMark.up,
  141: KeyboardMotionMark.up,
  //
  ///顶部转向因为可以进行键盘类型切换的缘故，
  ///导致无法识别是向上转向还是向下转向，使用转向进行描述
  144: KeyboardMotionMark.through,
  244: KeyboardMotionMark.through,
  441: KeyboardMotionMark.up,
  442: KeyboardMotionMark.down,
  //
  142: KeyboardMotionMark.halfThroughDown,
  312: KeyboardMotionMark.halfThroughDown,
  112: KeyboardMotionMark.halfThroughDown,
  124: KeyboardMotionMark.down,
  242: KeyboardMotionMark.down,
};

class KeyboardProperty {
  KeyboardHeightMark heightMark;

  KeyboardMotionMark motionMark;

  final double height;

  final double maxHeight;

  KeyboardProperty({
    required this.heightMark,
    required this.motionMark,
    required this.height,
    required this.maxHeight,
  });

  factory KeyboardProperty.zero() => KeyboardProperty(
        heightMark: KeyboardHeightMark.equalInZero,
        motionMark: KeyboardMotionMark.bottom,
        height: 0,
        maxHeight: 0,
      );

  KeyboardProperty copy({
    double? height,
    double? maxHeight,
    KeyboardHeightMark? heightMark,
    KeyboardMotionMark? motionMark,
  }) =>
      KeyboardProperty(
        height: height ?? this.height,
        heightMark: heightMark ?? this.heightMark,
        motionMark: motionMark ?? this.motionMark,
        maxHeight: maxHeight ?? this.maxHeight,
      );
}

class KeyboardManager {
  KeyboardManager._();

  static KeyboardManager? _instance;

  static KeyboardManager get instance => _instance ??= KeyboardManager._();

  final Map<String, Function(String key, KeyboardProperty property)>
      _listeners = {};

  double Function()? _getMaxKeyboardHeight;

  Function(double)? _setMaxKeyboardHeight;

  bool _isBinding = false;

  ///记录高度的标序列: height{number}, number越大高度越新
  double _height1 = 0;

  double _height2 = 0;

  final Set<double> _maxHeightSet = {};

  List<double> get maxHeightSet => _maxHeightSet.toList();

  double _maxHeight = 292;

  double get maxHeight => _getMaxKeyboardHeight?.call() ?? _maxHeight;

  ///对高度的标记: mark{number}, number越大标记越新
  KeyboardHeightMark _mark1 = KeyboardHeightMark.equalInZero;

  KeyboardHeightMark get mark1 => _mark1;

  KeyboardHeightMark _mark2 = KeyboardHeightMark.equalInZero;

  KeyboardHeightMark get mark2 => _mark2;

  KeyboardHeightMark _mark3 = KeyboardHeightMark.equalInZero;

  KeyboardHeightMark get mark3 => _mark3;

  ///对键盘运动的描述: motion{number}, number越大标记越新
  KeyboardMotionMark _motion1 = KeyboardMotionMark.bottom;

  KeyboardMotionMark get motion1 => _motion1;

  KeyboardMotionMark _motion2 = KeyboardMotionMark.bottom;

  KeyboardMotionMark get motion2 => _motion2;

  KeyboardMotionMark _motion3 = KeyboardMotionMark.bottom;

  KeyboardMotionMark get motion3 => _motion3;

  KeyboardProperty get property => KeyboardProperty(
        height: _height2,
        maxHeight: maxHeight,
        heightMark: mark3,
        motionMark: motion3,
      );

  bool _updateHeight(double height) {
    _height1 = _height2;
    _height2 = height;

    final KeyboardHeightMark newMark;
    if (_height2 > _height1) {
      newMark = KeyboardHeightMark.large;
    } else if (_height2 < _height1) {
      newMark = KeyboardHeightMark.small;
    } else if (_height2 == 0) {
      newMark = KeyboardHeightMark.equalInZero;
    } else {
      newMark = KeyboardHeightMark.equalNonZero;
    }
    return _updateHeightMark(newMark);
  }

  bool _updateHeightMark(KeyboardHeightMark newMark) {
    _mark1 = _mark2;
    _mark2 = _mark3;
    _mark3 = newMark;
    return _updateMotionMark();
  }

  bool _updateMotionMark() {
    KeyboardMotionMark? motion;
    int code2 = _mark3.code + _mark2.code * 10;
    int code3 = _mark1.code * 100 + code2;
    motion ??= _motionFeatures[code3];
    motion ??= _motionFeatures[code2];
    if (motion == null) {
      debugPrint(
          'keyboardManager ignore motion: ${_mark1.name} ${_mark2.name} ${_mark3.name}');
      return false;
    }
    _motion1 = _motion2;
    _motion2 = _motion3;
    _motion3 = motion;
    return true;
  }

  void notifyListeners() {
    final val = property;
    for (var key in _listeners.keys.toList()) {
      _listeners[key]?.call(
        key,
        val,
      );
    }
  }

  ///监听键盘发生变化
  void addListener(
    String key,
    Function(String key, KeyboardProperty property) callback, {
    ///立即执行一次
    bool callRightNow = false,
  }) {
    assert(_isBinding,
        "You should bind the `AppKeyboardListener` to the root view");
    _listeners[key] = callback;
    if (callRightNow) {
      callback.call(
        key,
        KeyboardProperty(
          height: _height2,
          maxHeight: maxHeight,
          heightMark: mark3,
          motionMark: motion3,
        ),
      );
    }
  }

  void removeListener(String key) {
    _listeners.remove(key);
  }

  void saveMaxHeight({
    double Function()? getMaxKeyboardHeight,
    Function(double)? setMaxKeyboardHeight,
  }) {
    _getMaxKeyboardHeight = getMaxKeyboardHeight;
    _setMaxKeyboardHeight = setMaxKeyboardHeight;
  }
}
