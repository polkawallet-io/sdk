import 'package:flutter/cupertino.dart';

/// Define the widget used in polkawallet app home page.
class HomeNavItem {
  HomeNavItem({
    required this.text,
    required this.icon,
    required this.iconActive,
    required this.content,
  });

  /// Text display in BottomNavBar.
  final String text;

  /// Icon display in BottomNavBar.
  final Widget icon;
  final Widget iconActive;

  /// Page content for this nav item.
  final Widget content;
}
