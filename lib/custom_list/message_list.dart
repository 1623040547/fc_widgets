import 'dart:async';
import 'dart:math';
import 'package:fc_widgets/fc_widgets.dart';
import 'package:flutter/material.dart';

part 'unimessage_list.dart';
part 'bimessage_list.dart';

abstract class MessageListInterface {
  ///跳转消息列表底部,
  /// - callBack: 跳转底部后回调
  /// - offsetWhenDown：当列表的`anchor`为0时，允许指定一个额外的偏移量，跳转时会加上这个偏移量
  void jumpToBottom({Function()? callBack, double offsetWhenDown = 0});

  ///跳转指定索引的消息，用于支持定向跳转
  void jumpToIndex(int index,
      {Function()? callBack, double offsetWhenDown = 0});

  ///移动消息列表中心位置，用于支持双向加载
  ///移动中心位置后，应该保证下一帧率时列表项数量大于等于中心位置
  void moveCenter(int count);

  ScrollController get scrollController;

  void dispose();

  /// 列表控制信息重置
  void reset();
}

enum MessageListState {
  unidirectional,
  bidirectional;

  bool get isSingle => this == unidirectional;
}

/// - [jumpingFoldCount] : 跳转底部时会将消息列表临时折叠(如列表有100项，跳转时实际只展示[jumpingFoldCount])
/// - [addScrollNotification] : 添加了列表滚动监听
/// - [jumpToBottom] : 跳转列表底部
/// - [dispose] : 控制器销毁
class MessageListControllerX extends MessageListInterface {
  MessageListState _state = MessageListState.unidirectional;

  UniMessageController? _uniMessageController;

  UniMessageController get _uniController =>
      _uniMessageController ??= UniMessageController(this);

  BiMessageController? _biMessageController;

  BiMessageController get _biController =>
      _biMessageController ??= BiMessageController(this);

  ///列表视图
  final GlobalKey _viewportKey = GlobalKey();

  ///列表内容
  final GlobalKey _contentKey = GlobalKey();

  //列表中心
  final GlobalKey _centerKey = GlobalKey();

  ///列表最底部固定部分
  final _bottomFixedKey = GlobalKey();

  ///列表最顶部固定部分
  final _topFixedKey = GlobalKey();

  ///尺寸变化监听
  final UniqueKey _measureTopKey = UniqueKey();
  final UniqueKey _measureBottomKey = UniqueKey();
  final UniqueKey _measureContentKey = UniqueKey();

  ///列表子项定位
  final Map<int, GlobalKey> _indexKeys = {};

  ///对[MessageListX]组件进行实时刷新
  Function()? _setState;

  ///滚动监听
  Function()? _onScrollNotification;

  ///列表是否已经构建
  bool _isBuild = false;

  ///预测列表是否已经开始展示
  bool _isCheck = false;

  ///列表是否正在跳转
  bool _isJumping = false;

  ///最大的视图高度
  double _maxViewportHeight = 0;

  ///实际的子项数量
  int _childCount = 0;

  final int initialJumpingFoldCount = 15;

  ///跳转折叠组件数量，当列表过长时能够使跳转无卡顿
  int _jumpingFoldCount = 15;

  ScrollPosition? _position;

  ScrollPhysics? _physics;

  Size? _oldViewport;

  MessageListControllerX();

  MessageListState get state => _state;

  ///UI绘制实际展示的子组件数量
  int get childCount {
    if (_isJumping) {
      return min(_jumpingFoldCount, _childCount);
    }
    return _childCount;
  }

  ///列表中使用的底部固定高度,与组件实际高度分离以进行延迟计算，实现组件高度与占位高度的同步变化
  double _bottomFixedHeight = 0;

  ///组件实际的底部固定高度
  double get bottomFixedHeight {
    RenderObject? object = _bottomFixedKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) {
      return 0;
    }
    return object.size.height;
  }

  double _topFixedHeight = 0;

  double get topFixedHeight {
    RenderObject? object = _topFixedKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) {
      return 0;
    }
    return object.size.height;
  }

  void setMaxViewportHeight() {
    _maxViewportHeight = max(_maxViewportHeight, viewportHeight ?? 0);
  }

  ///列表最大的视图展示高度
  double get maxViewportHeight {
    setMaxViewportHeight();
    return _maxViewportHeight;
  }

  ///列表的视图展示高度
  double? get viewportHeight {
    RenderObject? object = _viewportKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) {
      return null;
    }

    return object.size.height;
  }

  ///列表的内容展示区域高度
  double? get contentHeight {
    if (scrollController.hasClients) {
      _position = scrollController.position;
    }
    final position = _position;
    if (position != null) {
      return position.extentTotal - _bottomFixedHeight - _topFixedHeight;
    }
    return null;
  }

  ///与正轴最远端的距离
  double? get positiveDistance {
    if (!scrollController.hasClients) {
      return null;
    }
    final position = scrollController.position;

    return position.maxScrollExtent - position.pixels;
  }

  ///与负轴最远端的距离
  double? get negativeDistance {
    if (!scrollController.hasClients) {
      return null;
    }
    final position = scrollController.position;

    return position.pixels - position.minScrollExtent;
  }

  bool get inDown {
    switch (_state) {
      case MessageListState.unidirectional:
        return true;
      case MessageListState.bidirectional:
        return _biController._anchor == 0;
    }
  }

  bool get isJumping => _isJumping;

  int get point => _biController.point;

  ///仅保存最新添加的监听
  void addScrollNotification(Function()? call) {
    _onScrollNotification = call;
  }

  @override
  void dispose() {
    _uniController.dispose();
    _biController.dispose();
  }

  ///当列表高度不足时，该函数会重新计算列表布局
  void refresh() {
    _checkMessageState();
    _setState?.call();
  }

  void refreshIfStateChange() {
    if (_checkMessageState()) {
      _setState?.call();
    }
  }

  ///是否允许使用双向列表
  bool get useBiMessage => _isBuild && _isOverViewport;

  ///列表内容是否超出最大视图
  bool get _isOverViewport => (contentHeight ?? 0) > maxViewportHeight;

  bool _checkMessageState() {
    if (useBiMessage && _state == MessageListState.unidirectional) {
      return _changeState(MessageListState.bidirectional);
    }

    if (!useBiMessage && _state == MessageListState.bidirectional) {
      return _changeState(MessageListState.unidirectional);
    }

    return false;
  }

  bool _changeState(MessageListState state) {
    if (state == _state) {
      return false;
    }
    _state = state;
    switch (_state) {
      case MessageListState.unidirectional:
        if (_biController.scrollController.hasClients) {
          _biController.scrollController.position.correctPixels(0);
        }
        break;
      case MessageListState.bidirectional:
        if (_uniController.scrollController.hasClients) {
          _uniController.scrollController.position.correctPixels(0);
        }
        break;
    }
    return true;
  }

  void correctChildCount(int childCount) {
    _childCount = childCount;
    _indexKeys.clear();
  }

  void correctState(MessageListState state) {
    _state = state;
  }

  ///滚动控制器
  @override
  ScrollController get scrollController {
    switch (_state) {
      case MessageListState.unidirectional:
        return _uniController.scrollController;
      case MessageListState.bidirectional:
        return _biController.scrollController;
    }
  }

  ///跳转至列表最底部
  @override
  void jumpToBottom({Function()? callBack, double offsetWhenDown = 0}) async {
    switch (_state) {
      case MessageListState.unidirectional:
        _uniController.jumpToBottom(
            callBack: callBack, offsetWhenDown: offsetWhenDown);
        break;
      case MessageListState.bidirectional:
        _biController.jumpToBottom(
            callBack: callBack, offsetWhenDown: offsetWhenDown);
        break;
    }
  }

  ///跳转至指定索引位置
  @override
  void jumpToIndex(int index,
      {Function()? callBack, double offsetWhenDown = 0}) {
    switch (_state) {
      case MessageListState.unidirectional:
        _uniController.jumpToIndex(index,
            callBack: callBack, offsetWhenDown: offsetWhenDown);
        break;
      case MessageListState.bidirectional:
        _biController.jumpToIndex(index,
            callBack: callBack, offsetWhenDown: offsetWhenDown);
        break;
    }
  }

  @override
  void moveCenter(int count) {
    switch (_state) {
      case MessageListState.unidirectional:
        _uniController.moveCenter(count);
        break;
      case MessageListState.bidirectional:
        _biController.moveCenter(count);
        break;
    }
  }

  @override
  void reset() {
    _isBuild = false;
    _isCheck = false;
    _maxViewportHeight = 0;
    switch (_state) {
      case MessageListState.unidirectional:
        _uniController.reset();
        break;
      case MessageListState.bidirectional:
        _biController.reset();
        break;
    }
  }

  GlobalKey getKey(int index) {
    return _indexKeys[index] ??= GlobalKey();
  }

  void moveHeight(double offset) {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.offset + offset);
    }
  }

  void animeMoveHeight(double offset,
      {required Duration duration, required Curve curve}) {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.offset + offset,
        duration: duration,
        curve: curve,
      );
    }
  }

  double exceed(double offset) {
    if (scrollController.hasClients) {
      final pixel = scrollController.offset;
      final minExtent = scrollController.position.minScrollExtent;
      final maxExtent = scrollController.position.maxScrollExtent;
      if (pixel + offset < minExtent) {
        return (pixel + offset) - minExtent;
      }
      if (pixel + offset > maxExtent) {
        return (pixel + offset) - maxExtent;
      }
    }
    return 0;
  }
}

///消息列表，从下往上进行消息排列（列表是反向的）
class MessageListX extends StatefulWidget {
  final MessageListControllerX controller;

  final int childCount;

  ///如果想要跳转到固定索引位置，请挂载GlobalKey
  final Widget Function(int, GlobalKey)? builder;

  ///滚动列表的最后一项
  final Widget? bottomScrollItem;

  ///滚动列表的第一项
  final Widget? topScrollItem;

  ///固定在列表底部的非滚动组件，在滚动列表中会同时生成一个与之高度对应的占位组件
  ///但因为只有渲染之后才能得到组件高度，会存在延迟
  final Widget? bottomFixed;

  ///固定在列表顶部部的非滚动组件
  final Widget? topFixed;

  final ScrollPhysics? physics;

  const MessageListX({
    super.key,
    required this.controller,
    this.builder,
    this.bottomFixed,
    this.bottomScrollItem,
    this.topFixed,
    this.topScrollItem,
    this.childCount = 0,
    this.physics,
  });

  @override
  createState() => _MessageListXState();
}

class _MessageListXState extends State<MessageListX>
    with SingleTickerProviderStateMixin {
  MessageListControllerX get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller._setState = () {
      if (mounted) {
        setState(() {});
      }
    };
    controller._physics = widget.physics;
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      controller.refresh();
    });
  }

  bool onScrollNotification(ScrollNotification scrollNotification) {
    if (scrollNotification.metrics.axis == Axis.vertical) {
      controller._onScrollNotification?.call();
    }
    return true;
  }

  void onSizeChanged(Size? size) {
    controller.refresh();
  }

  void onViewportChanged(Size? size) {
    controller.refreshIfStateChange();
    final double oldHeight = controller._oldViewport?.height ?? 0;
    final double newHeight = size?.height ?? 0;
    final scroll = controller.scrollController;
    if (controller.state.isSingle &&
        oldHeight > newHeight &&
        scroll.hasClients) {
      scroll.position.correctPixels(
        scroll.position.minScrollExtent,
      );
    }
    controller._oldViewport = size;
  }

  void _firstBuild() {
    if (controller._isBuild) {
      return;
    }
    controller._isBuild = true;
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      controller.refresh();
      _checkDelay();
    });
  }

  void _checkDelay() {
    if (controller.contentHeight == null ||
        controller.maxViewportHeight == 0 ||
        controller.contentHeight == 0 ||
        controller.childCount == 0) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _checkDelay();
      });
      return;
    }
    controller._isCheck = true;
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (controller._childCount != widget.childCount) {
      controller.refreshIfStateChange();
    }

    if (controller._bottomFixedHeight != controller.bottomFixedHeight) {
      controller._bottomFixedHeight = controller.bottomFixedHeight;
    }

    if (controller._topFixedHeight != controller.topFixedHeight) {
      controller._topFixedHeight = controller.topFixedHeight;
    }

    controller.setMaxViewportHeight();

    controller._childCount = widget.childCount;

    return Stack(
      clipBehavior: Clip.none,
      key: controller._viewportKey,
      children: [
        Positioned.fill(
          child: MeasureSize(
            key: controller._measureContentKey,
            Stack(
              clipBehavior: Clip.none,
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: onScrollNotification,
                  child: widget.childCount == 0
                      ? noItemBuilder()
                      : AnimatedOpacity(
                          opacity: controller._isCheck ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: messageListSelector(),
                        ),
                ),
              ],
            ),
            onViewportChanged,
          ),
        ),
        Positioned(
          bottom: 0,
          child: SizedBox(
            height: controller._bottomFixedHeight,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              reverse: true,
              child: MeasureSize(
                key: controller._measureBottomKey,
                Container(
                  key: controller._bottomFixedKey,
                  child: bottomFixed(),
                ),
                onSizeChanged,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: SizedBox(
            height: controller._topFixedHeight,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: MeasureSize(
                key: controller._measureTopKey,
                Container(
                  key: controller._topFixedKey,
                  child: topFixed(),
                ),
                onSizeChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget bottomFixed() {
    return Container(
      child: widget.bottomFixed ?? Container(),
    );
  }

  Widget topFixed() {
    return Container(
      child: widget.topFixed ?? Container(),
    );
  }

  Widget itemBuilder(int index, int childCount) {
    if (index < 0 || index >= childCount) {
      return Container();
    }
    Widget item = widget.builder?.call(index, controller.getKey(index)) ??
        Container(key: controller.getKey(index));
    if (index == 0) {
      item = Column(
        children: [
          item,
          widget.bottomScrollItem ?? Container(),
        ],
      );
    }
    if (index == childCount - 1) {
      item = Column(
        children: [
          widget.topScrollItem ?? Container(),
          item,
        ],
      );
    }
    return item;
  }

  Widget noItemBuilder() {
    return CustomScrollView(
      physics: AlwaysScrollablePhysics(parent: controller._physics),
      reverse: true,
      clipBehavior: Clip.none,
      center: controller._centerKey,
      anchor: 1,
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate(
            [
              widget.bottomScrollItem ?? Container(),
              widget.topScrollItem ?? Container(),
            ],
          ),
        ),
        SliverPadding(
          key: controller._centerKey,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget messageListSelector() {
    _firstBuild();
    switch (controller._state) {
      case MessageListState.unidirectional:
        return UniMessageList(
          controller: controller._uniController,
          physics: controller._isCheck ? controller._physics : null,
          builder: itemBuilder,
          bottomFixedSpacer: bottomFixedSpacer(),
          topFixedSpacer: topFixedSpacer(),
        );
      case MessageListState.bidirectional:
        return BiMessageList(
          controller: controller._biController,
          physics: controller._isCheck ? controller._physics : null,
          builder: itemBuilder,
          bottomFixedSpacer: bottomFixedSpacer(),
          topFixedSpacer: topFixedSpacer(),
        );
    }
  }

  Widget bottomFixedSpacer() {
    return SizedBox(height: controller._bottomFixedHeight);
  }

  Widget topFixedSpacer() {
    return SizedBox(height: controller._topFixedHeight);
  }
}

class AlwaysScrollablePhysics extends ScrollPhysics {
  const AlwaysScrollablePhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AlwaysScrollablePhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}
