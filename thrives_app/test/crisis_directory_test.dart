import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/data/crisis_dialer.dart';
import 'package:monkeythrive/core/data/crisis_helplines.dart';
import 'package:monkeythrive/core/storage/prefs_service.dart';
import 'package:monkeythrive/core/theme/app_theme.dart';
import 'package:monkeythrive/features/settings/screens/crisis_directory_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _NoNetworkHttpOverrides guard;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    guard = _NoNetworkHttpOverrides();
    HttpOverrides.global = guard;
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  test('country filter returns only that country and stays local', () {
    final sweden = filterCrisisContacts(countryId: 'se');
    expect(
      sweden.map((contact) => contact.number),
      ['112', '90101', '116 123', '1177'],
    );
    expect(
      sweden.map((contact) => contact.name),
      contains('Mind Självmordslinjen'),
    );
    expect(
      sweden.any((contact) => contact.country == regionUnitedStates.label),
      isFalse,
    );

    final unitedStates = filterCrisisContacts(countryId: 'us');
    expect(
      unitedStates.map((contact) => contact.number),
      ['911', '988', '741741'],
    );
    expect(
      unitedStates.any((contact) => contact.name == 'Mind Självmordslinjen'),
      isFalse,
    );

    final byCompactNumber = filterCrisisContacts(
      countryId: 'se',
      query: '116123',
    );
    expect(byCompactNumber.single.name, 'Kvinnofridslinjen');

    final samaritans = filterCrisisContacts(
      countryId: 'gb',
      query: 'samar',
    );
    expect(samaritans.single.name, 'Samaritans');

    final whileSearching = visibleCrisisContacts(
      countryId: 'gb',
      query: 'samar',
    );
    expect(
      whileSearching.map((contact) => contact.name),
      ['Emergency', 'Samaritans'],
    );
    expect(guard.createdClients, 0);
  });

  test('seeded links are phone or text links and network URLs are refused', () {
    expect(
      contactsForCountry('de').map((contact) => contact.number),
      ['112', '110', '0800 111 0 111'],
    );
    expect(
      contactsForCountry('ph').map((contact) => contact.number),
      ['911', '1553', '0917-899-USAP', '0919-057-1553'],
    );
    expect(
      contactsForCountry('mt').map((contact) => contact.number),
      ['112', '179'],
    );

    final globe = contactsForCountry('ph')
        .singleWhere((contact) => contact.number.contains('USAP'));
    expect(globe.telUri.toString(), 'tel:09178998727');
    expect(globe.smsUri, isNull);

    final textLine = contactsForCountry('us')
        .singleWhere((contact) => contact.smsOptional != null);
    expect(textLine.smsOptional, 'HOME');
    expect(textLine.telUri, isNull);
    expect(textLine.smsUri.toString(), 'sms:741741?body=HOME');

    final international = contactsForCountry('intl').single;
    expect(international.category, CrisisCategory.guidance);
    expect(international.number, isEmpty);
    expect(international.telUri, isNull);
    expect(international.smsUri, isNull);
    expect(international.description, contains('primary emergency'));

    for (final contact in crisisContacts) {
      for (final uri in [contact.telUri, contact.smsUri]) {
        if (uri == null) continue;
        expect(uri.scheme, isIn(['tel', 'sms']));
        expect(uri.hasAuthority, isFalse);
        expect(uri.toString(), isNot(contains('http')));
        validateCrisisUri(uri);
      }
    }

    expect(
      () => const CrisisDialer().open(Uri.parse('https://example.com')),
      throwsArgumentError,
    );
    expect(
      () => const CrisisDialer().open(Uri.parse('tel://carrier.example/112')),
      throwsArgumentError,
    );
    expect(guard.createdClients, 0);
  });

  test('device locale picks a known country and does not guess neighbours', () {
    expect(
      countryIdForDeviceLocale(countryCode: 'SE', languageCode: 'sv'),
      'se',
    );
    expect(
      countryIdForDeviceLocale(countryCode: 'US', languageCode: 'en'),
      'us',
    );
    expect(
      countryIdForDeviceLocale(countryCode: 'GB', languageCode: 'en'),
      'gb',
    );
    expect(
      countryIdForDeviceLocale(countryCode: 'PH', languageCode: 'fil'),
      'ph',
    );
    expect(
      countryIdForDeviceLocale(countryCode: 'DE', languageCode: 'de'),
      'de',
    );
    expect(
      countryIdForDeviceLocale(countryCode: 'IN', languageCode: 'hi'),
      'in',
    );
    expect(countryIdForDeviceLocale(languageCode: 'sv'), 'se');
    expect(
      countryIdForDeviceLocale(countryCode: 'AT', languageCode: 'de'),
      'intl',
    );
    expect(countryIdForDeviceLocale(languageCode: 'en'), 'intl');
  });

  testWidgets(
    'country selection filters contacts and makes no network calls',
    (tester) async {
      final launched = <Uri>[];
      final dialer = CrisisDialer(launch: (uri) async {
        launched.add(uri);
        return true;
      });

      await PrefsService.saveCrisisCountry('se');
      await _pumpDirectory(tester, dialer: dialer);

      expect(find.text(crisisDirectoryDisclaimer), findsOneWidget);
      expect(find.text('Mind Självmordslinjen'), findsOneWidget);
      expect(find.text('Akut nöd'), findsOneWidget);
      expect(find.text('Suicide & Crisis Lifeline'), findsNothing);
      expect(find.text('Samaritans'), findsNothing);
      expect(find.text('TelefonSeelsorge'), findsNothing);
      expect(find.text('NCMH Crisis Helpline'), findsNothing);

      expect(
        find.descendant(
          of: find.byKey(const Key('crisis-card-se-112')),
          matching: find.text('EMERGENCY'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('crisis-card-se-90101')),
          matching: find.text('EMERGENCY'),
        ),
        findsNothing,
      );

      await tester.enterText(find.byKey(const Key('crisis-search')), 'kvinno');
      await tester.pump();
      expect(find.text('Kvinnofridslinjen'), findsOneWidget);
      expect(find.text('Sjukvårdsrådgivning'), findsNothing);
      expect(find.text('Akut nöd'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('crisis-search')), '');
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('crisis-call-se-112')));
      await tester.tap(find.byKey(const Key('crisis-call-se-112')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('crisis-confirm-number')))
            .data,
        '112',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(launched, isEmpty);

      await tester.tap(find.byKey(const Key('crisis-call-se-112')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Call 112'));
      await tester.pumpAndSettle();

      expect(launched.single.toString(), 'tel:112');
      expect(launched.single.scheme, 'tel');
      expect(launched.single.hasAuthority, isFalse);

      await tester.tap(find.byKey(const Key('crisis-country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('United States').last);
      await tester.pumpAndSettle();

      expect(find.text('Suicide & Crisis Lifeline'), findsOneWidget);
      expect(find.text('Crisis Text Line'), findsOneWidget);
      expect(find.text('Mind Självmordslinjen'), findsNothing);
      expect(find.text('Akut nöd'), findsNothing);
      expect(await PrefsService.loadCrisisCountry(), 'us');

      await tester.enterText(find.byKey(const Key('crisis-search')), '741741');
      await tester.pump();
      expect(find.text('Crisis Text Line'), findsOneWidget);
      expect(find.text('Suicide & Crisis Lifeline'), findsNothing);

      await tester
          .ensureVisible(find.byKey(const Key('crisis-text-us-741741')));
      await tester.tap(find.byKey(const Key('crisis-text-us-741741')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('crisis-confirm-number')))
            .data,
        '741741',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('crisis-confirm-message')))
            .data,
        'HOME',
      );
      await tester.tap(find.text('Text 741741'));
      await tester.pumpAndSettle();

      expect(launched.map((uri) => uri.toString()), [
        'tel:112',
        'sms:741741?body=HOME',
      ]);
      expect(launched.every((uri) => !uri.hasAuthority), isTrue);
      expect(launched.every((uri) => !uri.toString().contains('http')), isTrue);
      expect(
        guard.createdClients,
        0,
        reason: 'crisis directory must not open a network client',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const CrisisDirectoryScreen(key: Key('reopened')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Suicide & Crisis Lifeline'), findsOneWidget);
      expect(find.text('Mind Självmordslinjen'), findsNothing);
      expect(guard.createdClients, 0);
    },
  );

  testWidgets('a stored value that is not a country id is ignored',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'crisis_directory_country': 'https://nope.example',
    });
    await _pumpDirectory(tester);

    expect(find.text('Mind Självmordslinjen'), findsOneWidget);
    expect(find.text('https://nope.example'), findsNothing);
    expect(guard.createdClients, 0);
  });
}

Future<void> _pumpDirectory(
  WidgetTester tester, {
  CrisisDialer? dialer,
}) async {
  tester.platformDispatcher.localeTestValue = const Locale('sv', 'SE');
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: CrisisDirectoryScreen(dialer: dialer),
    ),
  );
  await tester.pumpAndSettle();
}

class _NoNetworkHttpOverrides extends HttpOverrides {
  int createdClients = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    createdClients += 1;
    throw StateError('Crisis directory must not open a network connection.');
  }
}
