import 'package:flutter/foundation.dart';

import '../data/crisis_dialer.dart';

// CLINICAL SAFETY — Trusted person shortcut
// What this does: Stores one or two people the user chose while the reading
//   was present, and builds a tel: or sms: link for a later one-tap handoff.
// Why it exists: Composing a message during freeze or acute distress is often
//   not possible. The native phone apps still place the call or send the text.
// What happens if removed: The prepared handoff disappears. The crisis
//   directory remains.
// This does not read the address book, send a message, or decide how the
//   person is feeling.

/// Bumped after the saved list changes so open screens can reload.
final trustedPeopleRevision = ValueNotifier<int>(0);

/// A person saved on this device for a one-tap text or call.
class TrustedPerson {
  const TrustedPerson({
    required this.name,
    required this.phone,
    required this.message,
  });

  static const limit = 2;
  static const nameLimit = 40;
  static const messageLimit = 160;

  static const suggestions = <String>[
    "I'm feeling overwhelmed right now. Could you sit with me or send a quiet check-in? No need to fix anything.",
    "Having a rough moment and grounding myself. Just letting you know so I'm not alone.",
  ];

  final String name;
  final String phone;
  final String message;

  Uri get telUri => Uri(scheme: 'tel', path: phone);

  Uri get smsUri => Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': message},
      );

  Map<String, String> toJson() => {
        'name': name,
        'phone': phone,
        'message': message,
      };

  /// Returns null when the stored record is not safe to dial.
  static TrustedPerson? tryParse(Map<String, dynamic> json) {
    final name = json['name'];
    final phone = json['phone'];
    final message = json['message'];
    if (name is! String || phone is! String || message is! String) {
      return null;
    }
    return tryMake(name: name, phone: phone, message: message);
  }

  /// Returns null when the name, number, or message cannot be handed off.
  static TrustedPerson? tryMake({
    required String name,
    required String phone,
    required String message,
  }) {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanPhone = normalizeTrustedPhone(phone);
    final cleanMessage = message.trim();
    if (cleanName.isEmpty ||
        cleanName.length > nameLimit ||
        cleanPhone == null ||
        cleanMessage.isEmpty ||
        cleanMessage.length > messageLimit) {
      return null;
    }
    final person = TrustedPerson(
      name: cleanName,
      phone: cleanPhone,
      message: cleanMessage,
    );
    try {
      validateCrisisUri(person.telUri);
      validateCrisisUri(person.smsUri);
    } on ArgumentError {
      return null;
    }
    return person;
  }
}

/// Keeps a leading + and the digits. Spaces and dashes are dropped.
String? normalizeTrustedPhone(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final plus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 6 || digits.length > 15) return null;
  return plus ? '+$digits' : digits;
}
