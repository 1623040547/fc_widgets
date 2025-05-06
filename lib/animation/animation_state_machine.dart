part of 'animation_progress.dart';

typedef CustomBoxCurve = AnimationBox Function(
    AnimationBox current,
    AnimationBox newBox,
    AnimationBox delta,
    double progress,
    double lastProgress);

typedef CustomCurve = double Function(double, double);

///通过记录上一状态与下一状态描述状态机所处的边
class AnimationStateEdge<T> {
  T? _frontStatus;

  T? _nextStatus;

  T? get next => _nextStatus;

  T? get front => _frontStatus;

  void update(T? status) {
    _frontStatus = _nextStatus;
    _nextStatus = status;
  }

  bool isEqual(AnimationStateEdge edge) {
    return edge._frontStatus == _frontStatus && edge._nextStatus == _nextStatus;
  }

  AnimationStateEdge();

  factory AnimationStateEdge.build(T? from, T? to) {
    return AnimationStateEdge<T>()
      .._frontStatus = from
      .._nextStatus = to;
  }
}

///开启自定义曲线功能，可自定义修改前往某一节点时进度曲线的变化
mixin AnimationCustomCurve<T> {
  final bool enableCustomCurve = true;

  ///前往状态机节点的自定义曲线
  final Map<T, Map<String, CustomCurve?>> _curves = {};

  final Map<T, Map<String, CustomBoxCurve?>> _customBoxCurves = {};

  void setCustomBoxCurve(
    T status, {
    String name = "",
    CustomCurve? customCurve,
    CustomBoxCurve? customBoxCurve,
  }) {
    if (!enableCustomCurve) {
      return;
    }
    _customBoxCurves[status] ??= {};
    _customBoxCurves[status]?[name] = customBoxCurve;
  }

  void setCustomCurve(
    T status, {
    String name = "",
    CustomCurve? customCurve,
  }) {
    if (!enableCustomCurve) {
      return;
    }
    _curves[status] ??= {};
    _curves[status]?[name] = customCurve;
  }

  CustomCurve? getCustomCurve(
    T? status, {
    String name = "",
  }) {
    if (!enableCustomCurve) {
      return null;
    }
    return _curves[status]?[name];
  }

  CustomBoxCurve? getCustomBoxCurve(
    T? status, {
    String name = "",
  }) {
    if (!enableCustomCurve) {
      return null;
    }
    return _customBoxCurves[status]?[name];
  }

  double getCustomCurveCursor(
    T? status, {
    String name = "",
    double progress = 0,
    double lastProgress = 0,
  }) {
    if (!enableCustomCurve) {
      return progress;
    }
    return getCustomCurve(status, name: name)?.call(progress, lastProgress) ??
        progress;
  }

  AnimationBox getCustomCurveBox(
    T? status, {
    String name = "",
    required AnimationBox oldBox,
    required AnimationBox path,
    double progress = 0,
    double lastProgress = 0,
  }) {
    final delta = path * (progress - lastProgress) / 100;
    final newBox = oldBox + path * (progress - lastProgress) / 100;
    if (!enableCustomCurve) {
      return newBox;
    }

    return getCustomBoxCurve(status, name: name)
            ?.call(oldBox, newBox, delta, progress, lastProgress) ??
        newBox;
  }
}

///组合动画管理方案，将一个页面或组件的各种动画抽象为状态机，
class AnimationStateMachine<T> with AnimationCustomCurve<T> {
  final AnimationStateEdge<T> edge = AnimationStateEdge<T>();

  T? get status => edge._nextStatus;

  bool _animeIsEnd = false;

  double Function()? _cursor;

  Function()? _setState;

  ///记录上一次前行进度
  final Map<String, double> _frontCursor = {};

  ///记录当前属性盒子，[_cursor]每次前进，[_current]都会更新（如果[box]被调用）
  ///以此实现物体属性与进度之间的解耦，不需要等待上一路径走完，便可直接指定前往下一路径
  final Map<String, AnimationBox> _current = {};

  ///记录连续的前行路径
  final Map<String, AnimationBox> _path = {};

  ///状态机节点
  final Map<T, Map<String, AnimationBox>> _nodes = {};

  void init(Function()? setState) {
    _setState = setState;
  }

  ///现有路径已走完多少进度
  AnimationBox finishPath({String name = ""}) {
    return (_path[name] ?? AnimationBox.box()) *
        (_frontCursor[name] ?? 0) /
        100;
  }

  ///现有路径剩余多少进度没有走完
  AnimationBox remainPath({String name = ""}) {
    final remain = (100 - (_frontCursor[name] ?? 0)) / 100;
    return (_path[name] ?? AnimationBox.box()) * remain;
  }

  ///在原有路径上叠加路径，如果当前进度是40，
  ///则叠加路径实际为[addPath] * 100 / (100 - 40)
  void overlayPath(AnimationBox addPath, {String name = ""}) {
    final double delta = 100 - (_frontCursor[name] ?? 0);
    if (delta <= 0) {
      return;
    }
    _path[name] = (_path[name] ?? AnimationBox.box()) + addPath * (100 / delta);
  }

  ///从当前节点,构造前往下一节点的路径
  ///- nextStatus：所前往的下一结点
  ///- cursor：游标，指示前往构建路径的进度（0->100）
  void next(T nextStatus, double Function()? cursor) {
    _animeIsEnd = false;
    edge.update(nextStatus);
    _frontCursor.clear();
    _path.clear();
    _cursor = cursor;
    final Map<String, AnimationBox> newBox = _nodes[nextStatus] ?? {};

    ///构建路径
    for (var key in newBox.keys) {
      final current = _current[key] ?? AnimationBox();
      final nextNode = _nodes[nextStatus]?[key];
      if (nextNode != null) {
        _path[key] = nextNode - current;
      }
    }
  }

  void setVisible(String name, bool visible) {
    _current[name]?._visible = visible;
  }

  ///直接完成当前构造路径
  void finish() {
    for (var key in _current.keys) {
      _current[key] = (_current[key] ?? AnimationBox.box()) +
          (_path[key] ?? AnimationBox.box()) *
              (100 - (_frontCursor[key] ?? 0)) /
              100;
    }
    _path.clear();
    _frontCursor.clear();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      _setState?.call();
    });
  }

  void setCurrent(
    AnimationBox box, {
    String name = "",
  }) {
    _current[name] = box;
  }

  void setCurrentByNode(T node) {
    edge.update(node);
    _current.clear();
    final map = _nodes[node];
    if (map == null) {
      return;
    }
    for (var key in map.keys) {
      _current[key] = map[key] ?? _current[key] ?? AnimationBox();
    }
  }

  ///指定[_nodes]中的属性盒子，当需要前往某个状态时，
  ///会依据该属性盒子与[_current]规划一条路径
  void setBox(
    T status,
    AnimationBox? box, {
    String name = "",
    CustomCurve? customCurve,
    CustomBoxCurve? customBoxCurve,
    List<AnimationStateEdge<T>>? edges,
    Map<double, AnimationBox>? interpolation,
  }) {
    if (box != null) {
      _nodes[status] ??= {};
      _nodes[status]?[name] = box;
    }
    if (customCurve != null) {
      setCustomCurve(status, name: name, customCurve: customCurve);
    }
    if (customBoxCurve != null) {
      setCustomBoxCurve(status, name: name, customBoxCurve: customBoxCurve);
    }
  }

  void build() {
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback(
      (_) {
        var originCursor = _cursor?.call() ?? 0;
        _current.forEach((key, value) {
          _buildBox(originCursor, key);
        });
        if (originCursor != 100) {
          _animeIsEnd = false;
        }
        if (originCursor == 100 && !_animeIsEnd) {
          _animeIsEnd = true;
          _setState?.call();
        }
      },
    );
  }

  AnimationBox box({String name = ""}) {
    return _current[name] ?? AnimationBox();
  }

  AnimationBox boxWithStatus(T status, {String name = ""}) {
    return _nodes[status]?[name] ?? AnimationBox();
  }

  bool boxExist(
    String name, {
    T? status,
  }) {
    if (status == null) {
      return _current.containsKey(name);
    }
    return _nodes[status]?.containsKey(name) == true;
  }

  AnimationStateMachine();

  void dispose() {
    _setState = null;
    _nodes.clear();
    _curves.clear();
    _current.clear();
    _path.clear();
    _frontCursor.clear();
  }

  void _buildBox(double originCursor, String name) {
    var cursor = originCursor;
    final frontCursor = _frontCursor[name] ?? 0;
    cursor = getCustomCurveCursor(edge.next,
        name: name, progress: cursor, lastProgress: frontCursor);
    _frontCursor[name] = cursor;

    ///路径计算
    final path = _path[name];
    if (path == null) {
      return;
    }
    final oldBox = _current[name] ?? AnimationBox();

    AnimationBox newBox = getCustomCurveBox(
      edge.next,
      name: name,
      oldBox: oldBox,
      path: path,
      progress: cursor,
      lastProgress: frontCursor,
    );

    _current[name] = newBox;
  }
}
