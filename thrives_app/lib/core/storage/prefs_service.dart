import 'package:shared_preferences/shared_preferences.dart';
import '../models/tolerance_state.dart';

/// Central access point for all SharedPreferences keys.
/// Nothing stored here leaves the device.
class PrefsService {
  PrefsService._();

  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyWotState = 'wot_state';
  static const _keyWotDate =
      'wot_date'; // yyyy-MM-dd — resets check-in each day
  static const _keyPrimaryGoal = 'profile_primary_goal';
  static const _keyFamiliarity = 'profile_familiarity';
  static const _keyHasWearable = 'profile_has_wearable';
  static const _keyWorkStyle = 'profile_work_style';
  static const _keyReduceMotion = 'profile_reduce_motion';
  static const _keyReduceAudio = 'profile_reduce_audio';
  static const _keyReduceVibration = 'profile_reduce_vibration';
  static const _keyHasTherapist = 'profile_has_therapist';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, false);
  }

  static Future<void> saveProfile({
    required String primaryGoal,
    required String familiarity,
    required bool hasWearable,
    required String workStyle,
    required bool reduceMotion,
    required bool reduceAudio,
    required bool reduceVibration,
    required String hasTherapist,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrimaryGoal, primaryGoal);
    await prefs.setString(_keyFamiliarity, familiarity);
    await prefs.setBool(_keyHasWearable, hasWearable);
    await prefs.setString(_keyWorkStyle, workStyle);
    await prefs.setBool(_keyReduceMotion, reduceMotion);
    await prefs.setBool(_keyReduceAudio, reduceAudio);
    await prefs.setBool(_keyReduceVibration, reduceVibration);
    await prefs.setString(_keyHasTherapist, hasTherapist);
  }

  // --- Window of Tolerance state ---

  /// Returns today's check-in state, or null if no check-in recorded today.
  /// Resets at midnight — a new day requires a new check-in.
  static Future<ToleranceState?> loadTodaysWotState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyWotDate);
    if (savedDate != _todayKey()) return null;
    final val = prefs.getString(_keyWotState);
    if (val == null) return null;
    return ToleranceState.values.where((s) => s.name == val).firstOrNull;
  }

  static Future<void> saveWotState(ToleranceState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWotState, state.name);
    await prefs.setString(_keyWotDate, _todayKey());
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<Map<String, dynamic>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'primaryGoal': prefs.getString(_keyPrimaryGoal) ?? '',
      'familiarity': prefs.getString(_keyFamiliarity) ?? '',
      'hasWearable': prefs.getBool(_keyHasWearable) ?? false,
      'workStyle': prefs.getString(_keyWorkStyle) ?? '',
      'reduceMotion': prefs.getBool(_keyReduceMotion) ?? false,
      'reduceAudio': prefs.getBool(_keyReduceAudio) ?? false,
      'reduceVibration': prefs.getBool(_keyReduceVibration) ?? false,
      'hasTherapist': prefs.getString(_keyHasTherapist) ?? '',
    };
  }
}
