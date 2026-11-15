import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A labelled slider for a whole-number choice, such as cycles or minutes.
class CountSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final String minLabel;
  final String maxLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final bool enabled;
  final Color activeColor;
  final Key? sliderKey;
  final ValueChanged<double>? onChanged;

  const CountSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.enabled,
    required this.activeColor,
    this.sliderKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = enabled ? AppColors.textSecondary : AppColors.textMuted;
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
            const Spacer(),
            Text(
              valueLabel,
              style: TextStyle(
                color: enabled ? activeColor : AppColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            key: sliderKey,
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            activeColor: enabled ? activeColor : AppColors.textMuted,
            inactiveColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            onChanged: enabled ? onChanged : null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            Text(
              maxLabel,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
