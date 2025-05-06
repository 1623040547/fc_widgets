part of 'keyboard_manager.dart';

///监听键盘弹出或收起的变化，建议将此组件绑定在`根页面`
class AppKeyboardListener extends StatefulWidget {
  const AppKeyboardListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  createState() => _AppKeyboardListenerState();
}

class _AppKeyboardListenerState extends State<AppKeyboardListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    keyboardManager._isBinding = true;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) {
      return;
    }
    final data = MediaQueryData.fromView(View.of(context));
    final bottom = data.viewInsets.bottom;
    final result = keyboardManager._updateHeight(bottom);

    if (keyboardManager.motion3.isThrough &&
        keyboardManager.motion2.isTop &&
        result) {
      keyboardManager._maxHeight = bottom;
      keyboardManager._setMaxKeyboardHeight?.call(bottom);
      keyboardManager._maxHeightSet.add(bottom);
    }

    keyboardManager.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
