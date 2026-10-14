import 'package:flutter/cupertino.dart';

/// App accent color (iOS system orange).
///
/// A plain [Color] on purpose: the native iOS 26 toolbar and tab bar receive it
/// as a fixed value and can't resolve a dynamic color.
const Color kAccent = Color(0xFFFF9500);

Color groupedBackground(BuildContext context) =>
    CupertinoColors.systemGroupedBackground.resolveFrom(context);

Color cardBackground(BuildContext context) =>
    CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

Color primaryLabel(BuildContext context) =>
    CupertinoColors.label.resolveFrom(context);

Color secondaryLabel(BuildContext context) =>
    CupertinoColors.secondaryLabel.resolveFrom(context);

Color tertiaryLabel(BuildContext context) =>
    CupertinoColors.tertiaryLabel.resolveFrom(context);