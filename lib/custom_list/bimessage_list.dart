part of 'message_list.dart';

class BiMessageController extends MessageListInterface {
  final MessageListControllerX controller;

  BiMessageController(this.controller);

  final ScrollController _scrollController = ScrollController();

  final int pointEdge = 20;

  int _point = 0;

  double _anchor = 0;

  int get point => max(0, _point);

  @override
  void jumpToBottom({Function()? callBack, double offsetWhenDown = 0}) {
    jumpToIndex(0, callBack: callBack, offsetWhenDown: offsetWhenDown);
  }

  ///跳转到指定索引位置
  @override
  void jumpToIndex(int index,
      {Function()? callBack, double offsetWhenDown = 0}) {
    final realChildCount = controller._childCount;

    if (controller._isJumping || index < 0 || index >= realChildCount) {
      return;
    }

    if (index == 0) {
      _jumpToIndexDown(index, callBack: callBack, offset: offsetWhenDown);
      return;
    }

    if (realChildCount <= pointEdge) {
      _jumpToIndex(index, callBack: callBack, offset: offsetWhenDown);
      return;
    }

    if (realChildCount - index > pointEdge) {
      _jumpToIndexDown(index, callBack: callBack, offset: offsetWhenDown);
    } else {
      ///_anchor设置为1时，offset不生效
      _jumpToIndexUp(index, callBack: callBack);
    }
  }

  ///跳转到指定索引位置，索引靠近列表的下半部分，此时[_anchor]设置为0
  void _jumpToIndexDown(int index, {Function()? callBack, double offset = 0}) {
    controller._jumpingFoldCount = controller.initialJumpingFoldCount + index;
    _point = index;
    _anchor = 0;
    controller._isJumping = true;
    controller.refresh();
    _jumpToSelector(offset);
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      controller.refresh();
      controller._isJumping = false;
      controller._jumpingFoldCount = controller.initialJumpingFoldCount;
      callBack?.call();
    });
  }

  ///跳转到指定索引位置，索引靠近列表的上半部分，此时[_anchor]需要设置为1
  void _jumpToIndexUp(int index, {Function()? callBack}) {
    controller._jumpingFoldCount = controller.initialJumpingFoldCount + index;
    _point = min(controller._childCount, index + 1);
    _anchor = 1;
    controller._isJumping = true;
    controller.refresh();
    _jumpToSelector(0);
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      controller.refresh();
      controller._isJumping = false;
      callBack?.call();
      controller._jumpingFoldCount = controller.initialJumpingFoldCount;
    });
  }

  void _jumpToIndex(int index,
      {Function()? callBack, double offset = 0, int retryCounter = 0}) {
    if (controller._isJumping) {
      return;
    }
    final context = controller.getKey(index).currentContext;
    final item = context?.findRenderObject();
    RenderObject? viewport =
        controller._viewportKey.currentContext?.findRenderObject();
    if (item is! RenderBox || !item.hasSize || !item.attached) {
      _jumpToIndexRetry(index,
          callBack: callBack, offset: offset, retryCounter: retryCounter);
      return;
    }
    if (viewport is! RenderBox || !viewport.hasSize || !viewport.attached) {
      _jumpToIndexRetry(index,
          callBack: callBack, offset: offset, retryCounter: retryCounter);
      return;
    }
    if (!controller.scrollController.hasClients) {
      _jumpToIndexRetry(index,
          callBack: callBack, offset: offset, retryCounter: retryCounter);
      return;
    }

    controller._isJumping = true;
    controller.refresh();

    final viewportPosition = viewport.localToGlobal(Offset.zero);
    final itemPosition = item.localToGlobal(Offset.zero);
    final newOffset = controller.scrollController.position.pixels + offset;
    final toPosition = viewportPosition.dy -
        itemPosition.dy +
        newOffset -
        item.size.height +
        controller.scrollController.position.viewportDimension;
    if (context != null) {
      controller.refresh();
      controller._isJumping = false;
      callBack?.call();
      _jumpToSelector(
        min(toPosition, controller.scrollController.position.maxScrollExtent),
        useAnimation: retryCounter != 0,
      );
    }
  }

  ///跳转重试，当需要重新构建列表时，可以选择将`MessageListControllerX`中的所有`_indexKeys`清空，
  ///此时执行指定索引跳转便会进入重试状态，触发重试之后`useAnimation`将被设置为`true`。
  void _jumpToIndexRetry(int index,
      {Function()? callBack, double offset = 0, int retryCounter = 0}) {
    if (retryCounter >= 30) {
      return;
    }
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      retryCounter++;
      _jumpToIndex(
        index,
        callBack: callBack,
        offset: offset,
        retryCounter: retryCounter,
      );
    });
  }

  ///选择跳转时是否使用动画，当需要将列表进行更换的同时进行跳转操作时，
  ///列表更换会使原有的列表偏移变为0，此时若再跳转到其它位置，若不使用动画，跳转过程会呈现出2帧。
  ///第一帧是偏移为0的位置，第二帧才是跳转位置，此时将直接跳转改为动画跳转，使过渡更平滑。
  void _jumpToSelector(double offset, {bool useAnimation = false}) {
    if (!controller.scrollController.hasClients) {
      return;
    }

    if (useAnimation) {
      controller.scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    } else {
      controller.scrollController.jumpTo(
        offset,
      );
    }
  }

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
  }

  @override
  void moveCenter(int count) {
    _point += count;
  }

  @override
  void reset() {
    _point = 0;
    _anchor = 0;
    if (_scrollController.hasClients) {
      _scrollController.position.correctPixels(0);
    }
  }
}

///消息列表，从下往上进行消息排列（列表是反向的）
class BiMessageList extends StatefulWidget {
  final BiMessageController controller;

  final Widget Function(int index, int childCount)? builder;

  final ScrollPhysics? physics;

  final Widget? bottomFixedSpacer;

  final Widget? topFixedSpacer;

  const BiMessageList({
    super.key,
    required this.controller,
    this.builder,
    this.physics,
    this.bottomFixedSpacer,
    this.topFixedSpacer,
  });

  @override
  createState() => _BiMessageListState();
}

class _BiMessageListState extends State<BiMessageList>
    with SingleTickerProviderStateMixin {
  MessageListControllerX get mController => controller.controller;

  BiMessageController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final childCount = mController.childCount;
    return CustomScrollView(
      key: mController._contentKey,
      controller: mController.scrollController,
      clipBehavior: Clip.none,
      physics: widget.physics,
      anchor: controller._anchor,
      cacheExtent: mController.maxViewportHeight * 2,
      reverse: true,
      center: mController._centerKey,
      slivers: [
        SliverToBoxAdapter(child: widget.bottomFixedSpacer ?? Container()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => widget.builder?.call(
              controller.point - index - 1,
              childCount,
            ),
            childCount: controller.point,
          ),
        ),
        SliverPadding(
          key: mController._centerKey,
          padding: EdgeInsets.zero,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) =>
                widget.builder?.call(index + controller.point, childCount),
            childCount: childCount - controller.point,
          ),
        ),
        SliverToBoxAdapter(child: widget.topFixedSpacer ?? Container()),
      ],
    );
  }
}
