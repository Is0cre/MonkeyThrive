// Offline crisis directory.
// Numbers are compiled into the app. Nothing here is fetched, refreshed, or
// reported over the network.
//
// Checked in November 2026 against the organisations that publish them:
// Mind (90101, open around the clock), 1177, NCMH (1553 and the Globe / Smart
// lines), and TelefonSeelsorge (0800 111 0 111, free and anonymous).
// 112, 911, 999, 988, 111, and 116 123 are the national numbers for the
// countries below. Germany's police number is 110 because 112 does not reach
// the police there.

/// How a line should be presented. Emergency numbers stay visually distinct
/// from specialised helplines.
enum CrisisCategory {
  emergency('Emergency'),
  helpline('Support line'),
  guidance('Where you are');

  const CrisisCategory(this.label);

  final String label;
}

/// One crisis or emergency contact stored on the device.
///
/// [smsOptional] is the message to prefill when the line is reached by text.
/// A text line does not also offer a voice call. Null means voice only.
class CrisisContact {
  final String country;
  final String name;
  final String number;
  final CrisisCategory category;
  final String description;
  final String? smsOptional;

  const CrisisContact({
    required this.country,
    required this.name,
    required this.number,
    required this.category,
    required this.description,
    this.smsOptional,
  });

  bool get usesText => smsUri != null;

  /// True when the published number contains letters, as with 0917-899-USAP.
  bool get dialsDifferentDigits {
    final plain = number.replaceAll(RegExp(r'[^0-9+]'), '');
    return plain != dialableNumber(number);
  }

  /// Voice link, or null when this contact is text-only or has no number.
  Uri? get telUri {
    if (smsOptional != null) return null;
    return _numberedUri('tel');
  }

  /// Text link with the keyword prefilled, or null when this contact is voice-only.
  Uri? get smsUri {
    final keyword = smsOptional?.trim();
    if (keyword == null || keyword.isEmpty) return null;
    final digits = dialableNumber(number);
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(digits)) return null;
    return Uri(scheme: 'sms', path: digits, queryParameters: {'body': keyword});
  }

  Uri? _numberedUri(String scheme) {
    final digits = dialableNumber(number);
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(digits)) return null;
    return Uri(scheme: scheme, path: digits);
  }
}

class CrisisRegion {
  final String id;
  final String label;

  const CrisisRegion({required this.id, required this.label});
}

const swedenCountry = 'Sweden (Sverige)';
const unitedStatesCountry = 'United States';
const unitedKingdomCountry = 'United Kingdom';
const philippinesCountry = 'Philippines';
const germanyCountry = 'Germany';
const maltaCountry = 'Malta';
const internationalCountry = 'International';

const regionSweden = CrisisRegion(id: 'se', label: swedenCountry);
const regionUnitedStates = CrisisRegion(id: 'us', label: unitedStatesCountry);
const regionUnitedKingdom = CrisisRegion(id: 'gb', label: unitedKingdomCountry);
const regionPhilippines = CrisisRegion(id: 'ph', label: philippinesCountry);
const regionGermany = CrisisRegion(id: 'de', label: germanyCountry);
const regionMalta = CrisisRegion(id: 'mt', label: maltaCountry);
const regionInternational =
    CrisisRegion(id: 'intl', label: internationalCountry);

const crisisRegions = <CrisisRegion>[
  regionSweden,
  regionUnitedStates,
  regionUnitedKingdom,
  regionPhilippines,
  regionGermany,
  regionMalta,
  regionInternational,
];

const crisisDirectoryDisclaimer =
    'These directories are stored completely offline on your device. '
    'Calls route through your cellular provider and standard carrier rates '
    'or calling rules apply.';

const crisisContacts = <CrisisContact>[
  CrisisContact(
    country: swedenCountry,
    name: 'Akut nöd',
    number: '112',
    category: CrisisCategory.emergency,
    description:
        'Police, ambulance, and fire. Use this when a life is in danger right now. Open around the clock.',
  ),
  CrisisContact(
    country: swedenCountry,
    name: 'Mind Självmordslinjen',
    number: '90101',
    category: CrisisCategory.helpline,
    description:
        'Mind\'s suicide prevention line. For you, or for someone you are worried about. Anonymous, free, and open around the clock.',
  ),
  CrisisContact(
    country: swedenCountry,
    name: 'Kvinnofridslinjen',
    number: '116 123',
    category: CrisisCategory.helpline,
    description:
        'National line for women subjected to violence or threats, and for people close to them. Free, and open around the clock.',
  ),
  CrisisContact(
    country: swedenCountry,
    name: 'Sjukvårdsrådgivning',
    number: '1177',
    category: CrisisCategory.helpline,
    description:
        'Nurse advice for illness and care questions that are not life-threatening. Open around the clock.',
  ),
  CrisisContact(
    country: unitedStatesCountry,
    name: 'Emergency',
    number: '911',
    category: CrisisCategory.emergency,
    description:
        'Police, ambulance, and fire. Use this when a life is in danger right now. Open around the clock.',
  ),
  CrisisContact(
    country: unitedStatesCountry,
    name: 'Suicide & Crisis Lifeline',
    number: '988',
    category: CrisisCategory.helpline,
    description:
        'For emotional distress and suicidal thoughts. You can call. In the United States you can also text this same number. Open around the clock.',
  ),
  CrisisContact(
    country: unitedStatesCountry,
    name: 'Crisis Text Line',
    number: '741741',
    category: CrisisCategory.helpline,
    description:
        'Text HOME to reach a crisis counselor. This is a text line, not a voice call. Open around the clock.',
    smsOptional: 'HOME',
  ),
  CrisisContact(
    country: unitedKingdomCountry,
    name: 'Emergency',
    number: '999',
    category: CrisisCategory.emergency,
    description:
        'Police, ambulance, fire, and coastguard. Use this when a life is in danger right now. Open around the clock.',
  ),
  CrisisContact(
    country: unitedKingdomCountry,
    name: 'NHS non-emergency',
    number: '111',
    category: CrisisCategory.helpline,
    description:
        'NHS advice for health problems that are not life-threatening. Open around the clock.',
  ),
  CrisisContact(
    country: unitedKingdomCountry,
    name: 'Samaritans',
    number: '116 123',
    category: CrisisCategory.helpline,
    description:
        'Someone to talk with about what you are going through, at any hour. Free.',
  ),
  CrisisContact(
    country: philippinesCountry,
    name: 'Emergency',
    number: '911',
    category: CrisisCategory.emergency,
    description:
        'Police, ambulance, and fire. Use this when a life is in danger right now. Open around the clock.',
  ),
  CrisisContact(
    country: philippinesCountry,
    name: 'NCMH Crisis Helpline',
    number: '1553',
    category: CrisisCategory.helpline,
    description:
        'National Center for Mental Health crisis helpline. Open around the clock. Toll-free from landlines. A mobile call can follow your carrier\'s rates.',
  ),
  CrisisContact(
    country: philippinesCountry,
    name: 'NCMH Crisis Helpline (Globe)',
    number: '0917-899-USAP',
    category: CrisisCategory.helpline,
    description:
        'The same NCMH crisis helpline for Globe and TM. Published as 0917-899-USAP. Open around the clock.',
  ),
  CrisisContact(
    country: philippinesCountry,
    name: 'NCMH Crisis Helpline (Smart)',
    number: '0919-057-1553',
    category: CrisisCategory.helpline,
    description:
        'The same NCMH crisis helpline for Smart and TNT. Open around the clock.',
  ),
  CrisisContact(
    country: germanyCountry,
    name: 'Notruf',
    number: '112',
    category: CrisisCategory.emergency,
    description:
        'Fire brigade and emergency medical help. Use this when a life is in danger right now. For the police, use 110. Open around the clock.',
  ),
  CrisisContact(
    country: germanyCountry,
    name: 'Polizei',
    number: '110',
    category: CrisisCategory.emergency,
    description:
        'Police. Use this when you need the police right now. For fire or an ambulance, use 112. Open around the clock.',
  ),
  CrisisContact(
    country: germanyCountry,
    name: 'TelefonSeelsorge',
    number: '0800 111 0 111',
    category: CrisisCategory.helpline,
    description:
        'Someone to talk with, anonymously, around the clock. Free from German networks. If the line is busy, 0800 111 0 222 is the same service.',
  ),
  CrisisContact(
    country: maltaCountry,
    name: 'Emergency',
    number: '112',
    category: CrisisCategory.emergency,
    description:
        'Police, ambulance, and fire. Use this when a life is in danger right now. Open around the clock.',
  ),
  CrisisContact(
    country: maltaCountry,
    name: 'Supportline',
    number: '179',
    category: CrisisCategory.helpline,
    description:
        'National helpline in Malta for people in distress. Open around the clock.',
  ),
  CrisisContact(
    country: internationalCountry,
    name: 'Local emergency services',
    number: '',
    category: CrisisCategory.guidance,
    description:
        'This list does not cover every country. If you are in immediate danger, contact the primary emergency service where you are. In many places that number is 112 or 911. If you do not know it, ask someone nearby. Do not wait if you or someone with you is in danger.',
  ),
];

/// Maps a device locale to a stored country id.
///
/// An unknown country code stays on International. German-speaking Austria,
/// for example, must not be shown the German police number.
String countryIdForDeviceLocale({
  String? countryCode,
  String languageCode = '',
}) {
  switch (countryCode?.toUpperCase()) {
    case 'SE':
      return regionSweden.id;
    case 'US':
      return regionUnitedStates.id;
    case 'GB':
    case 'UK':
      return regionUnitedKingdom.id;
    case 'PH':
      return regionPhilippines.id;
    case 'DE':
      return regionGermany.id;
    case 'MT':
      return regionMalta.id;
    case null:
    case '':
      break;
    default:
      return regionInternational.id;
  }

  switch (languageCode.toLowerCase()) {
    case 'sv':
      return regionSweden.id;
    case 'de':
      return regionGermany.id;
    case 'fil':
    case 'tl':
      return regionPhilippines.id;
    default:
      return regionInternational.id;
  }
}

CrisisRegion? crisisRegionById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final region in crisisRegions) {
    if (region.id == id) return region;
  }
  return null;
}

/// Stable id used for widget keys. Letters in a vanity number are converted
/// to the digits the dialer actually uses.
String crisisContactId(String countryId, CrisisContact contact) {
  final digits = dialableNumber(contact.number);
  final slug = digits.isEmpty ? 'guidance' : digits;
  return '$countryId-$slug';
}

List<CrisisContact> contactsForCountry(String countryId) {
  final region = crisisRegionById(countryId);
  if (region == null) return const [];
  return [
    for (final contact in crisisContacts)
      if (contact.country == region.label) contact,
  ];
}

/// In-memory filter. This never reads storage and never opens a connection.
List<CrisisContact> filterCrisisContacts({
  required String countryId,
  String query = '',
}) {
  final contacts = contactsForCountry(countryId);
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return contacts;

  final compactNeedle = needle.replaceAll(RegExp(r'[\s\-()]'), '');
  return [
    for (final contact in contacts)
      if (_matches(contact, needle, compactNeedle)) contact,
  ];
}

/// Emergency numbers and the international note stay visible while searching,
/// so a search cannot hide the number to call first.
List<CrisisContact> visibleCrisisContacts({
  required String countryId,
  String query = '',
}) {
  final all = contactsForCountry(countryId);
  final matching = filterCrisisContacts(countryId: countryId, query: query);
  final result = <CrisisContact>[];

  void add(CrisisContact contact) {
    if (!result.contains(contact)) result.add(contact);
  }

  for (final contact in all) {
    if (contact.category == CrisisCategory.emergency ||
        contact.category == CrisisCategory.guidance) {
      add(contact);
    }
  }
  for (final contact in matching) {
    if (contact.category == CrisisCategory.helpline) add(contact);
  }
  return List.unmodifiable(result);
}

bool _matches(CrisisContact contact, String needle, String compactNeedle) {
  final haystack = [
    contact.name,
    contact.number,
    contact.description,
    contact.category.name,
    contact.category.label,
    contact.smsOptional ?? '',
  ].join(' ').toLowerCase();
  if (haystack.contains(needle)) return true;
  if (compactNeedle.isEmpty) return false;

  final compactNumber = dialableNumber(contact.number);
  final compactDisplay =
      contact.number.toLowerCase().replaceAll(RegExp(r'[\s\-()]'), '');
  return compactNumber.contains(compactNeedle) ||
      compactDisplay.contains(compactNeedle);
}

/// Phone-keypad conversion so a published form such as USAP can be dialed.
String dialableNumber(String number) {
  const keypad = {
    'A': '2',
    'B': '2',
    'C': '2',
    'D': '3',
    'E': '3',
    'F': '3',
    'G': '4',
    'H': '4',
    'I': '4',
    'J': '5',
    'K': '5',
    'L': '5',
    'M': '6',
    'N': '6',
    'O': '6',
    'P': '7',
    'Q': '7',
    'R': '7',
    'S': '7',
    'T': '8',
    'U': '8',
    'V': '8',
    'W': '9',
    'X': '9',
    'Y': '9',
    'Z': '9',
  };

  final buffer = StringBuffer();
  for (final char in number.toUpperCase().split('')) {
    final mapped = keypad[char];
    if (mapped != null) {
      buffer.write(mapped);
      continue;
    }
    final isDigit = char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39;
    if (isDigit) {
      buffer.write(char);
    } else if (char == '+' && buffer.isEmpty) {
      buffer.write('+');
    }
  }
  return buffer.toString();
}
