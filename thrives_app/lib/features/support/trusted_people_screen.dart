import 'package:flutter/material.dart';

import '../../core/models/tolerance_state.dart';
import '../../core/models/trusted_person.dart';
import '../../core/state/wot_scope.dart';
import '../../core/storage/prefs_service.dart';
import '../../core/theme/app_theme.dart';

/// Edits the one or two saved people. Fields stay closed unless the reading
/// is present, so this screen is not a form to finish during distress.
class TrustedPeopleScreen extends StatefulWidget {
  const TrustedPeopleScreen({super.key});

  @override
  State<TrustedPeopleScreen> createState() => _TrustedPeopleScreenState();
}

class _Draft {
  _Draft({
    required this.name,
    required this.phone,
    required this.message,
    this.persisted = false,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController message;
  bool persisted;
  String? error;

  void dispose() {
    name.dispose();
    phone.dispose();
    message.dispose();
  }
}

class _TrustedPeopleScreenState extends State<TrustedPeopleScreen> {
  final _drafts = <_Draft>[];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final people = await PrefsService.loadTrustedPeople();
    if (!mounted) return;
    setState(() {
      for (final draft in _drafts) {
        draft.dispose();
      }
      _drafts
        ..clear()
        ..addAll(people.map(_draftFromPerson));
      if (_drafts.isEmpty) _drafts.add(_blankDraft(0));
      _ready = true;
    });
  }

  _Draft _draftFromPerson(TrustedPerson person) {
    return _Draft(
      name: TextEditingController(text: person.name),
      phone: TextEditingController(text: person.phone),
      message: TextEditingController(text: person.message),
      persisted: true,
    );
  }

  _Draft _blankDraft(int index) {
    final suggestion = TrustedPerson
        .suggestions[index.clamp(0, TrustedPerson.suggestions.length - 1)];
    return _Draft(
      name: TextEditingController(),
      phone: TextEditingController(),
      message: TextEditingController(text: suggestion),
    );
  }

  Future<void> _persist() async {
    final people = <TrustedPerson>[];
    for (final draft in _drafts) {
      final person = TrustedPerson.tryMake(
        name: draft.name.text,
        phone: draft.phone.text,
        message: draft.message.text,
      );
      if (person != null) people.add(person);
    }
    await PrefsService.saveTrustedPeople(people);
  }

  Future<void> _save(int index) async {
    final draft = _drafts[index];
    final person = TrustedPerson.tryMake(
      name: draft.name.text,
      phone: draft.phone.text,
      message: draft.message.text,
    );
    if (person == null) {
      setState(() {
        draft.error = _reason(draft);
      });
      return;
    }
    setState(() {
      draft.error = null;
      draft.persisted = true;
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved on this device.'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _reason(_Draft draft) {
    final name = draft.name.text.trim();
    if (name.isEmpty) return 'Add a name.';
    if (name.length > TrustedPerson.nameLimit) return 'Use a shorter name.';
    if (normalizeTrustedPhone(draft.phone.text) == null) {
      return 'Use a phone number, with the country code if it needs one.';
    }
    final message = draft.message.text.trim();
    if (message.isEmpty) return 'Add a short message.';
    if (message.length > TrustedPerson.messageLimit) {
      return 'Keep the message to ${TrustedPerson.messageLimit} characters.';
    }
    return 'That number cannot be opened from here.';
  }

  Future<void> _remove(int index) async {
    final draft = _drafts[index];
    if (draft.persisted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Remove this person?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            draft.name.text.trim().isEmpty
                ? 'The saved number will be removed from this device.'
                : '${draft.name.text.trim()} will be removed from this device.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Keep',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              key: const Key('trusted-remove-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Remove',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _drafts.removeAt(index).dispose();
      if (_drafts.isEmpty) _drafts.add(_blankDraft(0));
    });
    await _persist();
  }

  void _add() {
    if (_drafts.length >= TrustedPerson.limit) return;
    setState(() => _drafts.add(_blankDraft(_drafts.length)));
  }

  @override
  Widget build(BuildContext context) {
    final present = context
            .dependOnInheritedWidgetOfExactType<WoTScope>()
            ?.notifier
            ?.value ==
        ToleranceState.regulated;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Trusted person',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SafeArea(
        child: !present
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This can be saved when the reading is present.',
                  key: Key('trusted-screen-closed'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    height: 1.45,
                  ),
                ),
              )
            : !_ready
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    children: [
                      const Text(
                        'Saved on this device. Text and call open your phone\'s own apps. Nothing is sent from here.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < _drafts.length; i++) ...[
                        _PersonForm(
                          index: i,
                          draft: _drafts[i],
                          onSave: () => _save(i),
                          onRemove: () => _remove(i),
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_drafts.length < TrustedPerson.limit)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: const Key('trusted-add'),
                            onPressed: _add,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.amber,
                              minimumSize: const Size(48, 48),
                            ),
                            child: const Text('Add another person'),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _PersonForm extends StatelessWidget {
  const _PersonForm({
    required this.index,
    required this.draft,
    required this.onSave,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _Draft draft;
  final VoidCallback onSave;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.surfaceContainerHighest),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Name',
              fieldKey: Key('trusted-name-$index'),
              controller: draft.name,
              onChanged: onChanged,
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Phone number',
              fieldKey: Key('trusted-phone-$index'),
              controller: draft.phone,
              keyboard: TextInputType.phone,
              onChanged: onChanged,
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Message',
              fieldKey: Key('trusted-message-$index'),
              controller: draft.message,
              maxLength: TrustedPerson.messageLimit,
              lines: 4,
              onChanged: onChanged,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var s = 0; s < TrustedPerson.suggestions.length; s++)
                  ActionChip(
                    key: Key('trusted-suggestion-$index-$s'),
                    label: Text(
                      s == 0 ? 'Sit with me' : 'Just letting you know',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    backgroundColor: colors.surfaceContainerHighest,
                    side: BorderSide.none,
                    onPressed: () {
                      draft.message.text = TrustedPerson.suggestions[s];
                      onChanged();
                    },
                  ),
              ],
            ),
            if (draft.error != null) ...[
              const SizedBox(height: 10),
              Text(
                draft.error!,
                key: Key('trusted-error-$index'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  key: Key('trusted-save-$index'),
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: const Color(0xFF1A140C),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Save'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: Key('trusted-remove-$index'),
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.onChanged,
    this.keyboard,
    this.maxLength,
    this.lines = 1,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextInputType? keyboard;
  final int? maxLength;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboard,
          maxLength: maxLength,
          minLines: lines,
          maxLines: lines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          cursorColor: colors.primary,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            counterStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: _border(colors.surfaceContainerHighest),
            enabledBorder: _border(colors.surfaceContainerHighest),
            focusedBorder: _border(colors.primary),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
