import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';
import '../../../l10n/l10n.dart';

/// Previously stored when the description was left empty. Treat as the default.
const _legacySafePlaceDefault =
    'Think of a place — real or imagined — where you feel completely safe. '
    'It might be a room, a landscape, a memory. '
    'It belongs only to you.';

List<String> _guidedPrompts(AppLocalizations l10n) => [
      l10n.safePrompt1,
      l10n.safePrompt2,
      l10n.safePrompt3,
      l10n.safePrompt4,
      l10n.safePrompt5,
      l10n.safePrompt6,
      l10n.safePrompt7,
    ];

class SafePlaceScreen extends StatefulWidget {
  const SafePlaceScreen({super.key});

  @override
  State<SafePlaceScreen> createState() => _SafePlaceScreenState();
}

class _SafePlaceScreenState extends State<SafePlaceScreen>
    with SingleTickerProviderStateMixin, SessionTracking {
  bool _editing = false;
  bool _guiding = false;
  bool _askFeeling = false;
  int _promptIndex = 0;
  String? _savedDescription;
  int _sessionMinutes = 5;
  int _sessionSecondsLeft = 0;
  Timer? _promptTimer;
  Timer? _sessionTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..value = 1.0;
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: AppMotion.arrive);
    _loadSafePlace();
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _sessionTimer?.cancel();
    _fadeController.dispose();
    _editController.dispose();
    super.dispose();
  }

  bool _isDefaultDescription(String text) {
    return text == _legacySafePlaceDefault ||
        text == context.l10n.safePlaceDefault;
  }

  String _visibleDescription() {
    final saved = _savedDescription;
    if (saved == null || _isDefaultDescription(saved)) {
      return context.l10n.safePlaceDefault;
    }
    return saved;
  }

  Future<void> _loadSafePlace() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('safe_place_description');
    if (saved != null && mounted) {
      setState(() => _savedDescription = saved);
    }
  }

  Future<void> _saveSafePlace(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('safe_place_description', text);
    if (mounted) {
      setState(() {
        _savedDescription = text;
        _editing = false;
      });
    }
  }

  void _startGuide() {
    final wot = WoTScope.stateOf(context);
    if (wot == null || !wot.canSafePlace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wot == null
                ? context.l10n.safePlaceNeedsCheckin
                : context.l10n.safePlaceLocked(
                    toleranceLock(context.l10n, wot),
                  ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    beginTracking('Safe Place', 'Regulate',
        onEmergencyStop: () => _stopGuide());
    setState(() {
      _guiding = true;
      _askFeeling = false;
      _promptIndex = 0;
      _sessionSecondsLeft = _sessionMinutes * 60;
    });

    // Advance prompts every ~25s
    _promptTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          if (_promptIndex < _guidedPrompts(context.l10n).length - 1) {
            _promptIndex++;
          }
        });
        _fadeController.forward();
      });
    });

    // Session countdown
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_sessionSecondsLeft <= 1) {
        _stopGuide(finished: true);
        return;
      }
      setState(() => _sessionSecondsLeft--);
    });
  }

  void _stopGuide({bool finished = false}) {
    _promptTimer?.cancel();
    _sessionTimer?.cancel();
    endTracking();
    if (mounted) {
      setState(() {
        _guiding = false;
        if (finished) _askFeeling = true;
      });
    }
  }

  String get _sessionDisplay {
    final m = _sessionSecondsLeft ~/ 60;
    final s = _sessionSecondsLeft % 60;
    return context.l10n.clock(
      m.toString().padLeft(2, '0'),
      s.toString().padLeft(2, '0'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.safePlaceTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _stopGuide();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_guiding)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: l10n.customiseSafePlace,
              onPressed: () {
                final saved = _savedDescription;
                _editController.text =
                    saved == null || _isDefaultDescription(saved) ? '' : saved;
                setState(() => _editing = true);
              },
            ),
        ],
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: _editing ? _buildEditor(context) : _buildMain(context),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_guiding) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.landscape_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.yourSafePlace,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _visibleDescription(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Duration selector
            Row(
              children: [
                Text(context.l10n.duration,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                for (final min in [5, 10]) ...[
                  GestureDetector(
                    onTap: () => setState(() => _sessionMinutes = min),
                    child: AnimatedContainer(
                      duration: AppMotion.press,
                      curve: AppMotion.arrive,
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _sessionMinutes == min
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _sessionMinutes == min
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        context.l10n.minutesShort(min),
                        style: TextStyle(
                          color: _sessionMinutes == min
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            if (_askFeeling) ...[
              const FeelingBetterPrompt(),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _startGuide,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.l10n.beginVisualisation,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ] else ...[
            // Guiding mode
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _sessionDisplay,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: Text(
                    _guidedPrompts(context.l10n)[_promptIndex],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _stopGuide(finished: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.l10n.endSession),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.describeSafePlace,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.safePlaceStored,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TextField(
              controller: _editController,
              maxLines: null,
              expands: true,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.7,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.safePlaceHint,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _editing = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    final text = _editController.text.trim();
                    _saveSafePlace(
                      text.isEmpty ? context.l10n.safePlaceDefault : text,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(context.l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
