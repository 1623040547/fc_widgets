import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'custom/custom_box.dart';
export 'combine_animation_controller.dart';

part 'util/position_calculator.dart';

part 'animation_test.dart';

part 'animation_box.dart';

part 'animation_state_machine.dart';

enum AnimationDuration {
  short(120),
  medium(250),
  long(400);

  final int mills;

  Duration get duration => Duration(milliseconds: mills);

  const AnimationDuration(this.mills);
}

class AnimationProgress {
  String _progressId = "";

  String get progressId => _progressId;

  TickerProvider? _ticker;

  AnimationTest test = AnimationTest();

  AnimationController? _animeController;

  Animation<double>? _animation;

  double get progress => test.progress(_animation?.value ?? 0);

  AnimationProgress();

  bool get isRunning => _animeController?.isAnimating == true;

  void register(
    TickerProvider ticker, {
    AnimationDuration duration = AnimationDuration.short,
    AnimationDuration reverseDuration = AnimationDuration.short,
    Duration? customDuration,
    Duration? customReverseDuration,
    Animation<double> Function(AnimationController)? animation,
    Curve? curve,
  }) {
    _ticker = ticker;
    _animeController = AnimationController(
      vsync: ticker,
      duration: customDuration ?? Duration(milliseconds: duration.mills),
      reverseDuration: customReverseDuration ??
          customDuration ??
          Duration(milliseconds: reverseDuration.mills),
    );
    _animation = Tween<double>(begin: 0, end: 100).animate(
      animation?.call(_animeController!) ??
          CurvedAnimation(
            parent: _animeController!,
            curve: curve ?? Curves.easeInOut,
          ),
    );
    _progressId = hashCode.toString() +
        _animation.hashCode.toString() +
        DateTime.now().microsecondsSinceEpoch.toString();
  }

  Duration? get duration => _animeController?.duration;

  void correctDuration(Duration? duration) {
    _animeController?.duration = duration;
  }

  void correctReverseDuration(Duration? duration) {
    _animeController?.reverseDuration = duration;
  }

  void reset() {
    _animeController?.reset();
  }

  TickerFuture forward() {
    return _animeController?.forward() ?? TickerFuture.complete();
  }

  TickerFuture reverse() {
    return _animeController?.reverse() ?? TickerFuture.complete();
  }

  TickerFuture repeat() {
    return _animeController?.repeat() ?? TickerFuture.complete();
  }

  void stop() {
    _animeController?.stop();
  }

  TickerFuture animateBack(double target) {
    return _animeController?.animateBack(target) ?? TickerFuture.complete();
  }

  void dispose() {
    _animeController?.dispose();
    _animeController = null;
    _animation = null;
  }

  Widget mount({
    required Widget Function(
      Widget? fixedChild,
    ) builder,
    Function()? callback,
    Widget? fixedChild,
  }) {
    final animation = _animation;
    if (animation == null) {
      return builder(null);
    }
    return AnimatedBuilder(
      animation: animation,
      child: fixedChild,
      builder: (context, _) {
        callback?.call();
        return builder(fixedChild);
      },
    );
  }
}
