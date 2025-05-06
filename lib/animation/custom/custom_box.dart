import 'package:flutter/material.dart';

import '../animation_progress.dart';

final AnimationBoxCustom<double> singleColorBox = AnimationBoxCustom(
  name: 'singleColor',
  value: 0,
  operatorAdd: (double self, double other) => self + other,
  operatorMinus: (double self, double other) => self - other,
  operatorMultiply: (double self, double other) => self * other,
  operatorDivide: (double self, double other) => other == 0 ? 0 : self / other,
);

final AnimationBoxCustom<List<double>> colorBox = AnimationBoxCustom(
  name: 'color',
  value: [0, 0, 0, 1],
  operatorAdd: (List<double> self, List<double> other) => [
    self[0] + other[0],
    self[1] + other[1],
    self[2] + other[2],
    self[3] + other[3],
  ],
  operatorMinus: (List<double> self, List<double> other) => [
    self[0] - other[0],
    self[1] - other[1],
    self[2] - other[2],
    self[3] - other[3],
  ],
  operatorMultiply: (List<double> self, double other) => [
    self[0] * other,
    self[1] * other,
    self[2] * other,
    self[3] * other,
  ],
  operatorDivide: (List<double> self, double other) => [
    self[0] / other,
    self[1] / other,
    self[2] / other,
    self[3] / other,
  ],
);

extension AnimationCustomBoxQuickWidget on AnimationBox {
  Color vSingleColor({double opacity = 1}) {
    final custom = getCustom<double>(singleColorBox.name)?.toInt();
    if (custom == null) {
      return Color.fromRGBO(0, 0, 0, opacity);
    }
    return Color.fromRGBO(custom, custom, custom, opacity);
  }

  Widget wSingleColor(Widget child, {double opacity = 1}) {
    final custom = getCustom<double>(singleColorBox.name)?.toInt();
    if (custom == null) {
      return child;
    }
    return ColoredBox(
      color: Color.fromRGBO(custom, custom, custom, opacity),
      child: child,
    );
  }

  Widget wColor(Widget child) {
    final custom = getCustom<List<double>>(colorBox.name);
    if (custom == null) {
      return child;
    }
    return ColoredBox(
      color: Color.fromRGBO(
        custom[0].toInt(),
        custom[1].toInt(),
        custom[2].toInt(),
        custom[3],
      ),
      child: child,
    );
  }
}
