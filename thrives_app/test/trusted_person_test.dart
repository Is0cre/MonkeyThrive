import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/data/crisis_dialer.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/models/trusted_person.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/storage/prefs_service.dart';
import 'package:monkeythrive/core/theme/app_theme.dart';
import 'package:monkeythrive/features/regulate/screens/panic_screen.dart';
import 'package:monkeythrive/features/settings/screens/crisis_directory_screen.dart';
import 'package:monkeythrive/features/support/trusted_people_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a saved person becomes a phone link and a text link', () {
    for (final message in TrustedPerson.suggestions) {
      expect(message.length, lessThanOrEqualTo(TrustedPerson.messageLimit));
    }

    expect(normalizeTrustedPhone('+1 (555) 123-4567'), '+15551234567');
    expect(normalizeTrustedPhone('0917-899-USAP'), '0917899');
    expect(normalizeTrustedPhone('https://example.com'), isNull);
    expect(normalizeTrustedPhone('123'), isNull);

    final person = TrustedPerson.tryMake(
      name: '  Sam   River  ',
      phone: '+1 (555) 123-4567',
      message: TrustedPerson.suggestions[0],
    );
    expect(person, isNotNull);
    expect(person!.name, 'Sam River');
    expect(person.phone, '+15551234567');
    validateCrisisUri(person.telUri);
    validateCrisisUri(person.smsUri);
    expect(person.telUri.toString(), 'tel:+15551234567');
    expect(
      person.smsUri.queryParameters['body'],
      TrustedPerson.suggestions[0],
    );

    expect(
      TrustedPerson.tryMake(
        name: 'Sam',
        phone: '+15551234567',
        message: 'x' * (TrustedPerson.messageLimit + 1),
      ),
      isNull,
    );
    expect(
      TrustedPerson.tryParse({
        'name': 'Sam',
        'phone': 'sms:12345',
        'message': 'Hello',
      }),
      isNull,
    );
  });

  test('storage keeps two people and drops a broken record', () async {
    final first = TrustedPerson.tryMake(
      name: 'Sam',
      phone: '5551234567',
      message: TrustedPerson.suggestions[0],
    )!;
    final second = TrustedPerson.tryMake(
      name: 'Noor',
      phone: '+46701234567',
      message: TrustedPerson.suggestions[1],
    )!;
    await PrefsService.saveTrustedPeople([first, second, first]);
    final stored = await PrefsService.loadTrustedPeople();
    expect(stored.map((person) => person.name), ['Sam', 'Noor']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsService.trustedPeopleKey, 'not-json');
    expect(await PrefsService.loadTrustedPeople(), isEmpty);
  });

  testWidgets('one tap opens the text link and does not ask again',
      (tester) async {
    final person = TrustedPerson.tryMake(
      name: 'Sam',
      phone: '+15551234567',
      message: TrustedPerson.suggestions[0],
    )!;
    await PrefsService.saveTrustedPeople([person]);
    final launched = <Uri>[];
    final dialer = CrisisDialer(launch: (uri) async {
      launched.add(uri);
      return true;
    });

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: CrisisDirectoryScreen(dialer: dialer),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trusted-closed')), findsNothing);
    expect(find.byKey(const Key('trusted-setup')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('trusted-text-0')));
    await tester.tap(find.byKey(const Key('trusted-text-0')));
    await tester.pumpAndSettle();

    expect(launched, [person.smsUri]);
    expect(find.byKey(const Key('crisis-confirm-number')), findsNothing);

    await tester.tap(find.byKey(const Key('trusted-call-0')));
    await tester.pumpAndSettle();
    expect(launched.last, person.telUri);
  });

  testWidgets('the form is open only when the reading is present',
      (tester) async {
    await tester.pumpWidget(
      WoTScope(
        notifier: ValueNotifier<ToleranceState?>(ToleranceState.hyperaroused),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const TrustedPeopleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trusted-screen-closed')), findsOneWidget);
    expect(find.byKey(const Key('trusted-name-0')), findsNothing);
    final closed =
        tester.widget<Text>(find.byKey(const Key('trusted-screen-closed')));
    expect(closed.style?.color, AppColors.textPrimary);

    final present = ValueNotifier<ToleranceState?>(ToleranceState.regulated);
    await tester.pumpWidget(
      WoTScope(
        notifier: present,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const TrustedPeopleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trusted-name-0')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('trusted-name-0')), 'Sam');
    await tester.enterText(
      find.byKey(const Key('trusted-phone-0')),
      '+1 (555) 123-4567',
    );
    await tester.ensureVisible(find.byKey(const Key('trusted-suggestion-0-1')));
    await tester.tap(find.byKey(const Key('trusted-suggestion-0-1')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('trusted-save-0')));
    await tester.tap(find.byKey(const Key('trusted-save-0')));
    await tester.pumpAndSettle();

    final saved = await PrefsService.loadTrustedPeople();
    expect(saved.single.name, 'Sam');
    expect(saved.single.phone, '+15551234567');
    expect(saved.single.message, TrustedPerson.suggestions[1]);
    validateCrisisUri(saved.single.smsUri);
  });

  testWidgets('anchor keeps the shortcut off until the sighs finish',
      (tester) async {
    final person = TrustedPerson.tryMake(
      name: 'Sam',
      phone: '+15551234567',
      message: TrustedPerson.suggestions[0],
    )!;
    await PrefsService.saveTrustedPeople([person]);

    await tester.pumpWidget(const MaterialApp(home: PanicScreen()));
    await tester.pump();
    expect(find.text('Text Sam'), findsNothing);
    expect(find.text('go to regulate'), findsNothing);

    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.pump();
    await tester.pump();

    expect(find.text('Text Sam'), findsOneWidget);
    expect(find.text('go to regulate'), findsOneWidget);
    expect(find.byKey(const Key('trusted-setup')), findsNothing);
  });
}
