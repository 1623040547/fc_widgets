part of 'message_list.dart';

///单向列表用于处理消息为占满一屏时的页面展示
class UniMessageController extends MessageListInterface {
  final MessageListControllerX controller;

  UniMessageController(this.controller);

  final ScrollController _scrollController = ScrollController();

  @override
  void jumpToBottom({Function()? callBack, double offsetWhenDown = 0}) {
    if (controller._isJumping) {
      return;
    }

    controller._isJumping = true;
    controller.refresh();
    if (controller.scrollController.hasClients) {
      controller.scrollController.jumpTo(
        controller.scrollController.position.minScrollExtent,
      );
    }
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      controller.refresh();
      controller._isJumping = false;
      callBack?.call();
      if (controller.scrollController.hasClients) {
        controller.scrollController.animateTo(
          controller.scrollController.position.minScrollExtent + offsetWhenDown,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void jumpToIndex(int index,
      {Function()? callBack, double offsetWhenDown = 0}) {
    if (controller._isJumping) {
      return;
    }
    final context = controller.getKey(index).currentContext;
    final item = context?.findRenderObject();
    RenderObject? viewport =
        controller._viewportKey.currentContext?.findRenderObject();
    if (item is! RenderBox || !item.hasSize || !item.attached) {
      return;
    }
    if (viewport is! RenderBox || !viewport.hasSize || !viewport.attached) {
      return;
    }
    if (!controller.scrollController.hasClients) {
      return;
    }
    controller._isJumping = true;
    controller.refresh();
    final viewportPosition = viewport.localToGlobal(Offset.zero);
    final itemPosition = item.localToGlobal(Offset.zero);
    final newOffset =
        controller.scrollController.position.pixels + offsetWhenDown;
    final toPosition = viewportPosition.dy -
        itemPosition.dy +
        newOffset -
        item.size.height +
        controller.scrollController.position.viewportDimension;
    if (context != null) {
      controller.refresh();
      controller._isJumping = false;
      callBack?.call();
      controller.scrollController.jumpTo(
        min(toPosition, 0),
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
  void moveCenter(int count) {}

  @override
  void reset() {
    if (_scrollController.hasClients) {
      _scrollController.position.correctPixels(0);
    }
  }
}

class UniMessageList extends StatefulWidget {
  final UniMessageController controller;

  final Widget Function(int index, int childCount)? builder;

  final ScrollPhysics? physics;

  final Widget? bottomFixedSpacer;

  final Widget? topFixedSpacer;

  const UniMessageList({
    super.key,
    required this.controller,
    this.builder,
    this.physics,
    this.bottomFixedSpacer,
    this.topFixedSpacer,
  });

  @override
  createState() => _UniMessageListState();
}

class _UniMessageListState extends State<UniMessageList> {
  MessageListControllerX get mController => controller.controller;

  UniMessageController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final childCount = mController.childCount;
    return CustomScrollView(
      key: mController._contentKey,
      controller: mController.scrollController,
      clipBehavior: Clip.none,
      physics: AlwaysScrollablePhysics(parent: widget.physics),
      anchor: 1,
      center: mController._centerKey,
      reverse: true,
      cacheExtent: mController.maxViewportHeight * 3,
      slivers: [
        SliverToBoxAdapter(child: widget.bottomFixedSpacer ?? Container()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => widget.builder
                ?.call(max(1, childCount) - index - 1, childCount),
            childCount: max(1, childCount),
          ),
        ),
        SliverPadding(
          key: mController._centerKey,
          padding: EdgeInsets.zero,
        ),
        SliverToBoxAdapter(child: widget.topFixedSpacer ?? Container()),
      ],
    );
  }
}
