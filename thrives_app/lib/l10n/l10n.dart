import 'package:flutter/widgets.dart';

import '../core/models/tolerance_state.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The reading the person already gave. English stays overwhelmed, present,
/// or flat or numb.
String toleranceLabel(AppLocalizations l10n, ToleranceState state) {
  switch (state) {
    case ToleranceState.hyperaroused:
      return l10n.stateOverwhelmed;
    case ToleranceState.regulated:
      return l10n.statePresent;
    case ToleranceState.hypoaroused:
      return l10n.stateFlat;
  }
}

String toleranceLock(AppLocalizations l10n, ToleranceState state) {
  switch (state) {
    case ToleranceState.hyperaroused:
      return l10n.lockedWhenOverwhelmed;
    case ToleranceState.regulated:
      return '';
    case ToleranceState.hypoaroused:
      return l10n.lockedWhenFlat;
  }
}

/// Short month names used in journal dates. [month] is 1–12.
String monthShort(AppLocalizations l10n, int month) {
  switch (month) {
    case 1:
      return l10n.monthJan;
    case 2:
      return l10n.monthFeb;
    case 3:
      return l10n.monthMar;
    case 4:
      return l10n.monthApr;
    case 5:
      return l10n.monthMay;
    case 6:
      return l10n.monthJun;
    case 7:
      return l10n.monthJul;
    case 8:
      return l10n.monthAug;
    case 9:
      return l10n.monthSep;
    case 10:
      return l10n.monthOct;
    case 11:
      return l10n.monthNov;
    case 12:
      return l10n.monthDec;
    default:
      return '';
  }
}

/// Same thresholds as the English rmssd label. That getter stays English.
String hrvRecoveryLabel(AppLocalizations l10n, double rmssd) {
  if (rmssd >= 40) return l10n.hrvGoodRecovery;
  if (rmssd >= 20) return l10n.hrvModerate;
  return l10n.hrvLow;
}

/// Session-log category ids stay English. This is the label on screen.
String categoryLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'Attune':
      return l10n.navAttune;
    case 'Monitor':
      return l10n.navMonitor;
    case 'Build':
      return l10n.navBuild;
    case 'Reflect':
      return l10n.navReflect;
    case 'Process':
      return l10n.navProcess;
    case 'General':
      return l10n.generalCategory;
    case 'Regulate':
      return l10n.navRegulate;
    default:
      return id;
  }
}

String _bandLabel(AppLocalizations l10n, String stored) {
  switch (stored) {
    case 'Delta':
      return l10n.bandDelta;
    case 'Theta':
      return l10n.bandTheta;
    case 'Alpha':
      return l10n.bandAlpha;
    case 'Beta':
      return l10n.bandBeta;
    default:
      return stored;
  }
}

String _noiseLabel(AppLocalizations l10n, String stored) {
  switch (stored) {
    case 'Rain':
      return l10n.noiseRain;
    case 'Ocean':
      return l10n.noiseOcean;
    case 'Forest':
      return l10n.noiseForest;
    case 'River':
      return l10n.noiseRiver;
    case 'Thunder':
      return l10n.noiseThunder;
    case 'Wind':
      return l10n.noiseWind;
    default:
      return stored;
  }
}

/// Session-log tool names stay English in storage. Display goes through here.
String toolTitle(AppLocalizations l10n, String stored) {
  switch (stored) {
    case 'Box Breathing':
      return l10n.boxBreathingTitle;
    case '4-7-8 Breathing':
      return l10n.breathing478Title;
    case 'Physiological Sigh':
      return l10n.sighTracked;
    case 'Physiological sigh':
      return l10n.sighTitle;
    case 'Wim Hof':
      return l10n.wimHofTracked;
    case 'Wim Hof Breathing':
      return l10n.wimHofTitle;
    case '5-4-3-2-1 Grounding':
      return l10n.groundingTitle;
    case 'Cold Water':
      return l10n.coldWaterTitle;
    case 'Safe Place':
      return l10n.safePlaceTitle;
    case 'Vagal Prompts':
      return l10n.vagalTitle;
    case 'Panic / Physiological Sigh':
      return l10n.panicTool;
    case 'Bilateral Stimulation':
      return l10n.bilateralTitle;
    case 'HRV Measurement':
      return l10n.hrvMeasurement;
    case 'Journaling':
      return l10n.journaling;
    case 'Humming':
      return l10n.humming;
    case 'Gargling':
      return l10n.gargling;
    case 'Extended Exhale':
      return l10n.extendedExhale;
    case 'Diving Reflex':
      return l10n.divingReflex;
    default:
      break;
  }
  const vagal = 'Vagal — ';
  const binaural = 'Binaural Beats — ';
  const isochronic = 'Isochronic Tones — ';
  const nature = 'Nature Sound — ';
  if (stored.startsWith(vagal)) {
    return l10n.vagalToolTitle(toolTitle(l10n, stored.substring(vagal.length)));
  }
  if (stored.startsWith(binaural)) {
    return l10n.binauralBeatsTitle(
      _bandLabel(l10n, stored.substring(binaural.length)),
    );
  }
  if (stored.startsWith(isochronic)) {
    return l10n.isochronicTonesTitle(
      _bandLabel(l10n, stored.substring(isochronic.length)),
    );
  }
  if (stored.startsWith(nature)) {
    return l10n.natureSoundTitle(
      _noiseLabel(l10n, stored.substring(nature.length)),
    );
  }
  return stored;
}
