/// A static image widget — renders an asset or network image with an optional
/// tint. Useful for logos, diagrams, or decorative elements on a dashboard.
library;

import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:flutter/material.dart';

import '../src/cosmetic_helpers.dart';

/// Renders an `image` widget from resolved properties:
///  * `src`      — asset path or URL (String)
///  * `fit`      — BoxFit name (default 'contain')
///  * `tint`     — optional ARGB int colour filter
///  * `opacity`  — optional 0..1
class ImageWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const ImageWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final src = properties['src'] as String?;
    if (src == null) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white54),
      );
    }
    final fit = _boxFit(properties['fit'] as String?);
    final tint = properties['tint'] as int?;
    final opacity = (properties['opacity'] as num?)?.toDouble() ?? 1.0;
    final borderRadiusRaw = (properties['borderRadius'] as num?) ?? 0.0;

    final isUrl = src.startsWith('http://') || src.startsWith('https://');
    final image =
        isUrl ? Image.network(src, fit: fit) : Image.asset(src, fit: fit);

    Widget widget = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: image,
    );
    if (tint != null) {
      widget = ColorFiltered(
        colorFilter: ColorFilter.mode(Color(tint), BlendMode.srcIn),
        child: widget,
      );
    }
    final radius = borderRadiusRaw.toDouble();
    if (radius > 0) {
      widget = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: widget,
      );
    }
    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties).copyWith(
          color: Colors.transparent,
        ),
        padding: resolvePadding(properties),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: widget,
        ),
      ),
      properties,
    );
  }

  BoxFit _boxFit(String? name) => switch (name) {
        'cover' => BoxFit.cover,
        'fill' => BoxFit.fill,
        'fitWidth' => BoxFit.fitWidth,
        'fitHeight' => BoxFit.fitHeight,
        'none' => BoxFit.none,
        _ => BoxFit.contain,
      };
}
