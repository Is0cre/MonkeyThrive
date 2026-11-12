import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import 'somatic_map.dart';

enum SilhouetteType { masculine, feminine, neutral }

/// Anatomical silhouette with a glow that stays inside the body.
///
/// [canvas] is the shared SVG viewBox (200 by 420). A region is a rectangle
/// in that same pixel space. At layout time each edge is multiplied by the
/// drawn width or height, so the target stays on the same part of the figure
/// when the widget changes size. Keep the widget's aspect ratio equal to
/// [canvas] and load every silhouette with [BoxFit.fill].
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

  static const canvas = Size(200, 420);

  /// ViewBox rectangles. Head sits on the skull, throat on the neck,
  /// chest on the upper torso, stomach below the ribs.
  static const regions = <SomaticZone, Rect>{
    SomaticZone.head: Rect.fromLTWH(66, 14, 68, 76),
    SomaticZone.throat: Rect.fromLTWH(82, 82, 36, 42),
    SomaticZone.chest: Rect.fromLTWH(72, 136, 56, 92),
    SomaticZone.stomach: Rect.fromLTWH(70, 232, 60, 84),
  };

  static String assetFor(SilhouetteType type) {
    switch (type) {
      case SilhouetteType.masculine:
        return 'assets/vectors/anatomy_masculine.svg';
      case SilhouetteType.feminine:
        return 'assets/vectors/anatomy_feminine.svg';
      case SilhouetteType.neutral:
        return 'assets/vectors/anatomy_neutral.svg';
    }
  }

  @override
  State<SomaticBodyMap> createState() => _SomaticBodyMapState();
}

class _SomaticBodyMapState extends State<SomaticBodyMap>
    with TickerProviderStateMixin {
  SilhouetteType _silhouette = SilhouetteType.neutral;
  final Map<SilhouetteType, PictureInfo> _pictures = {};
  PictureInfo? _mask;
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
    for (final info in _pictures.values) {
      info.picture.dispose();
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
      final info = await vg.loadPicture(SvgAssetLoader(asset), context);
      if (!mounted || generation != _loadGeneration) {
        info.picture.dispose();
        return;
      }
      _pictures[type] = info;
      setState(() {
        _mask = info;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _selector(),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(180.0, 280.0);
            final height =
                width * SomaticBodyMap.canvas.height / SomaticBodyMap.canvas.width;
            final showMood = _mask != null &&
                _maskType == _silhouette &&
                !_fade.isAnimating;
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
                      child: SvgPicture.asset(
                        SomaticBodyMap.assetFor(_silhouette),
                        key: ValueKey(_silhouette),
                        width: width,
                        height: height,
                        fit: BoxFit.fill,
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
                              pulses: _pulse,
                              picture: showMood ? _mask!.picture : null,
                              pictureSize: _mask?.size ?? SomaticBodyMap.canvas,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (final zone in SomaticZone.values)
                      _zoneTarget(zone, width, height),
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
              color: selected ? AppColors.textSecondary : AppColors.surfaceVariant,
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

  Widget _zoneTarget(SomaticZone zone, double width, double height) {
    final rect = _placed(SomaticBodyMap.regions[zone]!, width, height);
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
    required this.pulses,
    required this.picture,
    required this.pictureSize,
  }) : super(repaint: Listenable.merge(pulses.values.toList()));

  final Map<SomaticZone, SomaticQuality> marks;
  final Map<SomaticZone, AnimationController> pulses;
  final ui.Picture? picture;
  final Size pictureSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (picture == null || pictureSize.isEmpty) return;
    var any = false;
    for (final zone in SomaticZone.values) {
      if (_glowColor(marks[zone] ?? SomaticQuality.unmarked) != null) {
        any = true;
        break;
      }
    }
    if (!any) return;

    final bounds = Offset.zero & size;
    // The silhouette is drawn first as coverage. The glow is then drawn with
    // srcIn, which keeps the glow color only where that coverage is opaque.
    // drawPicture ignores Paint.blendMode, so the mask has to be its own layer.
    canvas.saveLayer(bounds, Paint());
    canvas.save();
    canvas.scale(size.width / pictureSize.width, size.height / pictureSize.height);
    canvas.drawPicture(picture!);
    canvas.restore();

    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.srcIn);
    for (final zone in SomaticZone.values) {
      final color = _glowColor(marks[zone] ?? SomaticQuality.unmarked);
      if (color == null) continue;
      final breath = 0.86 + 0.14 * pulses[zone]!.value;
      final rect = _placed(SomaticBodyMap.regions[zone]!, size.width, size.height);
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
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoodPainter oldDelegate) {
    return oldDelegate.picture != picture ||
        oldDelegate.pictureSize != pictureSize ||
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
