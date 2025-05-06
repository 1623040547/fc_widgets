import 'package:flutter/material.dart';
import 'dart:ui';

class LiquidFilter extends StatelessWidget {
  final Widget? child;
  final double colorFilterOpacityFactor;
  final Color targetColor;
  final double blurSigma;
  final int blurPasses;
  final BlendMode blendMode;

  const LiquidFilter({
    super.key,
    this.child,
    this.colorFilterOpacityFactor = 15,
    this.targetColor = Colors.white,
    this.blurSigma = 1.0,
    this.blurPasses = 3,
    this.blendMode = BlendMode.overlay,
  });

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return const SizedBox();
    }
    final matrix = ColorFilter.matrix([
      ///r
      1, 0, 0, 0, 0,

      ///g
      0, 1, 0, 0, 0,

      ///b
      0, 0, 1, 0, 0,

      ///o
      0, 0, 0, colorFilterOpacityFactor, 0
    ]);

    Widget result = ColorFiltered(colorFilter: matrix, child: child!);

    for (int i = 0; i < blurPasses; i++) {
      result = wrapOverlay(
        child: result,
      );
    }

    return Stack(
      children: [
        ClipRRect(
          child: ColorFiltered(
            colorFilter: matrix,
            child: result,
          ),
        )
      ],
    );
  }

  Widget wrapOverlay({required Widget child}) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 1,
        sigmaY: 1,
      ),
      blendMode: BlendMode.overlay,
      child: child,
    );
  }
}
