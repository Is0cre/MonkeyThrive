import '../../core/models/tolerance_state.dart';

// CLINICAL SAFETY — Somatic map routing
// What this does: Turns marks on the body into one Window of Tolerance state.
// Why it exists: The check-in still has to choose a state before tools unlock.
//   Tightness in the head, throat, chest, or stomach is treated as overwhelmed.
//   Heaviness is treated as flat or numb. An unmarked body is not treated as
//   present. Silence is not the same as being able to make choices.
// What happens if removed or modified: An empty map could unlock processing
//   tools, or a mixed signal could be labelled present.
// Informed by: Ogden, sensorimotor psychotherapy / Siegel, Window of Tolerance.
//   The person sees the reading and continues only after it is on screen.
//   This is not a diagnosis.

enum SomaticZone { head, throat, chest, stomach }

enum SomaticQuality { unmarked, tight, heavy }

/// Zones the check-in can mark. Missing zones count as unmarked.
ToleranceState? stateFromBodyMap(Map<SomaticZone, SomaticQuality> marks) {
  final tight = <SomaticZone>{};
  final heavy = <SomaticZone>{};
  for (final zone in SomaticZone.values) {
    switch (marks[zone] ?? SomaticQuality.unmarked) {
      case SomaticQuality.tight:
        tight.add(zone);
      case SomaticQuality.heavy:
        heavy.add(zone);
      case SomaticQuality.unmarked:
        break;
    }
  }

  if (tight.isEmpty && heavy.isEmpty) return null;

  // Both patterns lock the same processing tools. The label still has to be
  // one state. A tie stays with charge, which is the louder signal.
  if (tight.isNotEmpty && heavy.length > tight.length) {
    return ToleranceState.hypoaroused;
  }
  if (tight.isNotEmpty) return ToleranceState.hyperaroused;
  return ToleranceState.hypoaroused;
}

SomaticQuality nextQuality(SomaticQuality current) {
  switch (current) {
    case SomaticQuality.unmarked:
      return SomaticQuality.tight;
    case SomaticQuality.tight:
      return SomaticQuality.heavy;
    case SomaticQuality.heavy:
      return SomaticQuality.unmarked;
  }
}
