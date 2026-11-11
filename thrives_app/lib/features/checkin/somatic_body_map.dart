import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'somatic_map.dart';

/// Anatomical silhouette. Hitboxes use the SVG viewBox, then scale with it.
///
/// [canvas] is `assets/vectors/anatomy_silhouette.svg` viewBox (200 by 420).
/// A region is a rectangle in that same pixel space. At layout time each edge
/// is multiplied by the drawn width or height, so the target stays on the
/// same part of the figure when the widget changes size. Keep the widget's
/// aspect ratio equal to [canvas] and load the SVG with [BoxFit.fill].
class SomaticBodyMap extends StatelessWidget {
  final Map<SomaticZone, SomaticQuality> marks;
  final ValueChanged<SomaticZone> onTap;

  const SomaticBodyMap({
    super.key,
    required this.marks,
    required this.onTap,
  });

  static const asset = 'assets/vectors/anatomy_silhouette.svg';
  static const canvas = Size(200, 420);

  /// ViewBox rectangles. Head sits on the skull, throat on the neck,
  /// chest on the upper torso, stomach below the ribs.
  static const regions = <SomaticZone, Rect>{
    SomaticZone.head: Rect.fromLTWH(66, 14, 68, 76),
    SomaticZone.throat: Rect.fromLTWH(82, 82, 36, 42),
    SomaticZone.chest: Rect.fromLTWH(72, 136, 56, 92),
    SomaticZone.stomach: Rect.fromLTWH(70, 232, 60, 84),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(180.0, 280.0);
        final height = width * canvas.height / canvas.width;
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                SvgPicture.asset(
                  asset,
                  width: width,
                  height: height,
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
                for (final zone in SomaticZone.values)
                  _glow(zone, width, height),
                for (final zone in SomaticZone.values)
                  _zoneTarget(zone, width, height),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _glow(SomaticZone zone, double width, double height) {
    final quality = marks[zone] ?? SomaticQuality.unmarked;
    final color = _glowColor(quality);
    if (color == null) return const SizedBox.shrink();

    final rect = _placed(regions[zone]!, width, height);
    final pad = rect.shortestSide * 0.42;
    return Positioned(
      left: rect.left - pad,
      top: rect.top - pad,
      width: rect.width + pad * 2,
      height: rect.height + pad * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.55),
                color.withValues(alpha: 0.20),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _zoneTarget(SomaticZone zone, double width, double height) {
    final rect = _placed(regions[zone]!, width, height);
    final quality = marks[zone] ?? SomaticQuality.unmarked;
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Semantics(
        button: true,
        label: '${_zoneName(zone)}, ${_qualityName(quality)}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(zone),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Rect _placed(Rect rect, double width, double height) {
    return Rect.fromLTWH(
      rect.left / canvas.width * width,
      rect.top / canvas.height * height,
      rect.width / canvas.width * width,
      rect.height / canvas.height * height,
    );
  }
}

Color? _glowColor(SomaticQuality quality) {
  switch (quality) {
    case SomaticQuality.unmarked:
      return null;
    case SomaticQuality.tight:
      return const Color(0xFFDA3633);
    case SomaticQuality.heavy:
      return const Color(0xFF6B8EAD);
  }
}

String _zoneName(SomaticZone zone) {
  switch (zone) {
    case SomaticZone.head:
      return 'Head';
    case SomaticZone.throat:
      return 'Throat';
    case SomaticZone.chest:
      return 'Chest';
    case SomaticZone.stomach:
      return 'Stomach';
  }
}

String _qualityName(SomaticQuality quality) {
  switch (quality) {
    case SomaticQuality.unmarked:
      return 'unmarked';
    case SomaticQuality.tight:
      return 'tight';
    case SomaticQuality.heavy:
      return 'heavy';
  }
}
