import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'somatic_map.dart';

enum SilhouetteType { masculine, feminine, neutral }

/// Anatomical silhouette with a glow that stays inside the body.
///
/// [canvas] is the shared PNG pixel size (784 by 1168). A region is a
/// rectangle in that same pixel space, and each silhouette has its own
/// regions because the figures are not the same height. At layout time each
/// edge is multiplied by the drawn width or height. Keep the widget's aspect
/// ratio equal to [canvas] and load every silhouette with [BoxFit.contain].
///
/// The silhouette choice is display only. Marks stay with the check-in.
class SomaticBodyMap extends StatefulWidget {
  final Map<SomaticZone, SomaticQuality> marks;
  final ValueChanged<SomaticZone> onTap;

  const SomaticBodyMap({
    super.key,
    required this.marks,
    required this.onTap,
  });

  static const canvas = Size(784, 1168);

  /// Pixel rectangles on [canvas]. Head sits on the skull, throat on the neck,
  /// chest on the upper torso, stomach on the abdomen.
  static const regions = <SilhouetteType, Map<SomaticZone, Rect>>{
    SilhouetteType.feminine: {
      SomaticZone.head: Rect.fromLTWH(338, 90, 108, 90),
      SomaticZone.throat: Rect.fromLTWH(352, 180, 80, 52),
      SomaticZone.chest: Rect.fromLTWH(314, 255, 156, 265),
      SomaticZone.stomach: Rect.fromLTWH(300, 525, 184, 110),
    },
    SilhouetteType.masculine: {
      SomaticZone.head: Rect.fromLTWH(336, 64, 112, 102),
      SomaticZone.throat: Rect.fromLTWH(344, 166, 96, 52),
      SomaticZone.chest: Rect.fromLTWH(305, 240, 174, 290),
      SomaticZone.stomach: Rect.fromLTWH(284, 545, 216, 120),
    },
    SilhouetteType.neutral: {
      SomaticZone.head: Rect.fromLTWH(344, 118, 96, 86),
      SomaticZone.throat: Rect.fromLTWH(356, 204, 72, 52),
      SomaticZone.chest: Rect.fromLTWH(318, 275, 148, 230),
      SomaticZone.stomach: Rect.fromLTWH(302, 515, 180, 115),
    },
  };

  static String assetFor(SilhouetteType type) {
    switch (type) {
      case SilhouetteType.masculine:
        return 'assets/vectors/anatomy_masculine.png';
      case SilhouetteType.feminine:
        return 'assets/vectors/anatomy_feminine.png';
      case SilhouetteType.neutral:
        return 'assets/vectors/anatomy_neutral.png';
    }
  }

  @override
  State<SomaticBodyMap> createState() => _SomaticBodyMapState();
}

class _SomaticBodyMapState extends State<SomaticBodyMap>
    with TickerProviderStateMixin {
  SilhouetteType _silhouette = SilhouetteType.neutral;
  final Map<SilhouetteType, ui.Image> _pictures = {};
  ui.Image? _mask;
  SilhouetteType? _maskType;
  int _loadGeneration = 0;
  var _loadStarted = false;
  var _alive = true;

  late final AnimationController _fade;
  late final Map<SomaticZone, AnimationController> _pulse;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener(_onFadeStatus);
    _pulse = {
      for (final zone in SomaticZone.values)
        zone: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2400),
        ),
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _load(_silhouette);
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(SomaticBodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _onFadeStatus(AnimationStatus status) {
    if (!_alive || status != AnimationStatus.completed) return;
    setState(() {});
  }

  @override
  void dispose() {
    _alive = false;
    _loadGeneration++;
    for (final image in _pictures.values) {
      image.dispose();
    }
    _pictures.clear();
    _mask = null;
    _fade.dispose();
    for (final controller in _pulse.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // CLINICAL SAFETY — Contained somatic glow
  // What this does: Draws a soft color inside the body where the person marked
  //   a zone, and pulses only after that mark. The silhouette choice changes
  //   the drawing only. Taps still cycle unmarked, tight, and heavy.
  // Why it exists: The color has to stay inside the outline so a zone reads as
  //   a place in the body. This widget does not score arousal and does not
  //   choose which tools open. The check-in screen does that from the marks.
  // What happens if removed or modified: A glow that leaks past the outline
  //   misplaces the sensation. A new zone or a 0–1 score would change the
  //   Window of Tolerance reading.
  // Informed by: Ogden, sensorimotor psychotherapy. The person is the authority
  //   on the mark. This is not a diagnosis.

  void _syncPulse() {
    final motion = !MediaQuery.disableAnimationsOf(context);
    for (final zone in SomaticZone.values) {
      final marked = _quality(zone) != SomaticQuality.unmarked;
      final controller = _pulse[zone]!;
      if (!marked || !motion) {
        controller.stop();
        controller.value = 0;
      } else if (!controller.isAnimating) {
        controller.repeat(reverse: true);
      }
    }
  }

  SomaticQuality _quality(SomaticZone zone) {
    return widget.marks[zone] ?? SomaticQuality.unmarked;
  }

  Future<void> _load(SilhouetteType type) async {
    final generation = ++_loadGeneration;
    final cached = _pictures[type];
    if (cached != null) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _mask = cached;
        _maskType = type;
      });
      return;
    }

    final asset = SomaticBodyMap.assetFor(type);
    try {
      final data = await rootBundle.load(asset);
      if (!mounted || generation != _loadGeneration) return;
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted || generation != _loadGeneration) {
        frame.image.dispose();
        return;
      }
      _pictures[type] = frame.image;
      setState(() {
        _mask = frame.image;
        _maskType = type;
      });
    } catch (error, stack) {
      if (!mounted || generation != _loadGeneration) return;
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'somatic body map',
        context: ErrorDescription('loading $asset'),
      ));
    }
  }

  void _select(SilhouetteType type) {
    if (type == _silhouette) return;
    // The outline crossfades. The glow waits until that fade is done and the
    // mask is the same silhouette, so color never sits outside the body.
    _fade.forward(from: 0);
    setState(() => _silhouette = type);
    _load(type);
  }

  @override
  Widget build(BuildContext context) {
    final zoneRegions = SomaticBodyMap.regions[_silhouette]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _selector(),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(180.0, 340.0);
            final height = width *
                SomaticBodyMap.canvas.height /
                SomaticBodyMap.canvas.width;
            final showMood =
                _mask != null && _maskType == _silhouette && !_fade.isAnimating;
            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Image.asset(
                        SomaticBodyMap.assetFor(_silhouette),
                        key: ValueKey(_silhouette),
                        width: width,
                        height: height,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _MoodPainter(
                              marks: {
                                for (final zone in SomaticZone.values)
                                  zone: _quality(zone),
                              },
                              regions: zoneRegions,
                              pulses: _pulse,
                              image: showMood ? _mask : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (final zone in SomaticZone.values)
                      _zoneTarget(zone, zoneRegions[zone]!, width, height),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _selector() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in SilhouetteType.values) _chip(type),
      ],
    );
  }

  Widget _chip(SilhouetteType type) {
    final selected = type == _silhouette;
    final label = _silhouetteLabel(type);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => _select(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected ? AppColors.textSecondary : AppColors.surfaceVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _zoneTarget(
      SomaticZone zone, Rect region, double width, double height) {
    final rect = _placed(region, width, height);
    final quality = _quality(zone);
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
          onTap: () => widget.onTap(zone),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _MoodPainter extends CustomPainter {
  _MoodPainter({
    required this.marks,
    required this.regions,
    required this.pulses,
    required this.image,
  }) : super(repaint: Listenable.merge(pulses.values.toList()));

  final Map<SomaticZone, SomaticQuality> marks;
  final Map<SomaticZone, Rect> regions;
  final Map<SomaticZone, AnimationController> pulses;
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final mask = image;
    if (mask == null) return;
    var any = false;
    for (final zone in SomaticZone.values) {
      if (_glowColor(marks[zone] ?? SomaticQuality.unmarked) != null) {
        any = true;
        break;
      }
    }
    if (!any) return;

    final bounds = Offset.zero & size;
    // Glows are drawn first. The PNG is then composited with dstIn, which
    // keeps color only where the figure is opaque. A ColorFilter on the image
    // alone does not see the glows, so it cannot clip them.
    canvas.saveLayer(bounds, Paint());
    for (final zone in SomaticZone.values) {
      final color = _glowColor(marks[zone] ?? SomaticQuality.unmarked);
      if (color == null) continue;
      final breath = 0.86 + 0.14 * pulses[zone]!.value;
      final rect = _placed(regions[zone]!, size.width, size.height);
      final radius = rect.longestSide * 0.9 * breath;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.50 * breath),
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: rect.center, radius: radius));
      canvas.drawCircle(rect.center, radius, paint);
    }
    canvas.drawImageRect(
      mask,
      Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()),
      bounds,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoodPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.regions != regions ||
        !_sameMarks(oldDelegate.marks, marks);
  }
}

bool _sameMarks(
  Map<SomaticZone, SomaticQuality> a,
  Map<SomaticZone, SomaticQuality> b,
) {
  for (final zone in SomaticZone.values) {
    if ((a[zone] ?? SomaticQuality.unmarked) !=
        (b[zone] ?? SomaticQuality.unmarked)) {
      return false;
    }
  }
  return true;
}

Rect _placed(Rect rect, double width, double height) {
  return Rect.fromLTWH(
    rect.left / SomaticBodyMap.canvas.width * width,
    rect.top / SomaticBodyMap.canvas.height * height,
    rect.width / SomaticBodyMap.canvas.width * width,
    rect.height / SomaticBodyMap.canvas.height * height,
  );
}

/// Legend colors: tight is red, heavy is blue.
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

String _silhouetteLabel(SilhouetteType type) {
  switch (type) {
    case SilhouetteType.masculine:
      return 'Masculine';
    case SilhouetteType.feminine:
      return 'Feminine';
    case SilhouetteType.neutral:
      return 'Neutral';
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
