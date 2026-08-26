import "package:flutter/material.dart";

class NavBarEntity {
  final String title;
  final IconData icon;
  final Widget? widget;
  final bool isRight;
  final bool isWidget;
  final Function? onPressed;

  NavBarEntity({
    required this.title,
    required this.icon,
    this.widget,
    this.isRight = false,
    this.isWidget = true,
    this.onPressed,
  });
}
