## 功能

- 组合动画管理

- 双向列表

- 液态融合效果

- 键盘高度监听

## 开始

本插件命名`fc_widgets`(flutter_complex_widgets),
目的是封装在开发过程中所遇到的一些实现较为困难的UI组件。

具体的向本插件新增功能的实现流程建议保持如下：

- 明确需求，首先在项目代码中对需求组件进行功能实现，确保功能在项目中能处于可用状态。
- 抽象出组件中的实现难点，抽象代码尽可能保持精简，尽可能不在本插件中引入第三方库。
- 在开发过程中持续迭代，进一步简化&完善组件能力。
- 完善本文档，并让文档书写的提交信息以"docs: "作为开头。

## 使用

### Animation - 组合动画管理

#### 创建背景

在项目开发中，需要仿照IOS最新版本(18)的"消息"系统
软件，实现与消息进行交互的消息互动弹窗，动画的复杂程度非常高，我们目前在项目中也只是较为拙劣的模仿。
同时，将动画的控制管理逻辑不断抽象，用于对组合动画进行管理。

目前，从性能、可读性、使用便捷性三个方面，该方案仍然有很大的优化空间。

#### 类说明

- PositionCalculator

  计算“消息”在限定范围内所处位置，并给出平移或缩放建议，与组合动画管理无关，用于物体的起止位置计算。

- AnimationBox

  动画盒子，记录一个物体需要的所有动画属性，并设定它们的四则运算。AnimationBox只给出了一些基础值，如果需要更多的取值，详情参考AnimationBoxCustom。
  目前基础属性包含如下：\
  visible：物体的可见性\
  width： 物体的宽度\
  height：物体的高度\
  opacity：物体的透明度\
  scale：物体的缩放比例\
  offset：物体的偏移\
  line：物体的某一线性取值（可根据自身情况用于不同取值）

- AnimationBoxCustom

  自定义动画盒子的属性，参考代码中`singleColorBox`或者`colorBox`。

- AnimationProgress

  动画进程，对Animation\<double>的封装，同时隐藏`AnimatedBuilder`，使用函数`mount`
  替代对`AnimatedBuilder`的直接使用。

- AnimationStateMachine

  动画状态机，完成对组合动画管理的主要实现。在动画前进过程中，始终记录物体每帧运动后的当前属性。通过此种方式，在从一个动画过程中突然转变为执行另一个动画效果时，保证物体不会发生突变。

- CombineAnimationController

  组合动画控制器，包含物体、物体动画状态结点、事件三个部分。在考虑一个动画过程时，可以将其抽象成起点->
  终点，不同物体从起点出发，经过某种变化（变化取值记为AnimatedBox），达到终点。
  因此，在初始化动画状态时，可以以物体为中心，构建同一个物体在不同动画节点时的属性值；
  或者，也可以以动画节点为中心，构建同一个动画节点下不同物体所具备的属性值。

  CombineAnimationController的使用示例可查看`test/example/animation_controller.dart`

### Custom_list - 双向列表

#### 创建背景

在项目开发中发现，flutter采用的列表加载机制在实现消息列表时，
如果采用自上而下的消息增长方向，消息跳转底部无法直接找到准确的底部位置，每次进入聊天室时都会执行跳转效果；
如果采用自下而上的消息增长方向，消息在不满一屏幕时无法位于顶部。
该项目中的实现按照解决第二个问题的思路对消息列表进行完善，并最终构建成现有的双向列表。

该列表在功能性上接近于 `CustomScrollList`，没有包含任何业务代码，
在长期的迭代开发中逐渐完善解决方案存在的不足，现在仍然存在的不足为：

- 不满一屏幕时的单向列表与超过一屏幕时的双向列表切换时，无法保证列表偏移不发生变化。

- 指定索引的跳转逻辑过于复杂。一方面，使用了大量globalKey进行列表项定位（能否在需要使用时才分配globalKey?）；另一方面，跳转对象位于列表最顶部或最底部时需要特殊处理。

#### 类说明

- MessageListControllerX

  消息列表控制器，支持底部跳转、列表刷新、预设列表数量、预设列表状态等。

    - addScrollNotification
      添加列表滚动监听。

    - refresh
      刷新双向列表，不会改变列表数量。

    - refreshIfStateChange
      如果列表的状态(满一屏幕或者不满一屏幕)发生变化，则进行刷新。

    - correctChildCount
      预修改列表项数量

    - correctState
      预修改列表状态

    - scrollController
      当前状态下的滚动控制器

    - jumpToBottom
      跳转到底部

    - jumpToIndex
      跳转到指定索引位置

    - moveCenter
      移动列表中心，以此保证列表偏移不发生变化

    - getKey
      获取某一索引下的挂载的GlobalKey

- MessageListX

  消息列表

    - controller: MessageListControllerX
      消息列表控制器

    - childCount: int
      子项数量

    - builder: Widget Function(int, GlobalKey)?
      子项构建，（索引，索引指向的GlobalKey）

    - bottomScrollItem: Widget?
      滚动列表的最后一项

    - topScrollItem: Widget?
      滚动列表的首项

    - bottomFixed: Widget?
      固定在列表底部的组件，会在列表底部带上一个滚动的空项

    - topFixed: Widget?
      固定在列表顶部的组件，会在列表顶部带上一个滚动的空项

    - physics: ScrollPhysics?

`Custom_list`的使用示例可参考`test/example/custom_list.dart`

### Filter - 液态融合效果（liquid_filter）

#### 创建背景

在项目开发中，为了仿照IOS最新版本的"消息"软件，需要在flutter中实现与"消息"软件中类似液态融合效果。
在一系列的调查之后，发现一个在Ps中实现液态融合效果的思路——先模糊，再清晰。
通过高斯模糊，将物体外轮廓变糊，将多个物体相交叠放在一起，然后通过比如阈值法将模糊部分便清晰或者移除，
因为物体的模糊部分叠加后能使颜色变得更重,因此重新清晰的图像在接触部分能够形成类似液体的曲线。

该思路出自以下视频：
https://www.bilibili.com/video/BV176421F7gG/?spm_id_from=333.337.search-card.all.click&vd_source=6a4629872e420e5c4262a087263d3bf5

出于性能考虑，可以使用`BoxShadow`构建物体的阴影部分，而`liquid_filter`则是对目标颜色进行阈值判断，
在IOS中形成液态效果。

该方案目前仅适用于IOS,因为系统底层渲染逻辑的不同，在安卓中，无法将阴影的外轮廓变成非常清晰的液体形态，
因此，需要对方法进行进一步改良。不过这种构建液态效果的思路仍具有参考价值。

除此之外，或许可以尝试自定义Shader达到相应的效果（还未开始）：

https://docs.flutter.cn/ui/design/graphics/fragment-shaders

https://github.com/MongkolchaiTue/next_gen_ui

`liquid_filter`的使用示例可参考`test/example/liquid_filter.dart`

### Keyboard_listener - 键盘高度变化监听

#### 创建背景

在部分场景中，我们会需求键盘收起但是UI界面的视图大小不发生变化，此时，需要将`resizeToAvoidBottomInset`
设置为`false`,
并手动实现键盘弹起相关的代码。然而，问题的难点并不在此。
如果我们允许用户快速的在请求焦点&取消焦点间切换，此时，高度键盘的频繁变化会使我们
难以预测键盘高度的走向。
在这一问题的基础之上，我们使用`WidgetsBindingObserver`监听键盘高度变化，并将高度变化的序列抽象为两个特征：
一是对变化前后的大小比较，一是对这种比较序列的归纳。以此，更为细化地评估键盘当前的运动状态。

当前的状态评估`_motionFeatures`仍然存在不足，因为键盘高度变化的情况较多，我们暂未对其进行完全的收集。

#### 类说明

- KeyboardManager

单例，记录键盘的状态变化，最大高度等信息

- AppKeyboardListener

应用键盘监听，只需将其绑定在根页面即可（全局只挂载一个AppKeyboardListener）

- KeyboardSpacer

同步键盘高度变化形成的等高占位组件，允许对`KeyboardSpacer`高度进行锁定与解锁。