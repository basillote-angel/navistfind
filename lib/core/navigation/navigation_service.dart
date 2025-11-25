import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get rootNavigator => rootNavigatorKey.currentState;

BuildContext? get rootNavigatorContext => rootNavigatorKey.currentContext;



