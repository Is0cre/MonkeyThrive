import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/storage/journal_service.dart';
import 'package:monkeythrive/core/storage/portable_archive.dart';
import 'package:monkeythrive/core/storage/vault_secret_box.dart';
import 'package:monkeythrive/core/storage/vault_service.dart';
import 'package:monkeythrive/features/reflect/screens/reflect_home_screen.dart';
import 'package:monkeythrive/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VaultService.instance.debugReset(MemoryVaultSecretBox());
  });

  tearDown(() {
    VaultService.instance.lock();
  });

  test('a wrong key stays shut and the right key opens the journal', () async {
    final vault = VaultService.instance;
    expect(await vault.createPin('123456'), isTrue);
    vault.lock();

    expect(await vault.unlock('000000'), isFalse);
    expect(vault.isUnlocked, isFalse);

    final sealed = await vault.encryptJournalText('secret journal', '123456');
    expect(sealed.startsWith(VaultService.textPrefix), isTrue);
    expect(sealed.contains('secret journal'), isFalse);
    expect(await vault.decryptJournalText(sealed, '123456'), 'secret journal');
    await expectLater(
      vault.decryptJournalText(sealed, '000000'),
      throwsFormatException,
    );

    expect(await vault.unlock('123456'), isTrue);
    final cached = vault.encryptText('secret journal');
    expect(cached.contains('secret journal'), isFalse);
    expect(vault.decryptText(cached), 'secret journal');
    vault.lock();
    expect(
        () => vault.decryptText(cached), throwsA(isA<VaultLockedException>()));
  });

  test('plaintext journal is sealed after the key is created', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': jsonEncode([
        {
          'id': '1',
          'timestamp': '2026-01-01T00:00:00.000Z',
          'body': 'secret journal',
        },
      ]),
    });
    final vault = VaultService.instance;
    expect(await vault.createPin('123456'), isTrue);
    await JournalService.resealAll();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('journal_entries')!;
    expect(stored.contains('secret journal'), isFalse);
    expect(stored.contains(VaultService.textPrefix), isTrue);

    vault.lock();
    await expectLater(
      JournalService.load(),
      throwsA(isA<VaultLockedException>()),
    );
    expect(await vault.unlock('123456'), isTrue);
    final entries = await JournalService.load();
    expect(entries.single.body, 'secret journal');
  });

  test('five minutes in the background locks, four does not', () async {
    var clock = DateTime(2026, 1, 1, 12);
    VaultService.instance.debugReset(
      MemoryVaultSecretBox(),
      now: () => clock,
    );
    final vault = VaultService.instance;
    expect(await vault.createPin('123456'), isTrue);

    vault.onBackgrounded();
    clock = clock.add(const Duration(minutes: 4));
    vault.onResumed();
    expect(vault.isUnlocked, isTrue);

    vault.onBackgrounded();
    clock = clock.add(const Duration(minutes: 5));
    vault.onResumed();
    expect(vault.isUnlocked, isFalse);
    await expectLater(
      JournalService.load(),
      throwsA(isA<VaultLockedException>()),
    );
  });

  testWidgets('five minutes without a touch locks the vault', (tester) async {
    var clock = DateTime(2026, 1, 1, 12);
    VaultService.instance.debugReset(
      MemoryVaultSecretBox(),
      now: () => clock,
    );
    expect(await VaultService.instance.createPin('123456'), isTrue);

    clock = clock.add(const Duration(minutes: 4));
    await tester.pump(const Duration(minutes: 4));
    expect(VaultService.instance.isUnlocked, isTrue);

    clock = clock.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(VaultService.instance.isUnlocked, isFalse);
  });

  test('five wrong keys wait thirty seconds', () async {
    var clock = DateTime(2026, 1, 1, 12);
    VaultService.instance.debugReset(
      MemoryVaultSecretBox(),
      now: () => clock,
    );
    final vault = VaultService.instance;
    expect(await vault.createPin('123456'), isTrue);
    vault.lock();
    for (var i = 0; i < 5; i++) {
      expect(await vault.unlock('000000'), isFalse);
    }
    expect(await vault.unlock('123456'), isFalse);
    clock = clock.add(const Duration(seconds: 30));
    expect(await vault.unlock('123456'), isTrue);
  });

  test('clearing the vault drops the key and tells listeners', () async {
    final vault = VaultService.instance;
    expect(await vault.createPin('123456'), isTrue);
    vault.lock();
    var heard = 0;
    void listener() => heard += 1;
    vault.addListener(listener);
    await vault.wipe();
    vault.removeListener(listener);
    expect(heard, greaterThan(0));
    expect(vault.isProtected, isFalse);
    expect(await vault.unlock('123456'), isFalse);
  });

  test('a locked vault does not export the journal', () async {
    final vault = VaultService.instance;
    expect(await vault.createPin('123456'), isTrue);
    await JournalService.save(
      JournalEntry(
        id: '1',
        timestamp: DateTime.utc(2026, 1, 1),
        body: 'secret journal',
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getString('journal_entries'), isNot(contains('secret journal')));

    final token = await PortableArchive.exportSealed(
      'correct horse',
      iterations: 1000,
    );
    expect(token.contains('secret journal'), isFalse);

    vault.lock();
    await expectLater(
      PortableArchive.exportSealed('correct horse', iterations: 1000),
      throwsA(isA<VaultLockedException>()),
    );
    await expectLater(
      PortableArchive.importSealed(token, 'correct horse'),
      throwsA(isA<VaultLockedException>()),
    );

    expect(await vault.unlock('123456'), isTrue);
    await prefs.remove('journal_entries');
    await PortableArchive.importSealed(token, 'correct horse');
    final stored = prefs.getString('journal_entries')!;
    expect(stored.contains('secret journal'), isFalse);
    expect(stored.contains(VaultService.textPrefix), isTrue);
    expect((await JournalService.load()).single.body, 'secret journal');
  });

  testWidgets('Reflect stays shut until the key is entered twice',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReflectHomeScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Choose a 6-digit key for Reflect.'), findsOneWidget);
    expect(find.textContaining('a record of what'), findsNothing);

    await _tapPin(tester, '12345');
    await tester.tap(find.byKey(const Key('vault-ok')));
    await tester.pump();
    expect(find.text('Use 6 digits.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('vault-digit-6')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('vault-ok')));
    await tester.pump();
    expect(find.text('Enter the same key again.'), findsOneWidget);

    await _tapPin(tester, '123457');
    await tester.tap(find.byKey(const Key('vault-ok')));
    await tester.pump();
    expect(find.text('Those keys did not match.'), findsOneWidget);
    expect(find.text('Choose a 6-digit key for Reflect.'), findsOneWidget);

    await _tapPin(tester, '123456');
    await tester.tap(find.byKey(const Key('vault-ok')));
    await tester.pump();
    await _tapPin(tester, '123456');
    await tester.tap(find.byKey(const Key('vault-ok')));
    await tester.pumpAndSettle();

    expect(find.textContaining('a record of what'), findsOneWidget);
    expect(find.text('Choose a 6-digit key for Reflect.'), findsNothing);
    VaultService.instance.lock();
  });
}

Future<void> _tapPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('vault-digit-$digit')));
    await tester.pump();
  }
}
