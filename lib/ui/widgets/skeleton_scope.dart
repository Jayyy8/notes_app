import 'package:flutter/cupertino.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/app_colors.dart';

/// Skeletonizer wrapper whose colors follow the Cupertino light/dark theme.
///
/// Skeletonizer normally reads the Material theme, which doesn't exist on iOS,
/// so we pass the shimmer colors in explicitly.
class SkeletonScope extends StatelessWidget {
  const SkeletonScope({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final base = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final highlight =
    isDark ? const Color(0xFF545458) : const Color(0xFFF2F2F7);

    return Skeletonizer(
      enabled: enabled,
      effect: ShimmerEffect(baseColor: base, highlightColor: highlight),
      containersColor: cardBackground(context),
      child: child,
    );
  }
}