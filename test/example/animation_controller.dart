// part of 'msgInteraction.dart';

import 'dart:math';

import 'package:fc_widgets/fc_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum MessageAnimationEvent {
  showInteractViewStart,
  showEmojiKeyboardStart,
  emojiKeyboardBackStart,
  showEditViewStart,
  editViewSizeChanged,
  showExitAnimationStart,
  ;
}

enum MessageAnimationStatus {
  originView,
  showInteractView,
  showEmojiKeyboard,
  showDeleteView,
  showEditView,
  showExitAnimation,
  ;

  bool get isOriginView => this == originView;

  bool get isInteractView => this == showInteractView;

  bool get isEmojiKeyboard => this == showEmojiKeyboard;

  bool get isDeleteView => this == showDeleteView;

  bool get isEditView => this == showEditView;

  bool get isExitAnimation => this == showExitAnimation;
}

enum MessageAnimationObject {
  dialogBg,
  msgCell,
  msgEditCell,
  emojiBar,
  emojiCloseBtn,
  emojiBubble,
  emojiIcon,
  emojiItem,
  emojiCircleLarge,
  emojiCircleSmall,
  emojiKeyboard,
  emojiSelector,
  functionBar,
  functionItem,
  deleteBar,
  usingEmojiView,
  ;
}

class MessageAnimationController {
  final controller = CombineAnimationController<MessageAnimationStatus,
          MessageAnimationObject, MessageAnimationEvent>(
      MessageAnimationStatus.values, MessageAnimationObject.values);

  AnimationStateMachine<MessageAnimationStatus> get stateMachine =>
      controller.stateMachine;

  AnimationBox get msgEditCell =>
      controller.box(MessageAnimationObject.msgEditCell);

  AnimationBox get msgCell => controller.box(MessageAnimationObject.msgCell);

  AnimationBox get emojiBar => controller.box(MessageAnimationObject.emojiBar);

  AnimationBox box(MessageAnimationObject object) => controller.box(object);

  AnimationBox boxWithStatus(
          MessageAnimationObject object, MessageAnimationStatus status) =>
      controller.boxWithStatus(object, status);

  void setCurrent(AnimationBox box, MessageAnimationObject object) =>
      controller.setCurrent(box, object);

  MessageAnimationStatus get status =>
      stateMachine.status ?? MessageAnimationStatus.originView;

  ///原始的消息Box位置
  late final Rect origin;

  ///位置移动后的消息Box位置
  late final Rect newOrigin;

  ///编辑状态下的消息Box位置
  late final Rect editOrigin;

  ///展示表情键盘下的消息Box位置
  late final Rect emojiKeyboardOrigin;

  void eventOn(MessageAnimationEvent event, Function callback) =>
      controller.eventOn(event, callback);

  void eventFire(MessageAnimationEvent event) => controller.eventFire(event);

  Widget mount({required Widget Function() builder, Function()? callback}) {
    return controller.mount(
      MessageAnimationStatus.showEditView,
      builder: (fixedChild) => controller.mount(
        MessageAnimationStatus.showInteractView,
        builder: (fixedChild) => controller.mount(
          MessageAnimationStatus.originView,
          builder: (fixedChild) => controller.mount(
            MessageAnimationStatus.showDeleteView,
            builder: (fixedChild) => controller.mount(
              MessageAnimationStatus.showEmojiKeyboard,
              builder: (fixedChild) => controller.mount(
                MessageAnimationStatus.showExitAnimation,
                builder: (fixedChild) {
                  stateMachine.build();
                  return builder.call();
                },
                callback: callback,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void register(
    TickerProvider ticker, {
    Function()? setState,
  }) {
    controller.register(
      ticker,
      progressRegister: (status) {
        switch (status) {
          case MessageAnimationStatus.originView:
            return AnimationProgressConfig(duration: AnimationDuration.short);
          case MessageAnimationStatus.showInteractView:
            return AnimationProgressConfig(duration: AnimationDuration.long);
          case MessageAnimationStatus.showEmojiKeyboard:
            return AnimationProgressConfig(duration: AnimationDuration.long);
          case MessageAnimationStatus.showDeleteView:
            return AnimationProgressConfig(duration: AnimationDuration.medium);
          case MessageAnimationStatus.showEditView:
            return AnimationProgressConfig(duration: AnimationDuration.long);
          case MessageAnimationStatus.showExitAnimation:
            return AnimationProgressConfig(duration: AnimationDuration.long);
        }
      },
      setState: setState,
    );
  }

  void dispose() => controller.dispose();

  bool isRunning(MessageAnimationStatus statys) => controller.isRunning(status);

  void init(
    Rect origin,
    Rect newOrigin,
    Rect editOrigin,
    Rect emojiKeyboardOrigin,
  ) {
    this.origin = origin;
    this.newOrigin = newOrigin;
    this.editOrigin = editOrigin;
    this.emojiKeyboardOrigin = emojiKeyboardOrigin;
    setDialogBg();
    setMsgCell();
    setFunctionBar();
    setFunctionItem();
    setDeleteBar();
    setMsgEditCell();
    setEmojiSelector();
    setEmojiKeyboard();
    setEmojiBar();
    setEmojiItem();
    setEmojiBubble();
    setEmojiIcon();
    setEmojiCircleSmall();
    setEmojiCircleLarge();
    setEmojiCloseBtn();
    stateMachine.setCurrentByNode(MessageAnimationStatus.originView);
  }

  void toShowInteractView() {
    controller.toShow(
      MessageAnimationStatus.showInteractView,
      animateBefore: () {
        controller.setVisible(MessageAnimationObject.deleteBar, false);
        controller.setVisible(MessageAnimationObject.msgEditCell, false);
        eventFire(MessageAnimationEvent.showInteractViewStart);
      },
    );
  }

  void toShowDeleteBar() {
    controller.toShow(
      MessageAnimationStatus.showDeleteView,
      animateBefore: () {
        controller.setVisible(MessageAnimationObject.deleteBar, true);
      },
      animateAfter: () {
        controller.setVisible(MessageAnimationObject.functionBar, false);
      },
    );
  }

  void toShowEmojiSwitch() {
    if (stateMachine.status == MessageAnimationStatus.showEmojiKeyboard) {
      controller.toShow(
        MessageAnimationStatus.showInteractView,
        animateBefore: () {
          controller.setVisible(MessageAnimationObject.functionBar, true);
          controller.setVisible(MessageAnimationObject.deleteBar, false);
          eventFire(MessageAnimationEvent.emojiKeyboardBackStart);
        },
      );
    } else {
      controller.toShow(
        MessageAnimationStatus.showEmojiKeyboard,
        animateBefore: () {
          eventFire(MessageAnimationEvent.showEmojiKeyboardStart);
        },
      );
    }
  }

  void toShowEditView() {
    controller.toShow(MessageAnimationStatus.showEditView, animateBefore: () {
      controller.setVisible(MessageAnimationObject.deleteBar, false);
      controller.setVisible(MessageAnimationObject.functionBar, false);
      controller.setVisible(MessageAnimationObject.msgCell, false);
      controller.setVisible(MessageAnimationObject.emojiSelector, false);
      controller.setVisible(MessageAnimationObject.dialogBg, false);
      controller.setVisible(MessageAnimationObject.emojiBar, false);
      controller.setVisible(MessageAnimationObject.msgEditCell, true);
      eventFire(MessageAnimationEvent.showEditViewStart);
    });
  }

  void toShowExitAnimation({
    Function? animateAfter,
  }) {
    ///展示从表情键盘离场的动画效果
    final bool showExitEmojiKeyboard = status.isEmojiKeyboard &&
        !controller.isRunning(MessageAnimationStatus.showEmojiKeyboard) &&
        newOrigin.height > origin.height;
    if (showExitEmojiKeyboard) {
      eventFire(MessageAnimationEvent.showExitAnimationStart);
      controller.toShow(
        MessageAnimationStatus.showExitAnimation,
        animateAfter: animateAfter,
        duration: AnimationDuration.long.duration,
      );
      return;
    }

    final showExitInteractView = status.isInteractView &&
        !controller.isRunning(MessageAnimationStatus.showInteractView) &&
        newOrigin.height > origin.height;
    if (showExitInteractView) {
      eventFire(MessageAnimationEvent.showExitAnimationStart);
      controller.toShow(
        MessageAnimationStatus.showExitAnimation,
        animateAfter: animateAfter,
        duration: AnimationDuration.long.duration,
      );
      return;
    }

    if (controller.isRunning(MessageAnimationStatus.showInteractView)) {
      eventFire(MessageAnimationEvent.showExitAnimationStart);
    }

    animateAfter?.call();
  }

  void setMsgCell() {
    controller.setBox(MessageAnimationObject.msgCell, (status) {
      switch (status) {
        case MessageAnimationStatus.showExitAnimation:
        case MessageAnimationStatus.originView:
          return AnimationBox.box(
            width: origin.width,
            height: origin.height,
            offset: Offset(origin.left, origin.top),
            scale: 1,
          ).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(
            width: newOrigin.width,
            height: newOrigin.height,
            offset: Offset(newOrigin.left, newOrigin.top),
            scale: newOrigin.height / max(1, origin.height),
          ).detail(
            customCurve: (progress, lastProgress) =>
                min(1, progress / 62.5) * 100,
          );
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(
            width: emojiKeyboardOrigin.width,
            height: emojiKeyboardOrigin.height,
            offset: Offset(emojiKeyboardOrigin.left, emojiKeyboardOrigin.top),
            scale: emojiKeyboardOrigin.height / max(1, origin.height),
          ).detail();
        case MessageAnimationStatus.showEditView:
          return AnimationBox.box(
            width: newOrigin.width,
            height: newOrigin.height,
            offset: Offset(0, editOrigin.top),
          ).detail();
        case MessageAnimationStatus.showDeleteView:
          return null;
      }
    });
  }

  void setFunctionBar() {
    controller.setBox(
      MessageAnimationObject.functionBar,
      (status) {
        switch (status) {
          case MessageAnimationStatus.originView:
          case MessageAnimationStatus.showExitAnimation:
            return AnimationBox.box(
              opacity: 0,
              scale: 0,
              width: 214,
              height: 180,
              line: 12,
            ).detail();
          case MessageAnimationStatus.showInteractView:
            return AnimationBox.box(
              opacity: 1,
              scale: 1,
              width: 214,
              height: 180,
              line: 12,
            ).detail();

          case MessageAnimationStatus.showDeleteView:
            final endBox = AnimationBox.box(
              opacity: 0,
              scale: 1,
              width: 180,
              height: 75,
              line: 16,
            );
            return endBox.detail(customBoxCurve:
                (oldBox, newBox, delta, progress, lastProgress) {
              ///透明度在进度95以前始终为0，以后从0->100
              if (progress < 95) {
                newBox = newBox.copy(opacity: oldBox.opacity);
              } else {
                newBox = newBox.copy(
                  opacity: oldBox.opacity +
                      (-1) *
                          (progress - clampDouble(lastProgress, 95, 100)) /
                          5,
                );
              }

              ///在进度90前完成圆角变化
              if (progress < 90) {
                newBox = newBox.copy(line: oldBox.line + delta.line * 10 / 9);
              } else {
                newBox = newBox.copy(line: endBox.line);
              }

              return newBox;
            });
          case MessageAnimationStatus.showEmojiKeyboard:
            return AnimationBox.box(
              opacity: 0,
              scale: 0,
              width: 214,
              height: 180,
              line: 12,
            ).detail();
          case MessageAnimationStatus.showEditView:
            return null;
        }
      },
    );
  }

  void setFunctionItem() {
    controller.setBox(
      MessageAnimationObject.functionItem,
      (status) {
        switch (status) {
          case MessageAnimationStatus.originView:
          case MessageAnimationStatus.showExitAnimation:
            return AnimationBox.box().detail();
          case MessageAnimationStatus.showInteractView:
            return AnimationBox.box().detail();
          case MessageAnimationStatus.showDeleteView:
            return AnimationBox.box(
              opacity: 0,
            ).detail(
              customCurve: (progress, _) => max(0, (progress - 50)) * 100 / 50,
            );
          case MessageAnimationStatus.showEmojiKeyboard:
          case MessageAnimationStatus.showEditView:
            return null;
        }
      },
    );
  }

  void setDeleteBar() {
    controller.setBox(
      MessageAnimationObject.deleteBar,
      (status) {
        switch (status) {
          case MessageAnimationStatus.originView:
          case MessageAnimationStatus.showExitAnimation:
            return AnimationBox.box(opacity: 0).detail();
          case MessageAnimationStatus.showInteractView:
            return AnimationBox.box(opacity: 0).detail();
          case MessageAnimationStatus.showDeleteView:
            return AnimationBox.box(opacity: 1).detail(
              customCurve: (progress, _) => max(0, (progress - 50)) * 100 / 50,
            );
          case MessageAnimationStatus.showEmojiKeyboard:
            return AnimationBox.box(opacity: 0, scale: 0).detail();
          case MessageAnimationStatus.showEditView:
            return null;
        }
      },
    );
  }

  void setDialogBg() {
    controller.setBox(
      MessageAnimationObject.dialogBg,
      (status) {
        switch (status) {
          case MessageAnimationStatus.originView:
          case MessageAnimationStatus.showEditView:
          case MessageAnimationStatus.showExitAnimation:
            return AnimationBox.box(line: 0).detail();
          case MessageAnimationStatus.showInteractView:
            return AnimationBox.box(line: 6).detail();
          case MessageAnimationStatus.showEmojiKeyboard:
          case MessageAnimationStatus.showDeleteView:
            return null;
        }
      },
    );
  }

  void setEmojiBar() {
    controller.setBox(
      MessageAnimationObject.emojiBar,
      (status) {
        switch (status) {
          case MessageAnimationStatus.originView:
          case MessageAnimationStatus.showExitAnimation:
            return AnimationBox.box(
                width: 20,
                height: 20,
                offset: Offset(origin.width, -46),
                custom: [singleColorBox.copy(255)]).detail();
          case MessageAnimationStatus.showInteractView:
            final endBox = AnimationBox.box(
              width: 32 + 280,
              offset: const Offset(20, -56),
              height: 32 + 4,
              line: 16,
              custom: [singleColorBox.copy(255)],
            );
            return endBox.detail();
          case MessageAnimationStatus.showEmojiKeyboard:
            return AnimationBox.box(
              width: 48,
              height: 48,
              offset: Offset(
                origin.width / 2 + emojiKeyboardOrigin.width / 2 - 10,
                -64,
              ),
              custom: [singleColorBox.copy(238)],
            ).detail();
          case MessageAnimationStatus.showEditView:
          case MessageAnimationStatus.showDeleteView:
            return null;
        }
      },
    );
  }

  void setEmojiIcon() {
    controller.setBox(MessageAnimationObject.emojiIcon, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(
            width: 0,
            height: 0,
            opacity: 0,
            offset: Offset(origin.width + 16, -34),
          ).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(
            width: 28,
            height: 28,
            opacity: 1,
            offset: Offset(origin.width / 2 + newOrigin.width / 2 + 30, -10),
          ).detail();
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(
            width: 48,
            height: 48,
            opacity: 1,
            offset: Offset(
              origin.width / 2 + emojiKeyboardOrigin.width / 2 - 10,
              -64,
            ),
          ).detail();
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
          return null;
      }
    });
  }

  void setEmojiItem() {
    controller.setBox(MessageAnimationObject.emojiItem, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(opacity: 0).detail(
            customCurve: (progress, lastProgress) =>
                min(60, (progress)) * 100 / 60,
          );
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(opacity: 1).detail(
            customCurve: (progress, lastProgress) =>
                max(0, (progress - 40)) * 100 / 60,
          );
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(opacity: 0).detail(
            customCurve: (progress, lastProgress) =>
                min(100, progress * 100 / 40),
          );
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
          return null;
      }
    });
  }

  void setEmojiBubble() {
    controller.setBox(MessageAnimationObject.emojiBubble, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(
            width: 0,
            height: 0,
            offset: Offset(origin.width + 16, -34),
          ).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(
            width: 8,
            height: 8,
            offset: Offset(origin.width / 2 + newOrigin.width / 2 + 40, 0),
          ).detail();
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(
            width: 0,
            height: 0,
            offset: Offset(
              origin.width / 2 + emojiKeyboardOrigin.width / 2 + 18,
              -30,
            ),
          ).detail();
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
          return null;
      }
    });
  }

  void setEmojiCircleSmall() {
    controller.setBox(MessageAnimationObject.emojiCircleSmall, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(
            width: 2,
            height: 2,
            offset: Offset(origin.width + 16, -34),
          ).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(
            width: 3,
            height: 3,
            offset: Offset(origin.width / 2 + newOrigin.width / 2 + 65, 35),
          ).detail();
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(
            width: 4,
            height: 4,
            offset: Offset(
                origin.width / 2 + emojiKeyboardOrigin.width / 2 + 46, 0),
          ).detail();
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
          return null;
      }
    });
  }

  void setEmojiCloseBtn() {
    controller.setBox(MessageAnimationObject.emojiCloseBtn, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(scale: 0, opacity: 0).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(scale: 0, opacity: 0).detail();
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(
            scale: 1,
            opacity: 1,
            offset: const Offset(-25, -20),
          ).detail();
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
          return null;
      }
    });
  }

  void setEmojiCircleLarge() {
    controller.setBox(MessageAnimationObject.emojiCircleLarge, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(
            width: 3,
            height: 3,
            offset: Offset(origin.width + 16, -34),
          ).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(
            width: 8,
            height: 8,
            offset: Offset(origin.width / 2 + newOrigin.width / 2 + 52, 18),
          ).detail();
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(
            width: 12,
            height: 12,
            offset: Offset(
                origin.width / 2 + emojiKeyboardOrigin.width / 2 + 30, -20),
          ).detail();
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
          return null;
      }
    });
  }

  void setEmojiSelector() {
    controller.setBox(MessageAnimationObject.emojiSelector, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(
            opacity: 0,
            scale: 0,
            offset: Offset(0, newOrigin.top),
          ).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(
            opacity: 1,
            scale: 1,
            offset: Offset(0, newOrigin.top),
          ).detail();
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(
            opacity: 1,
            scale: 1,
            offset: Offset(0, emojiKeyboardOrigin.top),
          ).detail();
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
          return null;
      }
    });
  }

  void setEmojiKeyboard() {
    controller.setBox(MessageAnimationObject.emojiKeyboard, (status) {
      switch (status) {
        case MessageAnimationStatus.originView:
        case MessageAnimationStatus.showDeleteView:
        case MessageAnimationStatus.showEditView:
        case MessageAnimationStatus.showExitAnimation:
          return AnimationBox.box(offset: const Offset(0, -272)).detail();
        case MessageAnimationStatus.showInteractView:
          return AnimationBox.box(offset: const Offset(0, -272)).detail();
        case MessageAnimationStatus.showEmojiKeyboard:
          return AnimationBox.box(offset: const Offset(0, 0)).detail();
      }
    });
  }

  void setMsgEditCell() {
    controller.setBox(
      MessageAnimationObject.msgEditCell,
      (status) {
        switch (status) {
          case MessageAnimationStatus.originView:
            return AnimationBox.box(
              width: newOrigin.width,
              height: newOrigin.height,
              offset: Offset(20, newOrigin.top),
              opacity: 1,
              scale: 1,
              line: 0,
              visible: false,
              custom: [singleColorBox.copy(255)],
            ).detail();
          case MessageAnimationStatus.showEditView:
            return AnimationBox.box(
              width: editOrigin.width,
              height: editOrigin.height,
              offset: Offset(0, editOrigin.top),
              opacity: 0,
              line: 44,
              scale: editOrigin.height / max(1, newOrigin.height),
              custom: [singleColorBox.copy(51)],
            ).detail();
          case MessageAnimationStatus.showInteractView:
          case MessageAnimationStatus.showEmojiKeyboard:
          case MessageAnimationStatus.showDeleteView:
          case MessageAnimationStatus.showExitAnimation:
            return null;
        }
      },
    );
  }
}
