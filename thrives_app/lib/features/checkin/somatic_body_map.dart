import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'somatic_map.dart';

/// Calm silhouette. Zones share one geometry with the hit targets.
class SomaticBodyMap extends StatelessWidget {
  final Map<SomaticZone, SomaticQuality> marks;
  final ValueChanged<SomaticZone> onTap;

  const SomaticBodyMap({
    super.key,
    required this.marks,
    required this.onTap,
  });

  static const canvas = Size(200, 420);

  static const regions = <SomaticZone, Rect>{
    SomaticZone.head: Rect.fromLTWH(58, 16, 84, 84),
    SomaticZone.throat: Rect.fromLTWH(82, 104, 36, 36),
    SomaticZone.chest: Rect.fromLTWH(52, 146, 96, 100),
    SomaticZone.stomach: Rect.fromLTWH(64, 252, 72, 84),
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
                CustomPaint(
                  size: Size(width, height),
                  painter: _SilhouettePainter(marks: marks),
                ),
                for (final zone in SomaticZone.values)
                  _zoneTarget(zone, width, height),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _zoneTarget(SomaticZone zone, double width, double height) {
    final rect = regions[zone]!;
    final quality = marks[zone] ?? SomaticQuality.unmarked;
    return Positioned(
      left: rect.left / canvas.width * width,
      top: rect.top / canvas.height * height,
      width: rect.width / canvas.width * width,
      height: rect.height / canvas.height * height,
      child: Semantics(
        button: true,
        label: '${_zoneName(zone)}, ${_qualityName(quality)}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(zone),
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Map<SomaticZone, SomaticQuality> marks;

  _SilhouettePainter({required this.marks});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / SomaticBodyMap.canvas.width;
    final sy = size.height / SomaticBodyMap.canvas.height;
    canvas.save();
    canvas.scale(sx, sy);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = AppColors.surfaceVariant;
    canvas.drawPath(_bodyPath(), outline);

    for (final zone in SomaticZone.values) {
      final rect = SomaticBodyMap.regions[zone]!;
      final quality = marks[zone] ?? SomaticQuality.unmarked;
      final fill = Paint()..color = _fill(quality);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _edge(quality);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
      if (zone == SomaticZone.head) {
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, edge);
      } else {
        canvas.drawRRect(rrect, fill);
        canvas.drawRRect(rrect, edge);
      }
    }

    canvas.restore();
  }

  Path _bodyPath() {
    return Path()
      ..moveTo(78, 108)
      ..lineTo(70, 150)
      ..cubicTo(28, 168, 24, 230, 40, 280)
      ..lineTo(58, 276)
      ..lineTo(64, 168)
      ..lineTo(72, 320)
      ..cubicTo(78, 390, 92, 404, 100, 404)
      ..cubicTo(108, 404, 122, 390, 128, 320)
      ..lineTo(136, 168)
      ..lineTo(142, 276)
      ..lineTo(160, 280)
      ..cubicTo(176, 230, 172, 168, 130, 150)
      ..lineTo(122, 108)
      ..close();
  }

  Color _fill(SomaticQuality quality) {
    switch (quality) {
      case SomaticQuality.unmarked:
        return AppColors.surface;
      case SomaticQuality.tight:
        return const Color(0xFFDA3633).withValues(alpha: 0.38);
      case SomaticQuality.heavy:
        return const Color(0xFF6B8EAD).withValues(alpha: 0.45);
    }
  }

  Color _edge(SomaticQuality quality) {
    switch (quality) {
      case SomaticQuality.unmarked:
        return AppColors.surfaceVariant;
      case SomaticQuality.tight:
        return const Color(0xFFDA3633);
      case SomaticQuality.heavy:
        return const Color(0xFF6B8EAD);
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) {
    return oldDelegate.marks != marks;
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
