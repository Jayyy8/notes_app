import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

/// Picks the right icon type for the running platform.
///
/// * iOS 26+            -> SF Symbol name (rendered natively by UIKit)
/// * iOS 18 and Android -> a [CupertinoIcons] glyph
///
/// adaptive_platform_ui widgets accept either a String or an IconData for
/// menu items and tab destinations, so this one helper keeps every icon valid
/// on every supported OS version.
dynamic adaptiveIcon(String sfSymbol, IconData fallback) {
  return PlatformInfo.isIOS26OrHigher() ? sfSymbol : fallback;
}