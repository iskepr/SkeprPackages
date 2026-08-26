import "package:flutter/material.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";

class Loading extends StatelessWidget {
  const Loading({super.key, this.size = 30, this.color = Colors.grey});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(size / 2),
      child: LoadingAnimationWidget.fourRotatingDots(color: color, size: size),
    );
  }
}
