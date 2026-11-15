import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Listening time for Attune on this device, for the local calendar day.
///
/// The count lives in SharedPreferences. It is not part of the portable
/// archive, so a restore cannot wipe today's time or import another
/// device's time. Hive is not used.
class AttuneDosage {
  AttuneDosage({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static final AttuneDosage instance = AttuneDosage();

  /// Local day stamp, `yyyy-MM-dd`.
  static const dayKey = 'attune_dosage_day';

  /// Whole seconds listened on [dayKey].
  static const secondsKey = 'attune_dosage_seconds';

  /// Named on the player. Four seasons together are about 43 minutes.
  static const recommendedMinutes = 45;

  /// Starting another session after this asks the person to continue or stop.
  static const softLimitMinutes = 45;

  static const softLimitSeconds = softLimitMinutes * 60;

  /// How often an open session writes, so a closed app keeps most of the time.
  static const checkpointEvery = Duration(seconds: 15);

  final DateTime Function() _now;

  DateTime? _openSince;
  Future<void> _writes = Future<void>.value();

  static String stamp(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  /// True once today's listening is past [softLimitMinutes].
  static bool needsWarning(int listenedSeconds) =>
      listenedSeconds > softLimitSeconds;

  /// Stored seconds for the local day, plus an open session that is not
  /// written yet.
  Future<int> todaySeconds([DateTime? at]) async {
    final clock = at ?? _now();
    final prefs = await SharedPreferences.getInstance();
    final stored = _storedSeconds(prefs, clock);
    final open = _openSince;
    if (open == null) return stored;
    final extra = clock.difference(open).inSeconds;
    if (extra <= 0) return stored;
    return stored + extra;
  }

  /// Opens the interval. A second call while one is open does not move it.
  void begin([DateTime? at]) {
    _openSince ??= at ?? _now();
  }

  /// Writes elapsed time once [due] has passed, and keeps the interval open.
  Future<void> checkpointIfDue({Duration due = checkpointEvery}) async {
    final started = _openSince;
    if (started == null) return;
    final clock = _now();
    if (clock.difference(started) < due) return;
    await _writeElapsed(close: false, at: clock);
  }

  /// Writes elapsed time and closes the interval.
  Future<void> end([DateTime? at]) => _writeElapsed(close: true, at: at);

  Future<void> _writeElapsed({required bool close, DateTime? at}) {
    final run = _writes.then((_) => _writeElapsedNow(close: close, at: at));
    _writes = run.catchError((Object _) {});
    return run;
  }

  Future<void> _writeElapsedNow({required bool close, DateTime? at}) async {
    final started = _openSince;
    if (started == null) return;
    final clock = at ?? _now();
    var seconds = clock.difference(started).inSeconds;
    if (seconds < 0) seconds = 0;
    if (seconds == 0) {
      if (close) _openSince = null;
      return;
    }
    _openSince = close ? null : clock;
    final prefs = await SharedPreferences.getInstance();
    final today = stamp(clock);
    final prior = _storedSeconds(prefs, clock);
    await prefs.setString(dayKey, today);
    await prefs.setInt(secondsKey, prior + seconds);
  }

  int _storedSeconds(SharedPreferences prefs, DateTime clock) {
    if (prefs.getString(dayKey) != stamp(clock)) return 0;
    return prefs.getInt(secondsKey) ?? 0;
  }
}

/// Asks before another session once today's listening is past 45 minutes.
///
/// Returns true only when the person chooses to continue.
Future<bool> confirmAttunePastDailyLimit(BuildContext context) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          dialogContext.l10n.attuneDosageOverTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          dialogContext.l10n.attuneDosageOverBody,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              dialogContext.l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            key: const Key('attune-dosage-continue'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              dialogContext.l10n.attuneDosageContinue,
              style: const TextStyle(color: AppColors.amber),
            ),
          ),
        ],
      );
    },
  );
  return proceed == true;
}
