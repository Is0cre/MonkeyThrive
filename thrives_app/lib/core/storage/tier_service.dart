import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_log.dart';

/// Tracks which feature tiers the user has unlocked through consistent practice.
///
/// Clinical rationale: trauma regulation tools exist on a readiness continuum.
/// Reflective tools (journaling, WoT history) require a stabilisation foundation.
/// Bilateral stimulation requires demonstrated reflective capacity.
/// Tiers unlock ambientally — no announcements, no progress bars, no congratulations.
/// Once unlocked, a tier never regresses.
///
/// Tier 1 — Regulate + Attune — always available
/// Tier 2 — Monitor, Build, Reflect — unlocks after ≥3 completed Regulate sessions
/// Tier 3 — Process — unlocks after ≥3 Build (journaling) sessions
///           OR ≥5 WoT tolerance check-ins (demonstrates engagement with self-monitoring)
class TierStatus {
  final bool tier2; // Monitor, Build, Reflect
  final bool tier3; // Process (bilateral stimulation)

  const TierStatus({required this.tier2, required this.tier3});

  @override
  bool operator ==(Object other) =>
      other is TierStatus && other.tier2 == tier2 && other.tier3 == tier3;

  @override
  int get hashCode => Object.hash(tier2, tier3);
}

class TierService {
  TierService._();

  static final notifier =
      ValueNotifier<TierStatus>(const TierStatus(tier2: false, tier3: false));

  static const _keyTier2 = 'tier2_unlocked';
  static const _keyTier3 = 'tier3_unlocked';

  // Minimum sessions to unlock each tier — kept deliberately low so the
  // progression feels earned but not punishing.
  static const _tier2RegulateThreshold = 3;
  static const _tier3JournalingThreshold = 3;
  static const _tier3WotThreshold = 5;

  /// Call once at app startup. Loads cached flags and recomputes any that are
  /// still false. Returns the current status and updates [notifier].
  static Future<TierStatus> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedT2 = prefs.getBool(_keyTier2) ?? false;
    final cachedT3 = prefs.getBool(_keyTier3) ?? false;

    // Short-circuit if already fully unlocked
    if (cachedT2 && cachedT3) {
      notifier.value = const TierStatus(tier2: true, tier3: true);
      return notifier.value;
    }

    final computed = await _compute(existingT2: cachedT2, existingT3: cachedT3);
    if (computed != TierStatus(tier2: cachedT2, tier3: cachedT3)) {
      await _persist(computed, prefs);
    }
    notifier.value = computed;
    return computed;
  }

  /// Recompute and update notifier. Called after each session log write so the
  /// shell reacts without the user needing to restart the app.
  static Future<void> recheck() async {
    final current = notifier.value;
    if (current.tier2 && current.tier3) return; // nothing left to unlock

    final prefs = await SharedPreferences.getInstance();
    final computed =
        await _compute(existingT2: current.tier2, existingT3: current.tier3);
    if (computed != current) {
      await _persist(computed, prefs);
      notifier.value = computed;
    }
  }

  // ── Computation ─────────────────────────────────────────────────────────────

  static Future<TierStatus> _compute({
    required bool existingT2,
    required bool existingT3,
  }) async {
    bool t2 = existingT2;
    bool t3 = existingT3;

    // Tier 2: count completed Regulate-category sessions (Attune also counts —
    // ambient sound is a legitimate stabilisation practice).
    if (!t2) {
      final sessions = await SessionLog.getSessionLog();
      final count = sessions
          .where((s) => s.category == 'Regulate' || s.category == 'Attune')
          .length;
      t2 = count >= _tier2RegulateThreshold;
    }

    // Tier 3 requires tier 2 as a prerequisite.
    if (t2 && !t3) {
      final sessions = await SessionLog.getSessionLog();
      final journalSessions =
          sessions.where((s) => s.category == 'Build').length;

      if (journalSessions >= _tier3JournalingThreshold) {
        t3 = true;
      } else {
        // Alternatively: enough WoT check-ins demonstrates self-monitoring
        final toleranceEntries = await SessionLog.getToleranceLog();
        t3 = toleranceEntries.length >= _tier3WotThreshold;
      }
    }

    return TierStatus(tier2: t2, tier3: t3);
  }

  static Future<void> _persist(
      TierStatus status, SharedPreferences prefs) async {
    await prefs.setBool(_keyTier2, status.tier2);
    await prefs.setBool(_keyTier3, status.tier3);
  }
}
