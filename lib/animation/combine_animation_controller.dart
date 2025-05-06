import 'package:fc_widgets/fc_widgets.dart';
import 'package:flutter/material.dart';
import 'animation_progress.dart';

class AnimationProgressConfig {
  final AnimationDuration duration;

  final AnimationDuration reverseDuration;

  final Duration? customDuration;

  final Duration? customReverseDuration;

  final Animation<double> Function(AnimationController)? animation;

  final Curve? curve;

  AnimationProgressConfig({
    this.customDuration,
    this.customReverseDuration,
    this.duration = AnimationDuration.short,
    this.reverseDuration = AnimationDuration.short,
    this.curve,
    this.animation,
  });
}

class AnimationBoxDetail {
  final AnimationBox box;
  CustomCurve? customCurve;
  CustomBoxCurve? customBoxCurve;

  AnimationBoxDetail(
    this.box, {
    this.customCurve,
    this.customBoxCurve,
  });
}

/// - S: state
/// - O: object
/// - E: event
class CombineAnimationController<S, O, E> {
  final List<S> _statusList;

  final List<O> _objectList;

  final Map<E, List<Function>> _eventBus = {};

  final Map<S, AnimationProgress> _progress = {};

  final stateMachine = AnimationStateMachine<S>();

  CombineAnimationController(this._statusList, this._objectList);

  AnimationBox box(O object) => stateMachine.box(name: object.toString());

  AnimationBox boxWithStatus(O object, S status) =>
      stateMachine.boxWithStatus(status, name: object.toString());

  void setCurrent(AnimationBox box, O object) =>
      stateMachine.setCurrent(box, name: object.toString());

  void setVisible(O object, bool visible) =>
      stateMachine.setVisible(object.toString(), visible);

  void eventOn(
    E event,
    Function callback,
  ) {
    _eventBus[event] = [..._eventBus[event] ?? [], callback];
  }

  void eventFire(E event) {
    _eventBus[event]?.forEach((func) {
      func.call();
    });
  }

  void register(
    TickerProvider ticker, {
    required AnimationProgressConfig? Function(S progress) progressRegister,
    Function()? setState,
  }) {
    stateMachine.init(setState);
    for (var value in _statusList) {
      final config = progressRegister.call(value);
      if (config == null) {
        continue;
      }
      _progress[value] = AnimationProgress()
        ..register(
          ticker,
          duration: config.duration,
          reverseDuration: config.reverseDuration,
          customDuration: config.customDuration,
          customReverseDuration: config.customReverseDuration,
          animation: config.animation,
          curve: config.curve,
        );
    }
  }

  void dispose() {
    _eventBus.clear();
    for (var progress in _progress.values) {
      progress.dispose();
    }
  }

  Widget mount(S status,
      {required Widget Function(Widget? fixedChild) builder,
      Function()? callback}) {
    final progress = _progress[status];
    if (progress == null) {
      callback?.call();
      return builder.call(null);
    }
    return progress.mount(builder: builder, callback: callback);
  }

  void toShow(
    S status, {
    Function? animateBefore,
    Function? animateAfter,
    Duration? duration,
  }) {
    final progress = _progress[status];
    if (progress == null) {
      animateBefore?.call();
      animateAfter?.call();
      return;
    }
    stateMachine.next(status, () => progress.progress);
    animateBefore?.call();
    final oldDuration = progress.duration;
    if (duration != null) {
      progress.correctDuration(duration);
    }
    progress.reset();
    progress.forward().then((value) {
      progress.correctDuration(oldDuration);
      animateAfter?.call();
    });
  }

  void repeat(
    S status, {
    Function? animateBefore,
    Function? animateAfter,
  }) {
    final progress = _progress[status];
    if (progress == null) {
      animateBefore?.call();
      animateAfter?.call();
      return;
    }
    stateMachine.next(status, () => progress.progress);
    animateBefore?.call();
    progress.reset();
    progress.repeat().then((value) {
      animateAfter?.call();
    });
  }

  ///以物体为主体，对物体的不同状态设置其属性值
  void setBox(
    O object,
    AnimationBoxDetail? Function(S status) builder,
  ) {
    for (var status in _statusList) {
      final detail = builder.call(status);
      stateMachine.setBox(
        status,
        detail?.box,
        name: object.toString(),
        customCurve: detail?.customCurve,
        customBoxCurve: detail?.customBoxCurve,
      );
    }
  }

  ///物体属性未被设置才进行设置
  void setBoxIfNone(
    O object,
    AnimationBoxDetail? Function(S status) builder,
  ) {
    for (var status in _statusList) {
      if (stateMachine.boxExist(object.toString(), status: status)) {
        continue;
      }
      final detail = builder.call(status);
      stateMachine.setBox(
        status,
        detail?.box,
        name: object.toString(),
        customCurve: detail?.customCurve,
        customBoxCurve: detail?.customBoxCurve,
      );
    }
  }

  ///以状态为主体，对同一状态下不同的物体设置其属性值
  void setStatusBox(
    S status,
    AnimationBoxDetail? Function(O object) builder,
  ) {
    for (var object in _objectList) {
      final detail = builder.call(object);
      stateMachine.setBox(
        status,
        detail?.box,
        name: object.toString(),
        customCurve: detail?.customCurve,
        customBoxCurve: detail?.customBoxCurve,
      );
    }
  }

  ///修改某一状态下某些物体的属性值，可通过此方法关联物体间的属性
  void correctBox(
    S status,
    List<O> objects,
    AnimationBox Function(AnimationBox) newBoxBuilder,
  ) {
    for (var object in objects) {
      final oldBox =
          stateMachine.boxWithStatus(status, name: object.toString());
      stateMachine.setBox(
        status,
        newBoxBuilder.call(oldBox),
        name: object.toString(),
      );
    }
  }

  bool isRunning(S status) => _progress[status]?.isRunning == true;
}

extension AnimationBoxExtension on AnimationBox {
  AnimationBoxDetail detail(
      {CustomCurve? customCurve, CustomBoxCurve? customBoxCurve}) {
    return AnimationBoxDetail(this,
        customCurve: customCurve, customBoxCurve: customBoxCurve);
  }
}
