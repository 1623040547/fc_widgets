import 'dart:math';

import 'package:fc_widgets/custom_list/message_list.dart';
import 'package:flutter/material.dart';

class CustomMessageList extends StatefulWidget {
  const CustomMessageList({super.key});

  @override
  State<StatefulWidget> createState() => _CustomMessageListState();
}

class _CustomMessageListState extends State<CustomMessageList> {
  final MessageListControllerX controller = MessageListControllerX();

  final List<String> messages = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  ///[MessageListX]为反向列表，加载旧消息（顶部）则需要放入[messages]的尾部
  void onLoadOlder() {
    messages.addAll(
      List.generate(
        Random().nextInt(100),
        (index) => "0" * Random().nextInt(100),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  ///[MessageListX]为反向列表，加载旧新消息（底部）则需要放入[messages]的首部
  void onLoadNewer() {
    final itemCount = Random().nextInt(100);
    messages.insertAll(
      0,
      List.generate(
        itemCount,
        (index) => "0" * Random().nextInt(100),
      ),
    );

    ///加载底部区消息时，为了保证偏移不发生变化调用`moveCenter`
    controller.moveCenter(itemCount);

    if (mounted) {
      setState(() {});
    }
  }

  void scrollToBottom() {
    ///跳转至消息最底部，同时增加一个底部固定位置高度的偏移
    controller.jumpToBottom(
      offsetWhenDown: -controller.bottomFixedHeight,
    );
  }

  void scrollToIndex() {
    controller.jumpToIndex(5);
  }

  Rect? getItemRect() {
    final key = controller.getKey(0);
    final item = key.currentContext?.findRenderObject();
    if (item is! RenderBox || !item.hasSize || !item.attached) {
      return null;
    }
    final offset = item.localToGlobal(Offset.zero);
    final size = item.size;
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  @override
  Widget build(BuildContext context) {
    return MessageListX(
      controller: controller,
      builder: (index, globalKey) => testItem(index, globalKey),
      childCount: messages.length,
      bottomFixed: Container(height: 100),
    );
  }

  Widget testItem(int index, GlobalKey key) => Container(
        color: Colors.blue,
        height: 100,
        width: 100,
        child: Container(
          key: key,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          height: 50,
          width: 50,
        ),
      );
}
