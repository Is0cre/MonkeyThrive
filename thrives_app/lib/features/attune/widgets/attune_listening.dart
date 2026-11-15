import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

/// Blocks the player until all three confirmations are stored on the device.
class AttuneWaiverGate extends StatefulWidget {
  final Future<void> Function() onAccepted;
  final VoidCallback onOpenPhysics;

  /// Shown on the deck's last card. The parent already pads the screen.
  final bool embedded;

  /// Replaces the default action label. The three lines stay the same.
  final String? actionLabel;

  const AttuneWaiverGate({
    super.key,
    required this.onAccepted,
    required this.onOpenPhysics,
    this.embedded = false,
    this.actionLabel,
  });

  @override
  State<AttuneWaiverGate> createState() => _AttuneWaiverGateState();
}

class _AttuneWaiverGateState extends State<AttuneWaiverGate> {
  final Set<int> _checked = {};
  bool _saving = false;

  bool get _ready => _checked.length == 3 && !_saving;

  Future<void> _enter() async {
    if (!_ready) return;
    setState(() => _saving = true);
    await widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lines = [
      l10n.attuneWaiverSeizure,
      l10n.attuneWaiverMachinery,
      l10n.attuneWaiverRisk,
    ];
    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        widget.embedded ? 4 : 24,
        widget.embedded ? 0 : 20,
        widget.embedded ? 36 : 4,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.attuneWaiverTitle,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.attuneWaiverRecorded,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < lines.length; i++)
                  CheckboxListTile(
                    value: _checked.contains(i),
                    onChanged: _saving
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _checked.add(i);
                              } else {
                                _checked.remove(i);
                              }
                            });
                          },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Theme.of(context).colorScheme.primary,
                    checkColor: Theme.of(context).scaffoldBackgroundColor,
                    title: Text(
                      lines[i],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onOpenPhysics,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.zero,
              ),
              child: Text(l10n.physicsOpen),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('attune-waiver-enter'),
              onPressed: _ready ? _enter : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(widget.actionLabel ?? l10n.attuneWaiverEnter),
            ),
          ),
        ],
      ),
    );
    if (widget.embedded) {
      return Material(
        type: MaterialType.transparency,
        child: body,
      );
    }
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.96),
      child: SafeArea(child: body),
    );
  }
}

/// A slow ovoid spiral. One cycle takes many seconds, so it does not flicker.
class AttuneVisualizer extends StatefulWidget {
  final bool active;

  const AttuneVisualizer({super.key, required this.active});

  @override
  State<AttuneVisualizer> createState() => _AttuneVisualizerState();
}

class _AttuneVisualizerState extends State<AttuneVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.active) _pulse.repeat();
  }

  @override
  void didUpdateWidget(AttuneVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.active && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: context.l10n.attuneFocus,
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return CustomPaint(
                painter: _TorusPainter(
                  turn: _pulse.value,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TorusPainter extends CustomPainter {
  final double turn;
  final Color color;

  const _TorusPainter({required this.turn, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final breathe = 0.94 + 0.06 * math.sin(turn * math.pi * 2);
    final shell = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2 * breathe,
        height: radius * 1.25 * breathe,
      ),
      shell,
    );

    final point = Paint()..color = color.withValues(alpha: 0.7);
    const turns = 3.0;
    const count = 72;
    for (var i = 0; i < count; i++) {
      final u = i / (count - 1);
      final angle = u * turns * math.pi * 2 + turn * math.pi * 2;
      final spread = radius * (0.18 + 0.82 * u) * breathe;
      final p = center +
          Offset(
            math.cos(angle) * spread,
            math.sin(angle) * spread * 0.62,
          );
      canvas.drawCircle(p, 1.2 + u, point);
    }
  }

  @override
  bool shouldRepaint(_TorusPainter oldDelegate) =>
      oldDelegate.turn != turn || oldDelegate.color != color;
}

/// One mix row. The label, track, number, and trailing slot share fixed
/// widths so every slider lines up with the next.
class AttuneSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final Widget? trailingAction;
  final Key? sliderKey;
  final bool enabled;

  const AttuneSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.trailingAction,
    this.sliderKey,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? Theme.of(context).colorScheme.primary : AppColors.textMuted;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              key: sliderKey,
              value: value.clamp(0.0, 1.0).toDouble(),
              min: 0,
              max: 1,
              activeColor: color,
              inactiveColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '${(value * 100).round()}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: trailingAction ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Sits under the mask slider. The icon stays quiet on the dark background.
class AttuneMaskMusicNote extends StatelessWidget {
  const AttuneMaskMusicNote({super.key});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline_rounded, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.attuneMaskMusicNote,
            style: const TextStyle(color: color, fontSize: 12, height: 1.45),
          ),
        ),
      ],
    );
  }
}

/// Fades and folds setup controls. This is a screen transition, not a claim
/// about a mental state. Hidden controls stay out of the hit test and the
/// semantics tree.
class ZenCollapse extends StatefulWidget {
  final bool show;
  final Widget child;

  const ZenCollapse({super.key, required this.show, required this.child});

  @override
  State<ZenCollapse> createState() => _ZenCollapseState();
}

class _ZenCollapseState extends State<ZenCollapse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.show ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(ZenCollapse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show == oldWidget.show) return;
    if (widget.show) {
      _reveal.forward();
    } else {
      _reveal.reverse();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, child) {
          final t = AppMotion.fold.transform(_reveal.value);
          final hidden = t < 0.99;
          return ExcludeSemantics(
            excluding: hidden,
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: t,
              child: Opacity(
                opacity: t,
                child: IgnorePointer(
                  ignoring: hidden,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
