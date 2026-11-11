import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

const _defaultSafePlace =
    'Think of a place — real or imagined — where you feel completely safe. '
    'It might be a room, a landscape, a memory. '
    'It belongs only to you.';

const _guidedPrompts = [
  'Settle in. There is nowhere you need to be right now.\n\n'
      'Let your breathing slow naturally.',
  'Bring your safe place to mind. Allow yourself to arrive there.',
  'Notice what you can see. The colours, the light, the shapes around you.',
  'What sounds are here? Gentle, familiar sounds that belong to this place.',
  'Feel the temperature. The air on your skin. The ground beneath you.',
  'You are safe here. Nothing can reach you in this place.',
  'Stay as long as you need. This place is always available to you.\n\n'
      'You can return here any time you close your eyes.',
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
  int _promptIndex = 0;
  String _safePlaceDescription = _defaultSafePlace;
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
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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

  Future<void> _loadSafePlace() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('safe_place_description');
    if (saved != null && mounted) {
      setState(() => _safePlaceDescription = saved);
    }
  }

  Future<void> _saveSafePlace(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('safe_place_description', text);
    if (mounted) {
      setState(() {
        _safePlaceDescription = text;
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
                ? 'Check in before using safe place.'
                : 'Safe place is ${wot.lockedReason}.',
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    beginTracking('Safe Place', 'Regulate', onEmergencyStop: _stopGuide);
    setState(() {
      _guiding = true;
      _promptIndex = 0;
      _sessionSecondsLeft = _sessionMinutes * 60;
    });

    // Advance prompts every ~25s
    _promptTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          if (_promptIndex < _guidedPrompts.length - 1) {
            _promptIndex++;
          }
        });
        _fadeController.forward();
      });
    });

    // Session countdown
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _sessionSecondsLeft--;
        if (_sessionSecondsLeft <= 0) {
          _stopGuide();
        }
      });
    });
  }

  void _stopGuide() {
    _promptTimer?.cancel();
    _sessionTimer?.cancel();
    endTracking();
    if (mounted) setState(() => _guiding = false);
  }

  String get _sessionDisplay {
    final m = _sessionSecondsLeft ~/ 60;
    final s = _sessionSecondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Place'),
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
              tooltip: 'Customise your safe place',
              onPressed: () {
                _editController.text =
                    _safePlaceDescription == _defaultSafePlace
                        ? ''
                        : _safePlaceDescription;
                setState(() => _editing = true);
              },
            ),
        ],
      ),
      floatingActionButton: const EmergencyButton(),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.landscape_rounded,
                          color: AppColors.amber, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Your safe place',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _safePlaceDescription,
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
                const Text('Duration',
                    style: TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                for (final min in [5, 10]) ...[
                  GestureDetector(
                    onTap: () => setState(() => _sessionMinutes = min),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _sessionMinutes == min
                            ? AppColors.amber.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _sessionMinutes == min
                              ? AppColors.amber
                              : AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${min}m',
                        style: TextStyle(
                          color: _sessionMinutes == min
                              ? AppColors.amber
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _startGuide,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Begin visualisation',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                    _guidedPrompts[_promptIndex],
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
                onPressed: _stopGuide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('End session'),
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
            'Describe your safe place',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'This is stored only on your device. '
            'Write whatever feels right — it only needs to make sense to you.',
            style: TextStyle(
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
                hintText: 'A quiet beach, a childhood room, a forest clearing…',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
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
                    side: const BorderSide(color: AppColors.surfaceVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    final text = _editController.text.trim();
                    _saveSafePlace(text.isEmpty ? _defaultSafePlace : text);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w500)),
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
