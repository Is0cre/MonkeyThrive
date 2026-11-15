import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monkeythrive/l10n/l10n.dart';

import '../../core/storage/archive_file.dart';
import '../../core/storage/portable_archive.dart';
import '../../core/storage/vault_service.dart';
import '../../core/storage/tier_service.dart';
import '../../core/theme/app_appearance.dart';
import '../../core/theme/app_theme.dart';

const _backupName = 'monkeythrive-backup.mtbackup';

Future<void> showLocalExportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ExportDialog(),
  );
}

Future<void> showLocalImportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ImportDialog(),
  );
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  final _passphrase = TextEditingController();
  final _repeat = TextEditingController();
  String? _token;
  String? _savedAs;
  String? _error;
  bool _working = false;

  @override
  void dispose() {
    _passphrase.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final passphrase = _passphrase.text;
    if (passphrase != _repeat.text) {
      setState(() => _error = 'The two passphrases do not match.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final token = await PortableArchive.exportSealed(passphrase);
      if (!mounted) return;
      setState(() {
        _token = token;
        _working = false;
      });
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message?.toString();
        _working = false;
      });
    } on VaultLockedException {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.vaultCopyLocked;
        _working = false;
      });
    }
  }

  Future<void> _save() async {
    final token = _token;
    if (token == null) return;
    final saved = await saveTextFile(_backupName, token);
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    setState(() => _savedAs = saved);
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.export,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: token == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.exportBody,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PassphraseField(
                      controller: _passphrase, label: context.l10n.passphrase),
                  const SizedBox(height: 8),
                  _PassphraseField(
                      controller: _repeat,
                      label: context.l10n.repeatPassphrase),
                  if (_error != null) _ErrorText(_error!),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.exportKeep,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    token,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  if (_savedAs != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.savedAs(_savedAs!),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.close,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (token == null)
          TextButton(
            onPressed: _working ? null : _create,
            child: Text(
              _working ? context.l10n.sealing : context.l10n.createCopy,
              style: const TextStyle(color: AppColors.teal),
            ),
          )
        else
          TextButton(
            onPressed: _save,
            child: Text(
              context.l10n.saveFileAndCopy,
              style: const TextStyle(color: AppColors.teal),
            ),
          ),
      ],
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _passphrase = TextEditingController();
  final _token = TextEditingController();
  String? _error;
  bool _working = false;

  @override
  void dispose() {
    _passphrase.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await PortableArchive.importSealed(_token.text, _passphrase.text);
      await AppAppearanceController.instance.load();
      await TierService.init();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.copyRestored),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _working = false;
      });
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message?.toString();
        _working = false;
      });
    } on VaultLockedException {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.vaultCopyLocked;
        _working = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.import,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.importBody,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            _PassphraseField(
                controller: _passphrase, label: context.l10n.passphrase),
            const SizedBox(height: 8),
            TextField(
              controller: _token,
              minLines: 3,
              maxLines: 6,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: _fieldDecoration(context.l10n.pasteTheCopy),
            ),
            if (_error != null) _ErrorText(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.cancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _working ? null : _restore,
          child: Text(
            _working ? context.l10n.restoring : context.l10n.restore,
            style: const TextStyle(color: AppColors.teal),
          ),
        ),
      ],
    );
  }
}

class _PassphraseField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PassphraseField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(label),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        _archiveErrorText(context.l10n, message),
        style:
            const TextStyle(color: AppColors.danger, fontSize: 13, height: 1.4),
      ),
    );
  }
}

/// The seal keeps these sentences in English. Show the matching translation.
String _archiveErrorText(AppLocalizations l10n, String message) {
  switch (message) {
    case 'The two passphrases do not match.':
      return l10n.passphrasesDoNotMatch;
    case 'This is not a MonkeyThrive copy.':
      return l10n.notACopy;
    case 'This copy could not be read.':
      return l10n.copyUnreadable;
    case 'This copy is from a newer version.':
      return l10n.copyNewer;
    case 'That passphrase did not open this copy.':
      return l10n.passphraseWrong;
    case 'Use at least 8 characters.':
      return l10n.passphraseMin(8);
    default:
      return message;
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.surfaceVariant),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.teal),
    ),
  );
}
