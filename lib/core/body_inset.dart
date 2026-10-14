import 'dart:math' as math;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

/// Height of the floating iOS 26 toolbar below the status bar. If content sits
/// too far from the toolbar, lower this number; if it still touches it, raise it.
const double kIOS26ToolbarExtent = 48;

/// Space a page body must leave at the top.
///
/// On iOS 26 the native toolbar floats over the page, so the body has to start
/// below it. On Android and iOS 18 the scaffold already lays the body out below
/// the app bar, so this returns 0.
double bodyTopInset(BuildContext context) {
  if (!PlatformInfo.isIOS26OrHigher()) return 0;

  final systemTop = MediaQueryData.fromView(View.of(context)).padding.top;
  final reportedTop = MediaQuery.paddingOf(context).top;
  return math.max(reportedTop, systemTop + kIOS26ToolbarExtent);
}