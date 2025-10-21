import 'package:navistfind/core/navigation/navigation_bar_app.dart';
import 'package:flutter/material.dart';

class NavigationWrapper extends StatelessWidget {
  final int initialIndex;
  final int lostFoundInitialTabIndex;
  const NavigationWrapper({
    super.key,
    this.initialIndex = 0,
    this.lostFoundInitialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarApp(
      initialIndex: initialIndex,
      lostFoundInitialTabIndex: lostFoundInitialTabIndex,
    );
  }
}
