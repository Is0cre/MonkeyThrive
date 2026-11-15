import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:monkeythrive/l10n/l10n.dart';
import '../../../core/audio/acoustic_synthesis_gate.dart';
import '../../../core/audio/attune_audio_session.dart';
import '../../../core/audio/local_audio_cache.dart';
import '../../../core/audio/noise_generator.dart';
import '../../../core/audio/tone_generator.dart';
import '../attune_dosage.dart';
import '../attune_mask_playlist.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/acoustic_coming_soon.dart';
import '../../../core/widgets/app_chrome.dart';
import '../../../core/widgets/count_slider.dart';
import '../widgets/attune_listening.dart';
import 'attune_frequency_intro.dart';
import 'attune_onboarding_carousel.dart';
import 'physics_explanation_screen.dart';

enum AttuneMode { none, binaural, isochronic }

const _noiseIcons = {
  NatureNoiseType.rain: Icons.grain_rounded,
  NatureNoiseType.ocean: Icons.waves_rounded,
  NatureNoiseType.forest: Icons.forest_rounded,
  NatureNoiseType.river: Icons.water_rounded,
  NatureNoiseType.thunder: Icons.thunderstorm_rounded,
  NatureNoiseType.wind: Icons.air_rounded,
};

class AttuneScreen extends StatelessWidget {
  const AttuneScreen({super.key});

  @override
  Widget build(BuildContext context) => const AttuneHomeScreen();
}

class AttuneHomeScreen extends StatelessWidget {
  const AttuneHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AcousticSynthesisGate.tonesEnabled) {
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
                title: context.l10n.navAttune,
                subtitle: context.l10n.attuneSubtitle,
                icon: Icons.graphic_eq_rounded,
              ),
            ),
            SizedBox(height: 28),
            AcousticSynthesisNotice(),
            SizedBox(height: 20),
            AcousticUnavailableCard(
              icon: Icons.headphones_rounded,
              title: context.l10n.binauralBeats,
              subtitle: context.l10n.comingSoon,
            ),
            SizedBox(height: 10),
            AcousticUnavailableCard(
              icon: Icons.graphic_eq_rounded,
              title: context.l10n.isochronicTones,
              subtitle: context.l10n.comingSoon,
            ),
            SizedBox(height: 10),
            AcousticUnavailableCard(
              icon: Icons.forest_rounded,
              title: context.l10n.natureSoundscapes,
              subtitle: context.l10n.comingSoon,
            ),
          ],
        ),
      ),
    );
  }
}

// CLINICAL SAFETY — Attune frequency introduction
// What this does: Holds binaural and isochronic playback until the person
//   has stepped through the introduction on this device.
// Why it exists: Two-ear beats and pulsed tones are strong sensory input.
//   Headphones, seizure history, and not driving have to be said before Play.
// What happens if removed or modified: Play can start on an unexplained tone.
// Informed by: the acoustic safety gate for this tool.
class _AttunePlayerScreen extends StatefulWidget {
  const _AttunePlayerScreen();

  @override
  State<_AttunePlayerScreen> createState() => _AttunePlayerScreenState();
}

class _AttunePlayerScreenState extends State<_AttunePlayerScreen>
    with SessionTracking {
  // Null until the device flags have been read. Play stays unbuilt until then.
  bool? _introSeen;
  bool? _waiverAccepted;
  bool _rereadIntro = false;

  /// Mix levels. The tone rises from silence to [_engineVolume].
  double _engineVolume = 0.25;
  double _maskVolume = 0.75;

  // ── tone state ────────────────────────────────────────────────────────────
  AttuneMode _mode = AttuneMode.none;
  BrainwaveBand _band = BrainwaveBand.alpha;
  double _carrierHz = attuneMaskCarrierHz(0);
  bool _toneLoading = false;
  bool _tonePlaying = false;
  String? _toneError;
  int _toneFade = 0;

  // The slider cannot run past the current recording. The floor is 10
  // minutes unless that recording is shorter. The value starts at the
  // length of the first season.
  static const int _minSessionMinutes = 10;
  int _sessionMinutes = attuneMaskDurationMinutes(0);
  int _secondsLeft = 0;
  Timer? _sessionTimer;

  // ── nature sounds ─────────────────────────────────────────────────────────
  final Set<NatureNoiseType> _activeSounds = {};
  final Map<NatureNoiseType, AudioPlayer> _naturePlayers = {};

  /// Created only after the gate check inside a playback method.
  AudioPlayer? _tonePlayer;

  /// Local classical mask. This is not nature synthesis, so the acoustic
  /// gate stays closed.
  AudioPlayer? _maskPlayer;
  StreamSubscription<PlayerState>? _maskStateSub;
  int _maskIndex = 0;
  int _maskFade = 0;

  /// True only after this recording has actually started. A later
  /// [ProcessingState.completed] then ends the session.
  bool _maskHeardPlayback = false;

  /// The binaural engine is held. The recording keeps playing.
  bool _toneEnginePaused = false;

  /// Seconds of Attune already listened on this local day.
  int _dosageSeconds = 0;

  /// True while the daily-limit ask is open, so Play cannot start twice.
  bool _dosageCheck = false;

  AudioPlayer _mixPlayer() => AudioPlayer(handleAudioSessionActivation: false);

  AudioPlayer _ensureTonePlayer() => _tonePlayer ??= _mixPlayer();

  AudioPlayer _ensureMaskPlayer() {
    final player = _maskPlayer ??= _mixPlayer();
    _maskStateSub ??= player.playerStateStream.listen(_onMaskPlayback);
    return player;
  }

  /// Whole minutes the person can choose for the season now selected.
  int get _sessionMaxMinutes => attuneMaskDurationMinutes(_maskIndex);

  int get _sessionMinMinutes {
    final maxMinutes = _sessionMaxMinutes;
    if (maxMinutes < _minSessionMinutes) return maxMinutes;
    return _minSessionMinutes;
  }

  void _selectMask(int index) {
    final previousMax = attuneMaskDurationMinutes(_maskIndex);
    final wasFullPiece = _sessionMinutes >= previousMax;
    _maskIndex = index;
    final maxMinutes = attuneMaskDurationMinutes(index);
    final minMinutes =
        maxMinutes < _minSessionMinutes ? maxMinutes : _minSessionMinutes;
    if (wasFullPiece || _sessionMinutes > maxMinutes) {
      _sessionMinutes = maxMinutes;
    } else if (_sessionMinutes < minMinutes) {
      _sessionMinutes = minMinutes;
    }
    final cap = attuneMaskDurationSeconds[index];
    if (_tonePlaying && _secondsLeft > cap) _secondsLeft = cap;
    _carrierHz = attuneMaskCarrierHz(index);
  }

  void _onMaskPlayback(PlayerState state) {
    if (!_maskHeardPlayback) {
      if (state.playing && state.processingState == ProcessingState.ready) {
        _maskHeardPlayback = true;
      }
      return;
    }
    if (state.processingState != ProcessingState.completed) return;
    _maskHeardPlayback = false;
    unawaited(_stopSession());
  }

  bool get _mayPlayTone =>
      _introSeen == true &&
      _waiverAccepted == true &&
      !_rereadIntro &&
      AcousticSynthesisGate.tonesEnabled;

  /// True once the tone is actually playing. Setup controls fold away then.
  bool get _isSessionActive => _tonePlaying;

  String _maskTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (_maskIndex) {
      case 0:
        return l10n.attuneMaskTrackSpring;
      case 1:
        return l10n.attuneMaskTrackSummer;
      case 2:
        return l10n.attuneMaskTrackAutumn;
      case 3:
        return l10n.attuneMaskTrackWinter;
      default:
        return l10n.attuneMaskTrackSpring;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadIntro();
  }

  Future<void> _loadIntro() async {
    final seen = await PrefsService.hasSeenAttuneIntro();
    final waiver = await PrefsService.hasAcceptedAttuneWaiver();
    final dosage = await AttuneDosage.instance.todaySeconds();
    if (seen && waiver) await PrefsService.rememberAttuneUnlocked();
    if (!mounted) return;
    setState(() {
      _introSeen = seen;
      _waiverAccepted = waiver;
      _dosageSeconds = dosage;
    });
  }

  Future<void> _finishCarousel() async {
    await PrefsService.setAttuneUnlocked();
    if (!mounted) return;
    setState(() {
      _introSeen = true;
      _waiverAccepted = true;
      _rereadIntro = false;
    });
  }

  Future<void> _completeIntro() async {
    await PrefsService.setAttuneIntroSeen();
    if (!mounted) return;
    setState(() {
      _introSeen = true;
      _rereadIntro = false;
    });
  }

  void _openPhysics() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PhysicsExplanationScreen(),
      ),
    );
  }

  void _openIntroAgain() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _toneFade++;
    unawaited(_tonePlayer?.stop());
    if (_tonePlaying && _activeSounds.isEmpty) endTracking();
    if (_tonePlaying) unawaited(_finishDosage());
    setState(() {
      _tonePlaying = false;
      _toneLoading = false;
      _rereadIntro = true;
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    unawaited(AttuneDosage.instance.end());
    _maskStateSub?.cancel();
    _tonePlayer?.dispose();
    _maskPlayer?.dispose();
    for (final p in _naturePlayers.values) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _finishDosage() async {
    await AttuneDosage.instance.end();
    final seconds = await AttuneDosage.instance.todaySeconds();
    if (!mounted) return;
    setState(() => _dosageSeconds = seconds);
  }

  // ── tone playback ──────────────────────────────────────────────────────────

  // CLINICAL SAFETY — Attune daily listening limit
  // What this does: Shows a standing note before Play, counts listening time
  //   for the local day, and asks once that time is past 45 minutes.
  // Why it exists: A long tone can leave a person drowsy. The note repeats
  //   the driving limit and a 45 minute recommendation. The ask does not
  //   diagnose, and it does not claim the tone forces a brain state.
  // What happens if removed or modified: Play can start with no daily count
  //   and no second look after a long day.
  // Informed by: the acoustic safety gate for this tool.
  Future<void> _onPlayPressed() async {
    if (_tonePlaying) {
      await _stopTone();
      return;
    }
    if (_dosageCheck || _toneLoading) return;
    setState(() => _dosageCheck = true);
    try {
      final seconds = await AttuneDosage.instance.todaySeconds();
      if (!mounted) return;
      if (AttuneDosage.needsWarning(seconds)) {
        final proceed = await confirmAttunePastDailyLimit(context);
        if (!proceed || !mounted) return;
      }
      await _startTone();
    } finally {
      if (mounted) setState(() => _dosageCheck = false);
    }
  }

  Future<void> _startTone({bool resumeClock = false}) async {
    if (!_mayPlayTone || _mode == AttuneMode.none) return;
    setState(() {
      _toneLoading = true;
      _toneError = null;
    });

    try {
      await AttuneAudioSession.configureForMix();
      final band = _band;
      final carrier = _carrierHz;
      final beatHz = band.defaultBeatHz;

      final sourceKey =
          '${_mode.name}_${band.name}_${carrier.toStringAsFixed(1)}_$beatHz';
      final source = await LocalAudioCache.toneSource(
        key: sourceKey,
        binaural: _mode == AttuneMode.binaural,
        carrierHz: carrier,
        beatHz: beatHz,
      );

      final tonePlayer = _ensureTonePlayer();
      await tonePlayer.setAudioSource(source, preload: true);
      await tonePlayer.setLoopMode(LoopMode.one);
      try {
        await tonePlayer.setVolume(0);
      } catch (_) {}
      if (!mounted || !_mayPlayTone) {
        _toneFade++;
        await tonePlayer.stop();
        return;
      }
      // play() stays pending while the looping chunk repeats.
      unawaited(tonePlayer.play().catchError((Object error, StackTrace stack) {
        debugPrint('THRIVES audio play failed: $error\n$stack');
        unawaited(_finishDosage());
        if (!mounted) return;
        _toneFade++;
        setState(() {
          _toneLoading = false;
          _tonePlaying = false;
          _toneError = context.l10n.couldNotStartAudio;
        });
      }));
      unawaited(_raiseTone(tonePlayer));

      final label = _mode == AttuneMode.binaural
          ? 'Binaural Beats — ${_band.label}'
          : 'Isochronic Tones — ${_band.label}';
      if (!resumeClock) {
        beginTracking(label, 'Attune', onEmergencyStop: _stopAllAudio);
        _beginSessionClock();
        unawaited(_startMask());
        AttuneDosage.instance.begin();
      }
      setState(() {
        _toneLoading = false;
        _tonePlaying = true;
      });
    } catch (e, stackTrace) {
      debugPrint('THRIVES audio start failed: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _toneLoading = false;
          _toneError = context.l10n.couldNotStartAudio;
        });
      }
    }
  }

  Future<void> _raiseTone(AudioPlayer player) async {
    final fade = ++_toneFade;
    const steps = 10;
    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (fade != _toneFade || !mounted) return;
      try {
        await player.setVolume((step / steps) * _engineVolume);
      } catch (_) {
        return;
      }
    }
  }

  // CLINICAL SAFETY — Attune session timer
  // What this does: Keeps a binaural or isochronic tone inside a length the
  //   person set, then fades it out.
  // Why it exists: Hemispheric sound is sustained sensory input. An open-ended
  //   loop can run past the point where the person meant to stop.
  // What happens if removed or modified: The tone can continue with no end.
  // Informed by: the acoustic safety gate for this tool.
  void _beginSessionClock() {
    _sessionTimer?.cancel();
    _secondsLeft = _sessionMinutes * 60;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(AttuneDosage.instance.checkpointIfDue());
      if (!mounted || !_tonePlaying) return;
      if (_secondsLeft <= 1) {
        _sessionTimer?.cancel();
        _sessionTimer = null;
        setState(() => _secondsLeft = 0);
        unawaited(_endSession());
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _endSession() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    final player = _tonePlayer;
    if (player == null) {
      await _stopTone();
      return;
    }
    await _lowerTone(player);
  }

  Future<void> _lowerTone(AudioPlayer player) async {
    final fade = ++_toneFade;
    const steps = 10;
    for (var step = steps - 1; step >= 0; step--) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (fade != _toneFade || !mounted) return;
      try {
        await player.setVolume((step / steps) * _engineVolume);
        await _maskPlayer?.setVolume((step / steps) * _maskVolume);
      } catch (_) {
        return;
      }
    }
    if (fade != _toneFade || !mounted) return;
    await _stopTone();
  }

  Future<void> _startMask() async {
    if (!_mayPlayTone || attuneMaskAssets.isEmpty) return;
    try {
      await AttuneAudioSession.configureForMix();
      final player = _ensureMaskPlayer();
      _maskHeardPlayback = false;
      await player.setAudioSource(
        AudioSource.asset(attuneMaskAssets[_maskIndex]),
        preload: true,
      );
      await player.setLoopMode(LoopMode.off);
      try {
        await player.setVolume(0);
      } catch (_) {}
      if (!mounted || !_mayPlayTone) {
        _maskFade++;
        await player.stop();
        return;
      }
      unawaited(player.play().catchError((Object error, StackTrace stack) {
        debugPrint('THRIVES mask play failed: $error\n$stack');
      }));
      unawaited(_raiseMask(player));
    } catch (e, stackTrace) {
      debugPrint('THRIVES mask start failed: $e\n$stackTrace');
    }
  }

  Future<void> _raiseMask(AudioPlayer player) async {
    final fade = ++_maskFade;
    const steps = 10;
    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (fade != _maskFade || !mounted) return;
      try {
        await player.setVolume((step / steps) * _maskVolume);
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _nextMaskTrack() async {
    final next = (_maskIndex + 1) % attuneMaskAssets.length;
    final inSession = _tonePlaying;
    setState(() {
      _selectMask(next);
      if (inSession) _sessionMinutes = attuneMaskDurationMinutes(next);
    });
    if (!inSession) return;

    final timer = _sessionTimer;
    if (timer != null && timer.isActive) timer.cancel();
    _sessionTimer = null;
    _beginSessionClock();

    try {
      await AttuneAudioSession.configureForMix();
      final player = _ensureMaskPlayer();
      _maskFade++;
      _maskHeardPlayback = false;
      await player.setAudioSource(
        AudioSource.asset(attuneMaskAssets[next]),
        preload: true,
      );
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(_maskVolume);
      // play() stays pending until this recording ends. Starting it is enough.
      unawaited(player.play().catchError((Object error, StackTrace stack) {
        debugPrint('THRIVES mask skip failed: $error\n$stack');
      }));
    } catch (e, stackTrace) {
      debugPrint('THRIVES mask skip failed: $e\n$stackTrace');
    }
    if (!mounted || !_tonePlaying) return;
    await _retuneSessionTone();
  }

  /// Swaps the playing tone to the season's carrier without ending the session.
  Future<void> _retuneSessionTone() async {
    if (!_mayPlayTone || _mode == AttuneMode.none || !_tonePlaying) return;
    try {
      await AttuneAudioSession.configureForMix();
      final band = _band;
      final carrier = _carrierHz;
      final beatHz = band.defaultBeatHz;
      final sourceKey =
          '${_mode.name}_${band.name}_${carrier.toStringAsFixed(1)}_$beatHz';
      final source = await LocalAudioCache.toneSource(
        key: sourceKey,
        binaural: _mode == AttuneMode.binaural,
        carrierHz: carrier,
        beatHz: beatHz,
      );
      if (!mounted || !_tonePlaying) return;
      final tonePlayer = _ensureTonePlayer();
      _toneFade++;
      _toneEnginePaused = false;
      await tonePlayer.setAudioSource(source, preload: true);
      await tonePlayer.setLoopMode(LoopMode.one);
      await tonePlayer.setVolume(_engineVolume);
      unawaited(tonePlayer.play().catchError((Object error, StackTrace stack) {
        debugPrint('THRIVES audio play failed: $error\n$stack');
        unawaited(_finishDosage());
        if (!mounted) return;
        _toneFade++;
        setState(() {
          _tonePlaying = false;
          _toneError = context.l10n.couldNotStartAudio;
        });
      }));
    } catch (e, stackTrace) {
      debugPrint('THRIVES audio start failed: $e\n$stackTrace');
      if (mounted) {
        setState(() => _toneError = context.l10n.couldNotStartAudio);
      }
    }
  }

  Future<void> _toggleToneEngine() async {
    final player = _tonePlayer;
    if (player == null || !_tonePlaying || _toneLoading) return;
    if (_toneEnginePaused) {
      unawaited(player.play().catchError((Object error, StackTrace stack) {
        debugPrint('THRIVES audio play failed: $error\n$stack');
      }));
      try {
        await player.setVolume(_engineVolume);
      } catch (_) {}
      if (mounted) setState(() => _toneEnginePaused = false);
      return;
    }
    try {
      await player.pause();
    } catch (e, stackTrace) {
      debugPrint('THRIVES audio pause failed: $e\n$stackTrace');
      return;
    }
    if (mounted) setState(() => _toneEnginePaused = true);
  }

  /// Stops the tone as soon as the recording ends, with no fade.
  Future<void> _stopSession() => _stopTone();

  Future<void> _stopMask() async {
    _maskFade++;
    await _maskPlayer?.stop();
  }

  void _stopAllAudio() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    unawaited(_finishDosage());
    _toneFade++;
    final tonePlayer = _tonePlayer;
    final maskPlayer = _maskPlayer;
    if (tonePlayer != null) unawaited(tonePlayer.stop());
    if (maskPlayer != null) unawaited(maskPlayer.stop());
    for (final p in _naturePlayers.values) {
      unawaited(p.stop());
      p.dispose();
    }
    _naturePlayers.clear();
    _maskHeardPlayback = false;
    if (mounted) {
      setState(() {
        _tonePlaying = false;
        _toneEnginePaused = false;
        _activeSounds.clear();
      });
    }
  }

  Future<void> _stopTone({bool endSession = true}) async {
    _toneFade++;
    _toneEnginePaused = false;
    if (endSession) {
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _maskHeardPlayback = false;
      await _finishDosage();
    }
    await _tonePlayer?.stop();
    if (endSession) await _stopMask();
    if (endSession && _activeSounds.isEmpty) endTracking();
    if (mounted) setState(() => _tonePlaying = false);
  }

  Future<void> _restartTone() async {
    await _stopTone(endSession: false);
    await _startTone(resumeClock: true);
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
        await AttuneAudioSession.configureForMix();
        player = AudioPlayer(handleAudioSessionActivation: false);
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
    if (_introSeen == null || _waiverAccepted == null) {
      return const AppBackdrop(child: SizedBox.expand());
    }
    // CLINICAL SAFETY — Attune listening confirmation
    // What this does: Blocks the player until three confirmations are stored
    //   on this device.
    // Why it exists: Seizure history and driving have to be declined before a
    //   sustained tone. The third line is the person's own risk statement.
    // What happens if removed or modified: Play can start without that record.
    // Informed by: the acoustic safety gate for this tool.
    if (_introSeen != true || _waiverAccepted != true) {
      return AppBackdrop(
        child: AttuneOnboardingCarousel(
          onAccepted: _finishCarousel,
          onOpenPhysics: _openPhysics,
        ),
      );
    }
    if (_rereadIntro) {
      return AppBackdrop(
        child: AttuneFrequencyIntro(
          allowClose: true,
          onDone: _completeIntro,
          onClose: () => setState(() => _rereadIntro = false),
        ),
      );
    }
    return _buildPlayer(context);
  }

  Widget _buildPlayer(BuildContext context) {
    return AppBackdrop(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ZenCollapse(
                    show: !_isSessionActive,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 42),
                          child: AppHeader(
                            title: context.l10n.navAttune,
                            subtitle: context.l10n.attuneSubtitle,
                            icon: Icons.graphic_eq_rounded,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DosageNote(minutes: _dosageSeconds ~/ 60),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: _openIntroAgain,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF7B68EE),
                                  alignment: Alignment.centerLeft,
                                ),
                                child: Text(context.l10n.attuneIntroAgain),
                              ),
                              TextButton(
                                onPressed: _openPhysics,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF7B68EE),
                                  alignment: Alignment.centerLeft,
                                ),
                                child: Text(context.l10n.physicsOpen),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ── Mode selector ───────────────────────────────────────
                        AppSectionLabel(context.l10n.attuneType,
                            icon: Icons.tune_rounded),
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
                            child: Row(
                              children: [
                                const Icon(Icons.headphones_rounded,
                                    color: AppColors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.l10n.headphonesNote,
                                    style: const TextStyle(
                                        color: AppColors.amber,
                                        fontSize: 12,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_mode != AttuneMode.none) ...[
                    ZenCollapse(
                      show: !_isSessionActive,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),

                          // ── Band selector ─────────────────────────────────
                          AppSectionLabel(
                            context.l10n.frequencyBand,
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
                          AppSectionLabel(
                            context.l10n.carrierFrequency,
                            icon: Icons.radio_button_checked_rounded,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(context.l10n.hertz('100'),
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              Expanded(
                                child: Slider(
                                  key: const Key('attune-carrier-slider'),
                                  value: _carrierHz,
                                  min: 100,
                                  max: 400,
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
                              Text(
                                  context.l10n.hertz(
                                    _carrierHz.toStringAsFixed(1),
                                  ),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    AttuneVisualizer(
                      active: _tonePlaying && !_toneEnginePaused,
                    ),
                    const SizedBox(height: 8),
                    AttuneSliderRow(
                      label: context.l10n.attuneToneLevel,
                      value: _engineVolume,
                      enabled: !_toneLoading,
                      sliderKey: const Key('attune-engine-slider'),
                      onChanged: (value) {
                        setState(() => _engineVolume = value);
                        if (_tonePlaying && !_toneEnginePaused) {
                          unawaited(_tonePlayer?.setVolume(value));
                        }
                      },
                      trailingAction: IconButton(
                        key: const Key('attune-tone-toggle'),
                        tooltip: _toneEnginePaused
                            ? context.l10n.play
                            : context.l10n.breathingPause,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: _tonePlaying && !_toneLoading
                            ? () => unawaited(_toggleToneEngine())
                            : null,
                        icon: Icon(
                          _toneEnginePaused ? Icons.play_arrow : Icons.pause,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AttuneSliderRow(
                      label: context.l10n.attuneMaskLevel,
                      value: _maskVolume,
                      enabled: !_toneLoading,
                      sliderKey: const Key('attune-mask-slider'),
                      onChanged: (value) {
                        setState(() => _maskVolume = value);
                        final mask = _maskPlayer;
                        if (_tonePlaying && mask != null) {
                          _maskFade++;
                          unawaited(mask.setVolume(value));
                        }
                      },
                      trailingAction: IconButton(
                        key: const Key('attune-mask-next'),
                        tooltip: context.l10n.attuneMaskNext,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: _toneLoading
                            ? null
                            : () => unawaited(_nextMaskTrack()),
                        icon: const Icon(Icons.skip_next_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const AttuneMaskMusicNote(),
                    const SizedBox(height: 8),
                    Text(
                      _maskTitle(context),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.attuneMaskCredit,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    ZenCollapse(
                      show: !_isSessionActive,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: CountSlider(
                          label: context.l10n.sessionLength,
                          valueLabel:
                              context.l10n.minutesShort(_sessionMinutes),
                          minLabel:
                              context.l10n.minutesShort(_sessionMinMinutes),
                          maxLabel:
                              context.l10n.minutesShort(_sessionMaxMinutes),
                          value: _sessionMinutes.toDouble(),
                          min: _sessionMinMinutes.toDouble(),
                          max: _sessionMaxMinutes.toDouble(),
                          divisions: _sessionMaxMinutes == _sessionMinMinutes
                              ? null
                              : _sessionMaxMinutes - _sessionMinMinutes,
                          enabled: !_tonePlaying && !_toneLoading,
                          activeColor: const Color(0xFF7B68EE),
                          sliderKey: const Key('attune-session-slider'),
                          onChanged: (v) => setState(
                            () => _sessionMinutes = v.round(),
                          ),
                        ),
                      ),
                    ),

                    ZenCollapse(
                      show: _isSessionActive,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 28, bottom: 28),
                        child: Text(
                          context.l10n.clock(
                            (_secondsLeft ~/ 60).toString().padLeft(2, '0'),
                            (_secondsLeft % 60).toString().padLeft(2, '0'),
                          ),
                          key: const Key('attune-session-clock'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 40,
                            height: 1,
                            fontFamily: 'monospace',
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),

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
                        onPressed: _toneLoading || _dosageCheck
                            ? null
                            : (_tonePlaying ? _stopTone : _onPlayPressed),
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
                              ? context.l10n.generating
                              : (_tonePlaying
                                  ? context.l10n.stop
                                  : context.l10n.play),
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
                  ],
                  ZenCollapse(
                    show: !_isSessionActive,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),

                        // ── Nature sounds ─────────────────────────────────────────
                        AppSectionLabel(
                          context.l10n.natureSounds,
                          icon: Icons.forest_rounded,
                        ),
                        const SizedBox(height: 12),
                        if (AcousticSynthesisGate.enabled) ...[
                          Text(
                            context.l10n.natureLayer,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          _NoiseSoundGrid(
                            active: _activeSounds,
                            onTap: _toggleNature,
                          ),
                        ] else
                          AcousticUnavailableCard(
                            icon: Icons.forest_rounded,
                            title: context.l10n.natureSoundscapes,
                            subtitle: context.l10n.comingSoon,
                          ),
                      ],
                    ),
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

class _DosageNote extends StatelessWidget {
  final int minutes;

  const _DosageNote({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('attune-dosage-note'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.hourglass_bottom_rounded,
              color: AppColors.amber,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.attuneDosageTitle,
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.attuneDosageBody,
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.attuneDosageToday(minutes),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final AttuneMode selected;
  final ValueChanged<AttuneMode> onSelect;

  const _ModeRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in [
          (AttuneMode.none, context.l10n.none, Icons.volume_off_rounded),
          (
            AttuneMode.binaural,
            context.l10n.binauralShort,
            Icons.headphones_rounded
          ),
          (
            AttuneMode.isochronic,
            context.l10n.isochronicShort,
            Icons.graphic_eq_rounded
          ),
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
                          '${_bandName(context.l10n, band)}  ·  ${_bandRange(context.l10n, band)}',
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
                          _bandUse(context.l10n, band),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    context.l10n.hertzBeat(
                      band.defaultBeatHz.toStringAsFixed(1),
                    ),
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
                  _noiseName(context.l10n, type),
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

String _bandName(AppLocalizations l10n, BrainwaveBand band) {
  switch (band) {
    case BrainwaveBand.delta:
      return l10n.bandDelta;
    case BrainwaveBand.theta:
      return l10n.bandTheta;
    case BrainwaveBand.alpha:
      return l10n.bandAlpha;
    case BrainwaveBand.beta:
      return l10n.bandBeta;
  }
}

String _bandRange(AppLocalizations l10n, BrainwaveBand band) {
  switch (band) {
    case BrainwaveBand.delta:
      return l10n.rangeDelta;
    case BrainwaveBand.theta:
      return l10n.rangeTheta;
    case BrainwaveBand.alpha:
      return l10n.rangeAlpha;
    case BrainwaveBand.beta:
      return l10n.rangeBeta;
  }
}

String _bandUse(AppLocalizations l10n, BrainwaveBand band) {
  switch (band) {
    case BrainwaveBand.delta:
      return l10n.useDelta;
    case BrainwaveBand.theta:
      return l10n.useTheta;
    case BrainwaveBand.alpha:
      return l10n.useAlpha;
    case BrainwaveBand.beta:
      return l10n.useBeta;
  }
}

String _noiseName(AppLocalizations l10n, NatureNoiseType type) {
  switch (type) {
    case NatureNoiseType.rain:
      return l10n.noiseRain;
    case NatureNoiseType.ocean:
      return l10n.noiseOcean;
    case NatureNoiseType.forest:
      return l10n.noiseForest;
    case NatureNoiseType.river:
      return l10n.noiseRiver;
    case NatureNoiseType.thunder:
      return l10n.noiseThunder;
    case NatureNoiseType.wind:
      return l10n.noiseWind;
  }
}
