import 'package:flutter/material.dart';

import '../../core/data/crisis_dialer.dart';
import '../../core/models/tolerance_state.dart';
import '../../core/models/trusted_person.dart';
import '../../core/state/wot_scope.dart';
import '../../core/storage/prefs_service.dart';
import '../../core/theme/app_theme.dart';
import 'trusted_people_screen.dart';

/// One-tap text and call for people saved on this device.
///
/// [offerSetup] adds the editor link once today's reading is present, and a
/// readable note while it is not. The note is not the form.
class TrustedPersonBanner extends StatefulWidget {
  const TrustedPersonBanner({
    super.key,
    this.dialer,
    this.onBlack = false,
    this.offerSetup = false,
  });

  final CrisisDialer? dialer;
  final bool onBlack;
  final bool offerSetup;

  @override
  State<TrustedPersonBanner> createState() => _TrustedPersonBannerState();
}

class _TrustedPersonBannerState extends State<TrustedPersonBanner> {
  List<TrustedPerson> _people = const [];
  bool _ready = false;

  CrisisDialer get _dialer => widget.dialer ?? const CrisisDialer();

  @override
  void initState() {
    super.initState();
    trustedPeopleRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    trustedPeopleRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final people = await PrefsService.loadTrustedPeople();
    if (!mounted) return;
    setState(() {
      _people = people;
      _ready = true;
    });
  }

  Future<void> _open(TrustedPerson person, {required bool text}) async {
    final uri = text ? person.smsUri : person.telUri;
    var opened = false;
    try {
      opened = await _dialer.open(uri);
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    final message =
        text ? 'The messages app did not open.' : 'The phone app did not open.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TrustedPeopleScreen()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final present = context
            .dependOnInheritedWidgetOfExactType<WoTScope>()
            ?.notifier
            ?.value ==
        ToleranceState.regulated;
    final ink = widget.onBlack ? const Color(0xFF1A140C) : AppColors.background;

    final rows = <Widget>[];
    for (var i = 0; i < _people.length; i++) {
      final person = _people[i];
      rows.add(
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                key: Key('trusted-text-$i'),
                label: 'Text ${person.name}',
                filled: true,
                ink: ink,
                onPressed: () => _open(person, text: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                key: Key('trusted-call-$i'),
                label: 'Call ${person.name}',
                filled: false,
                ink: ink,
                onPressed: () => _open(person, text: false),
              ),
            ),
          ],
        ),
      );
      rows.add(const SizedBox(height: 8));
    }

    if (widget.offerSetup && present) {
      rows.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: Key(_people.isEmpty ? 'trusted-setup' : 'trusted-edit'),
            onPressed: _edit,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _people.isEmpty ? 'Save a trusted person' : 'Edit trusted people',
            ),
          ),
        ),
      );
    } else if (widget.offerSetup && _people.isEmpty) {
      rows.add(
        const Text(
          'A trusted person can be saved when the reading is present.',
          key: Key('trusted-closed'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_people.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Trusted person',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ...rows,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.filled,
    required this.ink,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final Color ink;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.amber,
        side: const BorderSide(color: AppColors.amber),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: child,
    );
  }
}
