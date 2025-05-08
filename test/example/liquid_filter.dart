import 'dart:io';

import 'package:fc_widgets/filter/liquid_filter.dart';
import 'package:flutter/material.dart';

Widget liquidFilter() {
  return LiquidFilter(
    blurPasses: Platform.isIOS ? 2 : 0,
    colorFilterOpacityFactor: Platform.isIOS ? 10 : 4,
    child: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: circle(
            10,
            color: Colors.white,
          ),
        ),
        Positioned(
          top: 7,
          left: 7,
          child: circle(
            10,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

Widget circle(double size, {Color color = Colors.white}) {
  return Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          blurRadius: 4,
          color: color,
        )
      ],
    ),
  );
}
