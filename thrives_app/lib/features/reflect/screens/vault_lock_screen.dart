import 'package:flutter/material.dart';
import 'package:monkeythrive/l10n/l10n.dart';

import '../../../core/storage/journal_service.dart';
import '../../../core/storage/vault_service.dart';
import '../../../core/theme/app_theme.dart';

/// Dark PIN pad for the Reflect key.
///
/// Shown in place of Reflect, and pushed when Build needs the journal.
/// A pushed route can close. The Reflect tab cannot.
class VaultLockScreen extends StatefulWidget {
  const VaultLockScreen({super.key});

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  String _pin = '';
  String? _first;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    VaultService.instance.ensureLoaded();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = context.l10n;
    final pin = _pin;
    if (pin.length < 6) {
      setState(() => _error = l10n.vaultShort);
      return;
    }
    final vault = VaultService.instance;
    await vault.ensureLoaded();
    if (!mounted || vault.storageBroken) return;

    if (!vault.isProtected) {
      final first = _first;
      if (first == null) {
        setState(() {
          _first = pin;
          _pin = '';
          _error = null;
        });
        return;
      }
      if (first != pin) {
        setState(() {
          _first = null;
          _pin = '';
          _error = l10n.vaultMismatch;
        });
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = vault.isProtected
        ? await vault.unlock(pin)
        : await vault.createPin(pin);
    if (ok) await JournalService.resealAll();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _pin = '';
        _error = vault.isProtected ? l10n.vaultWrong : l10n.vaultShort;
      });
      return;
    }
    final route = ModalRoute.of(context);
    if (route != null && route.canPop) {
      Navigator.of(context).pop();
    }
  }

  void _digit(String digit) {
    if (_busy || _pin.length >= 12) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _delete() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  String _lead(AppLocalizations l10n, VaultService vault) {
    if (!vault.isProtected) {
      return _first == null ? l10n.vaultCreateLead : l10n.vaultConfirmLead;
    }
    return l10n.vaultEnterLead;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VaultService.instance,
      builder: (context, _) {
        final vault = VaultService.instance;
        final l10n = context.l10n;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: !vault.isReady
                ? const SizedBox.shrink()
                : vault.storageBroken
                    ? _Notice(l10n.vaultUnread)
                    : _Pad(
                        lead: _lead(l10n, vault),
                        pinLength: _pin.length,
                        error: _error,
                        busy: _busy,
                        onDigit: _digit,
                        onDelete: _delete,
                        onSubmit: _submit,
                      ),
          ),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 72, 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  final String lead;
  final int pinLength;
  final String? error;
  final bool busy;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const _Pad({
    required this.lead,
    required this.pinLength,
    required this.error,
    required this.busy,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final ready = pinLength >= 6 && !busy;
    return AbsorbPointer(
      absorbing: busy,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Text(
              l10n.navReflect,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lead,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            _Dots(length: pinLength),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: busy
                  ? Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Text(
                      error ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(
                      children: [
                        for (final digit in row)
                          Expanded(
                            child: _Key(
                              onTap: () => onDigit(digit),
                              key: Key('vault-digit-$digit'),
                              child: Text(
                                digit,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _Key(
                          onTap: onDelete,
                          key: const Key('vault-delete'),
                          child: Icon(
                            Icons.backspace_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                            semanticLabel: l10n.vaultDeleteDigit,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _Key(
                          onTap: () => onDigit('0'),
                          key: const Key('vault-digit-0'),
                          child: const Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _Key(
                          onTap: onSubmit,
                          key: const Key('vault-ok'),
                          color: ready
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          child: Icon(
                            Icons.check_rounded,
                            color: ready
                                ? Theme.of(context).scaffoldBackgroundColor
                                : AppColors.textMuted,
                            semanticLabel: l10n.continueAction,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int length;
  const _Dots({required this.length});

  @override
  Widget build(BuildContext context) {
    final shown = length == 0 ? 6 : length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < shown; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < length ? AppColors.textPrimary : Colors.transparent,
              border: Border.all(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;

  const _Key({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(height: 58, child: Center(child: child)),
        ),
      ),
    );
  }
}
