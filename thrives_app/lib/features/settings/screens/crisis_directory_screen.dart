import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/data/crisis_dialer.dart';
import '../../../core/data/crisis_helplines.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_theme.dart';

// CLINICAL SAFETY — Offline crisis directory
// What this does: Shows crisis and emergency numbers stored in the app,
//   filters them on the device, and opens the phone dialer only after the
//   number is confirmed.
// Why it exists: A person who needs another human should not have to search
//   the web, create an account, or tell this app where they are.
// What happens if removed: The in-app path to real-world help disappears.
// The selected country is a local display preference. It is never sent.

class CrisisDirectoryScreen extends StatefulWidget {
  const CrisisDirectoryScreen({super.key, this.dialer});

  /// Test seam. Production uses the platform dialer.
  final CrisisDialer? dialer;

  @override
  State<CrisisDirectoryScreen> createState() => _CrisisDirectoryScreenState();
}

class _CrisisDirectoryScreenState extends State<CrisisDirectoryScreen> {
  final _search = TextEditingController();
  late String _countryId;

  CrisisDialer get _dialer => widget.dialer ?? const CrisisDialer();

  @override
  void initState() {
    super.initState();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _countryId = countryIdForDeviceLocale(
      countryCode: locale.countryCode,
      languageCode: locale.languageCode,
    );
    _restoreCountry();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _restoreCountry() async {
    final saved = await PrefsService.loadCrisisCountry();
    if (!mounted) return;
    final region = crisisRegionById(saved);
    if (region == null) return;
    setState(() => _countryId = region.id);
  }

  Future<void> _selectCountry(String? id) async {
    if (id == null || crisisRegionById(id) == null) return;
    setState(() => _countryId = id);
    await PrefsService.saveCrisisCountry(id);
  }

  Future<void> _confirmAndOpen(CrisisContact contact) async {
    final text = contact.usesText;
    final uri = text ? contact.smsUri : contact.telUri;
    if (uri == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmCallDialog(
        contact: contact,
        text: text,
      ),
    );
    if (confirmed != true || !mounted) return;

    var opened = false;
    try {
      opened = await _dialer.open(uri);
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;

    final message = text
        ? 'The messages app did not open. The number is still on this screen.'
        : 'The phone app did not open. The number is still on this screen for you to dial.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copy(CrisisContact contact) {
    final value = contact.dialsDifferentDigits
        ? dialableNumber(contact.number)
        : contact.number;
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Number copied'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visible = visibleCrisisContacts(
      countryId: _countryId,
      query: _search.text,
    );
    final pinned = [
      for (final contact in visible)
        if (contact.category != CrisisCategory.helpline) contact,
    ];
    final support = [
      for (final contact in visible)
        if (contact.category == CrisisCategory.helpline) contact,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crisis support',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'If you are in immediate danger, call the emergency number for where you are.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel('Country'),
                  _CountryDropdown(
                    countryId: _countryId,
                    onChanged: _selectCountry,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('crisis-search'),
                    controller: _search,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    cursorColor: colors.primary,
                    decoration: InputDecoration(
                      hintText: 'Search name or number',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: _fieldBorder(colors.surfaceContainerHighest),
                      enabledBorder:
                          _fieldBorder(colors.surfaceContainerHighest),
                      focusedBorder: _fieldBorder(colors.primary),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  const _Disclaimer(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  if (visible.isEmpty)
                    const Text(
                      'No lines are stored for this country. Choose International for what to do next.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  for (final contact in pinned) ...[
                    _ContactCard(
                      countryId: _countryId,
                      contact: contact,
                      onOpen: () => _confirmAndOpen(contact),
                      onCopy: () => _copy(contact),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (support.isNotEmpty) ...[
                    const _FieldLabel('Support lines'),
                    const SizedBox(height: 8),
                    for (final contact in support) ...[
                      _ContactCard(
                        countryId: _countryId,
                        contact: contact,
                        onOpen: () => _confirmAndOpen(contact),
                        onCopy: () => _copy(contact),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (_search.text.trim().isNotEmpty && support.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No support lines match that search. The emergency number stays listed above.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (_countryId != regionInternational.id)
                    const Text(
                      'Somewhere else? Choose International in the country list.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  final String countryId;
  final ValueChanged<String?> onChanged;

  const _CountryDropdown({
    required this.countryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceContainerHighest),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: const Key('crisis-country'),
            value: countryId,
            isExpanded: true,
            dropdownColor: colors.surface,
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            items: [
              for (final region in crisisRegions)
                DropdownMenuItem(
                  value: region.id,
                  child: Text(region.label),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceContainerHighest),
      ),
      child: const Text(
        crisisDirectoryDisclaimer,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String countryId;
  final CrisisContact contact;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  const _ContactCard({
    required this.countryId,
    required this.contact,
    required this.onOpen,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEmergency = contact.category == CrisisCategory.emergency;
    final id = crisisContactId(countryId, contact);
    final canOpen = contact.telUri != null || contact.smsUri != null;
    final accent = isEmergency ? AppColors.danger : colors.primary;

    return Container(
      key: Key('crisis-card-$id'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isEmergency ? AppColors.danger : colors.surfaceContainerHighest,
          width: isEmergency ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              contact.category.label.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            contact.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            contact.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (canOpen) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Material(
                    color: accent.withValues(alpha: isEmergency ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: Key(
                        contact.usesText
                            ? 'crisis-text-$id'
                            : 'crisis-call-$id',
                      ),
                      borderRadius: BorderRadius.circular(12),
                      onTap: onOpen,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: accent.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              contact.usesText
                                  ? Icons.sms_rounded
                                  : Icons.phone_rounded,
                              color: accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                contact.usesText
                                    ? 'Text ${contact.smsOptional} to ${contact.number}'
                                    : contact.number,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Copy number',
                  onPressed: onCopy,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (contact.dialsDifferentDigits) ...[
              const SizedBox(height: 8),
              Text(
                'Dials ${dialableNumber(contact.number)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConfirmCallDialog extends StatelessWidget {
  final CrisisContact contact;
  final bool text;

  const _ConfirmCallDialog({
    required this.contact,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEmergency = contact.category == CrisisCategory.emergency;
    final actionLabel =
        text ? 'Text ${contact.number}' : 'Call ${contact.number}';

    return AlertDialog(
      backgroundColor: colors.surface,
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        text ? 'Send this text?' : 'Call this number?',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            contact.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              contact.number,
              key: const Key('crisis-confirm-number'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          if (contact.dialsDifferentDigits) ...[
            const SizedBox(height: 8),
            Text(
              'Dials ${dialableNumber(contact.number)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          if (text) ...[
            const SizedBox(height: 16),
            const Text(
              'Message',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact.smsOptional ?? '',
              key: const Key('crisis-confirm-message'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            text
                ? 'This opens your messages app with the text ready. This app does not send it or use the internet.'
                : 'This opens your phone dialer with the number ready. This app does not place the call or use the internet.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isEmergency ? AppColors.danger : colors.primary,
            foregroundColor: isEmergency ? Colors.white : colors.onPrimary,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
