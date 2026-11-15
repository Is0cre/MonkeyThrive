import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/storage/prefs_service.dart';
import 'package:monkeythrive/features/attune/expansions/expansion_archive_pick.dart';
import 'package:monkeythrive/features/attune/expansions/expansion_pack_service.dart';
import 'package:monkeythrive/features/attune/screens/attune_home_screen.dart';
import 'package:monkeythrive/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a saved zip can be chosen and another zip can be added',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      PrefsService.attuneIntroKey: true,
      PrefsService.attuneWaiverKey: true,
    });
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final root = Directory.systemTemp.createTempSync('mt-pack-pick');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final packs = ExpansionPackService(rootPath: root.path);
    await tester.runAsync(() => packs.installArchive(
          _zip({
            'manifest.json': utf8.encode(jsonEncode([
              {
                'file': '05_satie_gymnopedie_1.ogg',
                'composer': 'Erik Satie',
                'title': 'Gymnopédie No. 1',
                'key': 'A',
                'bpm': 0,
              },
            ])),
            '05_satie_gymnopedie_1.ogg': <int>[1, 2, 3, 4],
          }),
          packName: 'satie_expansion',
        ));

    var picks = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AttuneHomeScreen(
          packs: packs,
          pickArchive: () async {
            picks += 1;
            if (picks == 1) {
              return const ExpansionArchivePick(
                name: 'My Pack.zip',
                bytes: [1],
              );
            }
            return ExpansionArchivePick(
              name: 'beethoven_expansion.zip',
              bytes: _zip({
                'manifest.json': utf8.encode(jsonEncode([
                  {
                    'file': '08_beethoven_op132_mvt1.ogg',
                    'composer': 'Ludwig van Beethoven',
                    'title': 'String Quartet No. 15',
                    'movement': '1',
                    'key': '',
                    'bpm': 0,
                  },
                ])),
                '08_beethoven_op132_mvt1.ogg': <int>[9],
              }),
            );
          },
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Binaural'), findsOneWidget);
    await tester.tap(find.text('Binaural'));
    await tester.pump();
    expect(find.text('Vivaldi, Spring'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('attune-mask-pick')));
    await tester.tap(find.byKey(const Key('attune-mask-pick')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('INCLUDED'), findsOneWidget);
    expect(find.text('ERIK SATIE'), findsOneWidget);
    expect(find.text('Erik Satie, Gymnopédie No. 1'), findsOneWidget);
    await tester.tap(find.text('Erik Satie, Gymnopédie No. 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Erik Satie, Gymnopédie No. 1'), findsOneWidget);
    expect(find.text('This recording stays on this device.'), findsOneWidget);
    expect(find.text('220.0 Hz'), findsOneWidget);
    expect(find.textContaining('Modena Chamber Orchestra'), findsNothing);

    await tester.tap(find.byKey(const Key('attune-mask-pick')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('attune-add-pack')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Name the zip with letters and numbers, then try again.'),
      findsOneWidget,
    );
    expect(
      find.text('Ludwig van Beethoven, String Quartet No. 15 · 1'),
      findsNothing,
    );
    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('attune-add-pack'))),
    ).removeCurrentSnackBar();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.byKey(const Key('attune-add-pack')));
    await tester.tap(find.byKey(const Key('attune-add-pack')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 track added on this device'), findsOneWidget);
    expect(
      find.text('Ludwig van Beethoven, String Quartet No. 15 · 1'),
      findsOneWidget,
    );
    await tester.tap(
      find.text('Ludwig van Beethoven, String Quartet No. 15 · 1'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('220.0 Hz'), findsOneWidget);
    expect(
      find.text('Ludwig van Beethoven, String Quartet No. 15 · 1'),
      findsOneWidget,
    );

    final stored = await tester.runAsync(() => packs.loadTracks());
    expect(
      stored!.where((track) => track.packName == 'beethoven_expansion'),
      hasLength(1),
    );
  });
}

List<int> _zip(Map<String, List<int>> files) {
  final archive = Archive();
  for (final item in files.entries) {
    archive.addFile(ArchiveFile(item.key, item.value.length, item.value));
  }
  return ZipEncoder().encode(archive);
}
