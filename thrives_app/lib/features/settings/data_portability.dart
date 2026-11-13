import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/storage/archive_file.dart';
import '../../core/storage/portable_archive.dart';
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
      title: const Text(
        'Export',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: token == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The copy is sealed with a passphrase you choose. '
                    'MonkeyThrive does not keep that passphrase and cannot '
                    'open the copy without it. Nothing is uploaded.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PassphraseField(
                      controller: _passphrase, label: 'Passphrase'),
                  const SizedBox(height: 8),
                  _PassphraseField(
                      controller: _repeat, label: 'Repeat passphrase'),
                  if (_error != null) _ErrorText(_error!),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keep this copy somewhere you control. Opening it on '
                    'another device needs the same passphrase.',
                    style: TextStyle(
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
                      'Saved: $_savedAs',
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
          child: const Text(
            'Close',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (token == null)
          TextButton(
            onPressed: _working ? null : _create,
            child: Text(
              _working ? 'Sealing' : 'Create copy',
              style: const TextStyle(color: AppColors.teal),
            ),
          )
        else
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save file and copy',
              style: TextStyle(color: AppColors.teal),
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
        const SnackBar(
          content: Text('Copy restored on this device.'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Import',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This replaces the journal, check-ins, session log, '
              'trusted people, and preferences on this device. '
              'It does not contact a server.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            _PassphraseField(controller: _passphrase, label: 'Passphrase'),
            const SizedBox(height: 8),
            TextField(
              controller: _token,
              minLines: 3,
              maxLines: 6,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: _fieldDecoration('Paste the copy'),
            ),
            if (_error != null) _ErrorText(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _working ? null : _restore,
          child: Text(
            _working ? 'Restoring' : 'Restore',
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
        message,
        style:
            const TextStyle(color: AppColors.danger, fontSize: 13, height: 1.4),
      ),
    );
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
