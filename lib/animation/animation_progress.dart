import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'custom/custom_box.dart';
export 'combine_animation_controller.dart';

part 'position_calculator.dart';

part 'animation_test.dart';

part 'anime_transform.dart';

part 'base_transform_record.dart';

part 'animation_box.dart';

part 'animation_trans.dart';

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

class AnimationDrive {
  final Map<AnimationProgress, Set<AnimeTransform>> _transforms = {};

  AnimationProgress? _point;

  Rect? _start;

  Rect get start => _start ?? Rect.zero;

  AnimationDrive();

  void pointToProgress(AnimationProgress progress) {
    _point = progress;
  }

  void addAll(List<AnimeTransform> element) {
    assert(_point != null, 'Did you call the `pointToProgress`?');
    if (_point != null) {
      _transforms[_point!] = {
        ..._transforms[_point!] ?? [],
        ...element,
      };
    }
  }

  void add(AnimeTransform element) {
    assert(_point != null, 'Did you call the `pointToProgress`?');
    if (_point != null) {
      _transforms[_point!] = {
        ..._transforms[_point!] ?? [],
        element,
      };
    }
  }

  void setStart(Rect start) {
    _start = start;
  }

  ///获取某个进度下的变化组合
  BaseTransformRecord get delta {
    List<BaseTransformRecord> records = [];
    for (var key in _transforms.keys) {
      if (key.progress == 0) {
        continue;
      }
      final transforms = _transforms[key] ?? {};
      if (transforms.isEmpty) {
        continue;
      } else if (transforms.length == 1) {
        records = [
          ...records,
          transforms.first.delta *
              key.progress.factor(transforms.first.start, transforms.first.end)
        ];
      } else {
        records = [
          ...records,
          transforms
              .map((e) => e.delta * key.progress.factor(e.start, e.end))
              .reduce((a, b) => a + b)
        ];
      }
    }

    if (records.isEmpty) {
      return BaseTransformRecord.fromSize(Size.zero);
    }

    return records.reduce((a, b) => a + b);
  }

  ///获取drive偏移量变化的集合
  List<AnimeTransform> get offsets =>
      _transforms[_point]?.map((e) => e.toOffset).toList() ?? [];
}

extension AnimationProgressFactor on AnimationProgress {
  double factor(int from, int to) =>
      min((to - from), max(0, progress - from)) / (to - from);
}

extension AnimationDriveDouble on double {
  double progress(double factor) => this * factor;

  double factor(double from, double to) =>
      min((to - from), max(0, this - from)) / (to - from);
}
