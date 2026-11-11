import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monkeythrive/core/baseline/baseline_models.dart';
import 'package:monkeythrive/core/baseline/baseline_monitor.dart';
import 'package:monkeythrive/core/storage/session_tracker.dart';

class _Source implements BaselineDecisionSource {
  final NotificationDecision? decision;

  _Source(this.decision);

  @override
  Future<NotificationDecision?> shouldNotify() async => decision;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SessionActivity.activeCount.value = 0;
  });

  NotificationDecision decision(DateTime now, String id) {
    return NotificationDecision(
      sensorSnapshotId: id,
      modelConfidence: 0.91,
      baselineVersion: 1,
      shouldNotify: true,
      decidedAt: now,
    );
  }

  test('BaselineMonitor blocks quiet hours', () async {
    final monitor = BaselineMonitor(now: () => DateTime(2026, 1, 1, 23));

    expect(
      await monitor.shouldNotify(decision(DateTime(2026, 1, 1, 23), 'a')),
      false,
    );
  });

  test('BaselineMonitor blocks while a THRIVES session is active', () async {
    final now = DateTime(2026, 1, 1, 12);
    final monitor = BaselineMonitor(now: () => now);
    SessionActivity.begin();

    expect(await monitor.shouldNotify(decision(now, 'a')), false);
  });

  test('BaselineMonitor does not repeat a closed snapshot', () async {
    final now = DateTime(2026, 1, 1, 12);
    final monitor = BaselineMonitor(now: () => now);
    final first = decision(now, 'snapshot-1');

    expect(await monitor.submitDecision(first), true);
    await monitor.markPromptClosed('snapshot-1');

    expect(await monitor.submitDecision(first), false);
  });

  test('BaselineMonitor can evaluate a future shouldNotify source', () async {
    final now = DateTime(2026, 1, 1, 12);
    final monitor = BaselineMonitor(now: () => now);

    final shown = await monitor.evaluate(_Source(decision(now, 'source-1')));

    expect(shown, true);
  });

  test('BaselineMonitor can show a user-triggered prompt preview', () async {
    final now = DateTime(2026, 1, 1, 23);
    final monitor = BaselineMonitor(now: () => now);

    expect(
      await monitor.showManualPrompt(decision(now, 'manual')),
      true,
    );
    expect(
      await monitor.showManualPrompt(decision(now, 'manual-2')),
      false,
    );
  });
}
