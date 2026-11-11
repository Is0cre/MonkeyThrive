import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/audio/acoustic_synthesis_gate.dart';
import '../../../core/audio/local_audio_cache.dart';
import '../../../core/audio/noise_generator.dart';
import '../../../core/audio/tone_generator.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/acoustic_coming_soon.dart';
import '../../../core/widgets/app_chrome.dart';

enum AttuneMode { none, binaural, isochronic }

const _noiseIcons = {
  NatureNoiseType.rain: Icons.grain_rounded,
  NatureNoiseType.ocean: Icons.waves_rounded,
  NatureNoiseType.forest: Icons.forest_rounded,
  NatureNoiseType.river: Icons.water_rounded,
  NatureNoiseType.thunder: Icons.thunderstorm_rounded,
  NatureNoiseType.wind: Icons.air_rounded,
};

class AttuneHomeScreen extends StatelessWidget {
  const AttuneHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AcousticSynthesisGate.enabled) {
      return const _AttuneUnavailableScreen();
    }
    return const _AttunePlayerScreen();
  }
}

/// Shown while synthesis is gated. Builds no player and starts no buffer.
class _AttuneUnavailableScreen extends StatelessWidget {
  const _AttuneUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 100),
          children: [
            Padding(
              padding: EdgeInsets.only(right: 42),
              child: AppHeader(
                title: 'Attune',
                subtitle: 'Generated sound tools for steady attention.',
                icon: Icons.graphic_eq_rounded,
              ),
            ),
            SizedBox(height: 28),
            AcousticSynthesisNotice(),
            SizedBox(height: 20),
            AcousticUnavailableCard(
              icon: Icons.headphones_rounded,
              title: 'Binaural beats',
              subtitle: 'Coming soon',
            ),
            SizedBox(height: 10),
            AcousticUnavailableCard(
              icon: Icons.graphic_eq_rounded,
              title: 'Isochronic tones',
              subtitle: 'Coming soon',
            ),
            SizedBox(height: 10),
            AcousticUnavailableCard(
              icon: Icons.forest_rounded,
              title: 'Nature soundscapes',
              subtitle: 'Coming soon',
            ),
          ],
        ),
      ),
    );
  }
}

class _AttunePlayerScreen extends StatefulWidget {
  const _AttunePlayerScreen();

  @override
  State<_AttunePlayerScreen> createState() => _AttunePlayerScreenState();
}

class _AttunePlayerScreenState extends State<_AttunePlayerScreen>
    with SessionTracking {
  // ── tone state ────────────────────────────────────────────────────────────
  AttuneMode _mode = AttuneMode.none;
  BrainwaveBand _band = BrainwaveBand.alpha;
  double _carrierHz = 200.0;
  bool _toneLoading = false;
  bool _tonePlaying = false;
  String? _toneError;

  // ── nature sounds ─────────────────────────────────────────────────────────
  final Set<NatureNoiseType> _activeSounds = {};
  final Map<NatureNoiseType, AudioPlayer> _naturePlayers = {};

  /// Created only after the gate check inside a playback method.
  AudioPlayer? _tonePlayer;

  AudioPlayer _ensureTonePlayer() => _tonePlayer ??= AudioPlayer();

  @override
  void dispose() {
    _tonePlayer?.dispose();
    for (final p in _naturePlayers.values) {
      p.dispose();
    }
    super.dispose();
  }

  // ── tone playback ──────────────────────────────────────────────────────────

  Future<void> _startTone() async {
    if (!AcousticSynthesisGate.enabled || _mode == AttuneMode.none) return;
    setState(() {
      _toneLoading = true;
      _toneError = null;
    });

    try {
      final band = _band;
      final carrier = _carrierHz;
      final beatHz = band.defaultBeatHz;

      final sourceKey =
          '${_mode.name}_${band.name}_${carrier.toStringAsFixed(1)}_$beatHz';
      late final AudioSource source;
      if (_mode == AttuneMode.binaural) {
        source = await LocalAudioCache.audioSource(
          sourceKey,
          () => BinauralBeatSource(carrierHz: carrier, beatHz: beatHz).bytes,
        );
      } else {
        source = await LocalAudioCache.audioSource(
          sourceKey,
          () => IsochronicToneSource(carrierHz: carrier, beatHz: beatHz).bytes,
        );
      }

      final tonePlayer = _ensureTonePlayer();
      await tonePlayer.setAudioSource(source, preload: true);
      await tonePlayer.setLoopMode(LoopMode.one);
      await tonePlayer.play();

      if (mounted) {
        final label = _mode == AttuneMode.binaural
            ? 'Binaural Beats — ${_band.label}'
            : 'Isochronic Tones — ${_band.label}';
        beginTracking(label, 'Attune', onEmergencyStop: _stopAllAudio);
        setState(() {
          _toneLoading = false;
          _tonePlaying = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('THRIVES audio start failed: $e');
      }
      if (mounted) {
        setState(() {
          _toneLoading = false;
          _toneError = 'Could not start audio. Try again.';
        });
      }
    }
  }

  void _stopAllAudio() {
    final tonePlayer = _tonePlayer;
    if (tonePlayer != null) unawaited(tonePlayer.stop());
    for (final p in _naturePlayers.values) {
      unawaited(p.stop());
      p.dispose();
    }
    _naturePlayers.clear();
    if (mounted) {
      setState(() {
        _tonePlaying = false;
        _activeSounds.clear();
      });
    }
  }

  Future<void> _stopTone() async {
    await _tonePlayer?.stop();
    if (_activeSounds.isEmpty) endTracking();
    if (mounted) setState(() => _tonePlaying = false);
  }

  Future<void> _restartTone() async {
    await _stopTone();
    await _startTone();
  }

  // ── nature playback ────────────────────────────────────────────────────────

  Future<void> _toggleNature(NatureNoiseType type) async {
    if (!AcousticSynthesisGate.enabled) return;
    if (_activeSounds.contains(type)) {
      await _naturePlayers[type]?.stop();
      _naturePlayers[type]?.dispose();
      _naturePlayers.remove(type);
      if (mounted) setState(() => _activeSounds.remove(type));
      if (!_tonePlaying && _activeSounds.isEmpty) endTracking();
    } else {
      AudioPlayer? player;
      try {
        final source = await LocalAudioCache.audioSource(
          'nature_${type.name}',
          () => NatureNoiseSource(type).bytes,
        );
        if (!mounted || !AcousticSynthesisGate.enabled) return;
        player = AudioPlayer();
        await player.setAudioSource(source, preload: true);
        await player.setLoopMode(LoopMode.one);
        await player.play();
        _naturePlayers[type] = player;
        player = null;
        beginTracking(
          'Nature Sound — ${type.label}',
          'Attune',
          onEmergencyStop: _stopAllAudio,
        );
        if (mounted) setState(() => _activeSounds.add(type));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('THRIVES nature audio failed: $e');
        }
        player?.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: const Padding(
                  padding: EdgeInsets.only(right: 42),
                  child: AppHeader(
                    title: 'Attune',
                    subtitle: 'Generated sound tools for steady attention.',
                    icon: Icons.graphic_eq_rounded,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Mode selector ───────────────────────────────────────
                  const AppSectionLabel('Type', icon: Icons.tune_rounded),
                  const SizedBox(height: 12),
                  _ModeRow(
                    selected: _mode,
                    onSelect: (m) {
                      if (_tonePlaying) _stopTone();
                      setState(() => _mode = m);
                    },
                  ),

                  if (_mode == AttuneMode.binaural) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.headphones_rounded,
                              color: AppColors.amber, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Binaural beats require stereo headphones to work.',
                              style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_mode != AttuneMode.none) ...[
                    const SizedBox(height: 24),

                    // ── Band selector ─────────────────────────────────────
                    const AppSectionLabel(
                      'Frequency band',
                      icon: Icons.equalizer_rounded,
                    ),
                    const SizedBox(height: 12),
                    _BandGrid(
                      selected: _band,
                      onSelect: (b) {
                        setState(() => _band = b);
                        if (_tonePlaying) _restartTone();
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Carrier frequency ─────────────────────────────────
                    const AppSectionLabel(
                      'Carrier frequency',
                      icon: Icons.radio_button_checked_rounded,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('100 Hz',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        Expanded(
                          child: Slider(
                            value: _carrierHz,
                            min: 100,
                            max: 400,
                            divisions: 30,
                            activeColor: const Color(0xFF7B68EE),
                            inactiveColor: AppColors.surfaceVariant,
                            onChanged: (v) {
                              setState(() => _carrierHz = v);
                            },
                            onChangeEnd: (_) {
                              if (_tonePlaying) _restartTone();
                            },
                          ),
                        ),
                        Text('${_carrierHz.round()} Hz',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Play/stop ─────────────────────────────────────────
                    if (_toneError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_toneError!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _toneLoading
                            ? null
                            : (_tonePlaying ? _stopTone : _startTone),
                        icon: _toneLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : Icon(_tonePlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded),
                        label: Text(
                          _toneLoading
                              ? 'Generating…'
                              : (_tonePlaying ? 'Stop' : 'Play'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _tonePlaying
                              ? AppColors.surfaceVariant
                              : const Color(0xFF7B68EE),
                          foregroundColor: _tonePlaying
                              ? AppColors.textPrimary
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    if (_tonePlaying) ...[
                      const SizedBox(height: 12),
                      _PlayingBadge(band: _band, mode: _mode),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // ── Nature sounds ─────────────────────────────────────────
                  const AppSectionLabel(
                    'Nature sounds',
                    icon: Icons.forest_rounded,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Layer ambient sound over any tone, or use on its own.',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  _NoiseSoundGrid(
                    active: _activeSounds,
                    onTap: _toggleNature,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _ModeRow extends StatelessWidget {
  final AttuneMode selected;
  final ValueChanged<AttuneMode> onSelect;

  const _ModeRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in [
          (AttuneMode.none, 'None', Icons.volume_off_rounded),
          (AttuneMode.binaural, 'Binaural', Icons.headphones_rounded),
          (AttuneMode.isochronic, 'Isochronic', Icons.graphic_eq_rounded),
        ]) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(entry.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: selected == entry.$1
                      ? const Color(0xFF7B68EE).withValues(alpha: 0.15)
                      : Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected == entry.$1
                        ? const Color(0xFF7B68EE)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(entry.$3,
                        color: selected == entry.$1
                            ? const Color(0xFF7B68EE)
                            : AppColors.textMuted,
                        size: 20),
                    const SizedBox(height: 4),
                    Text(
                      entry.$2,
                      style: TextStyle(
                        color: selected == entry.$1
                            ? const Color(0xFF7B68EE)
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (entry.$1 != AttuneMode.isochronic) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _BandGrid extends StatelessWidget {
  final BrainwaveBand selected;
  final ValueChanged<BrainwaveBand> onSelect;

  const _BandGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final band in BrainwaveBand.values) ...[
          GestureDetector(
            onTap: () => onSelect(band),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected == band
                    ? const Color(0xFF7B68EE).withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected == band
                      ? const Color(0xFF7B68EE)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${band.label}  ·  ${band.range}',
                          style: TextStyle(
                            color: selected == band
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          band.use,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${band.defaultBeatHz.toStringAsFixed(1)} Hz beat',
                    style: TextStyle(
                      color: selected == band
                          ? const Color(0xFF7B68EE)
                          : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selected == band)
                    const Icon(Icons.check_rounded,
                        color: Color(0xFF7B68EE), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NoiseSoundGrid extends StatelessWidget {
  final Set<NatureNoiseType> active;
  final void Function(NatureNoiseType type) onTap;

  const _NoiseSoundGrid({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: NatureNoiseType.values.map((type) {
        final isActive = active.contains(type);
        return GestureDetector(
          onTap: () => onTap(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? AppColors.teal
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _noiseIcons[type]!,
                  color: isActive ? AppColors.teal : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    color: isActive ? AppColors.teal : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PlayingBadge extends StatefulWidget {
  final BrainwaveBand band;
  final AttuneMode mode;
  const _PlayingBadge({required this.band, required this.mode});

  @override
  State<_PlayingBadge> createState() => _PlayingBadgeState();
}

class _PlayingBadgeState extends State<_PlayingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF7B68EE)
                .withValues(alpha: 0.08 + _pulse.value * 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF7B68EE),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.mode == AttuneMode.binaural ? "Binaural" : "Isochronic"} · '
                '${widget.band.label} · ${widget.band.defaultBeatHz.toStringAsFixed(1)} Hz',
                style: const TextStyle(
                  color: Color(0xFF7B68EE),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
