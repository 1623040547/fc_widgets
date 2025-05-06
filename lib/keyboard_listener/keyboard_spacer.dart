import 'dart:math';

import 'package:flutter/material.dart';

import 'keyboard_listener.dart';

class KeyboardSpacerController {
  late final String keyboardListenKey = 'keyboardListenKey_$hashCode';

  int _lockCounter = 0;

  bool _isLock = false;

  double? _lockedHeight;

  double _minHeight = 0;

  void setMinHeight(double minHeight) {
    _minHeight = minHeight;
  }

  bool get isLock => _isLock;

  ///锁住当前占位高度
  void lockHeight() {
    if (_isLock) {
      return;
    }
    _lockCounter++;
    keyboardManager.removeListener(keyboardListenKey);
    _isLock = true;
    _lockedHeight = _keyboardHeight?.call();
  }

  ///解锁当前占位高度，当[_height]取值变化为和[_lockedHeight]非常接近时，
  ///[_lockedHeight]才会被设置为空，以此避免占位空白的突变
  void unlockHeight({bool willFocus = false}) {
    if (!_isLock) {
      return;
    }
    if (willFocus) {
      _unlockWillFocus();
    } else {
      _unlockNoFocus();
    }
    final lockCounter = _lockCounter;
    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (lockCounter == _lockCounter && _isLock) {
          _isLock = false;
          _lockedHeight = null;
        }
      },
    );
  }

  ///在解锁时将要请求焦点
  void _unlockWillFocus() {
    final KeyboardMotionMark motion = keyboardManager.motion3;
    final lockedHeight = _lockedHeight ?? 0;
    if (lockedHeight == _minHeight) {
      _isLock = false;
      _lockedHeight = null;
      return;
    }
    if (motion.isTop) {
      _isLock = false;
      _lockedHeight = null;
      return;
    }
    keyboardManager.addListener(
      keyboardListenKey,
      (key, property) {
        ///获取再次请求焦点前的键盘运动标记或者在中途便转而向下移动
        if (property.motionMark.isTop ||
            property.motionMark.isHalfThroughDown) {
          _isLock = false;
          _lockedHeight = null;
          keyboardManager.removeListener(key);
        }
      },
    );
  }

  void _unlockNoFocus() {
    final KeyboardMotionMark motion = keyboardManager.motion3;
    final lockedHeight = _lockedHeight ?? 0;
    if (lockedHeight != _minHeight) {
      _isLock = false;
      _lockedHeight = null;
      return;
    }
    if (motion.isBottom) {
      _isLock = false;
      _lockedHeight = null;
      return;
    }
    keyboardManager.addListener(
      keyboardListenKey,
      (key, property) {
        ///获取再次请求焦点前的键盘运动标记或者在中途便转而向下移动
        if (property.motionMark.isBottom ||
            property.motionMark.isHalfThroughUp) {
          _isLock = false;
          _lockedHeight = null;
          keyboardManager.removeListener(key);
        }
      },
    );
  }

  double Function()? _keyboardHeight;
}

///键盘空白处占位组件
class KeyboardSpacer extends StatefulWidget {
  final Widget? child;

  final KeyboardSpacerController controller;

  const KeyboardSpacer({
    super.key,
    required this.controller,
    this.child,
  });

  @override
  State<StatefulWidget> createState() => _KeyboardSpacer();
}

class _KeyboardSpacer extends State<KeyboardSpacer>
    with WidgetsBindingObserver {
  KeyboardSpacerController get controller => widget.controller;

  double get keyboardHeight =>
      MediaQueryData.fromView(View.of(context)).viewInsets.bottom;

  @override
  void initState() {
    super.initState();
    controller._keyboardHeight =
        () => max(controller._minHeight, keyboardHeight);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) {
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: controller._lockedHeight ??
          max(controller._minHeight, keyboardHeight),
      child: widget.child,
    );
  }
}
