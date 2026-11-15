import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my')
  ];

  /// The app name. Keep this word unchanged in every language.
  ///
  /// In en, this message translates to:
  /// **'MonkeyThrive'**
  String get appTitle;

  /// No description provided for @navRegulate.
  ///
  /// In en, this message translates to:
  /// **'Regulate'**
  String get navRegulate;

  /// No description provided for @navAttune.
  ///
  /// In en, this message translates to:
  /// **'Attune'**
  String get navAttune;

  /// No description provided for @navMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get navMonitor;

  /// No description provided for @navBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get navBuild;

  /// No description provided for @navReflect.
  ///
  /// In en, this message translates to:
  /// **'Reflect'**
  String get navReflect;

  /// No description provided for @navProcess.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get navProcess;

  /// No description provided for @anchorLabel.
  ///
  /// In en, this message translates to:
  /// **'Anchor'**
  String get anchorLabel;

  /// Check-in title. Keep the line break. Do not turn this into a diagnosis.
  ///
  /// In en, this message translates to:
  /// **'how are you\nright now?'**
  String get checkinTitle;

  /// No description provided for @checkinHint.
  ///
  /// In en, this message translates to:
  /// **'Tap where the body is speaking. Tap again to change it. This shapes what is available.'**
  String get checkinHint;

  /// Shows the person's own reading. {state} is overwhelmed, present, or flat or numb.
  ///
  /// In en, this message translates to:
  /// **'this reads as {state}'**
  String readingAs(String state);

  /// No description provided for @nothingStandsOut.
  ///
  /// In en, this message translates to:
  /// **'nothing stands out'**
  String get nothingStandsOut;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'continue'**
  String get continueLabel;

  /// No description provided for @tight.
  ///
  /// In en, this message translates to:
  /// **'tight'**
  String get tight;

  /// No description provided for @heavy.
  ///
  /// In en, this message translates to:
  /// **'heavy'**
  String get heavy;

  /// No description provided for @unmarked.
  ///
  /// In en, this message translates to:
  /// **'unmarked'**
  String get unmarked;

  /// The person's hyperaroused reading. Not a diagnosis.
  ///
  /// In en, this message translates to:
  /// **'overwhelmed'**
  String get stateOverwhelmed;

  /// The person's regulated reading. Not a diagnosis.
  ///
  /// In en, this message translates to:
  /// **'present'**
  String get statePresent;

  /// The person's hypoaroused reading. Not a diagnosis.
  ///
  /// In en, this message translates to:
  /// **'flat or numb'**
  String get stateFlat;

  /// No description provided for @lockedWhenOverwhelmed.
  ///
  /// In en, this message translates to:
  /// **'not available when overwhelmed'**
  String get lockedWhenOverwhelmed;

  /// No description provided for @lockedWhenFlat.
  ///
  /// In en, this message translates to:
  /// **'not available when flat'**
  String get lockedWhenFlat;

  /// No description provided for @bodyMasculine.
  ///
  /// In en, this message translates to:
  /// **'Masculine'**
  String get bodyMasculine;

  /// No description provided for @bodyFeminine.
  ///
  /// In en, this message translates to:
  /// **'Feminine'**
  String get bodyFeminine;

  /// No description provided for @bodyNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get bodyNeutral;

  /// No description provided for @zoneHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get zoneHead;

  /// No description provided for @zoneThroat.
  ///
  /// In en, this message translates to:
  /// **'Throat'**
  String get zoneThroat;

  /// No description provided for @zoneChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get zoneChest;

  /// No description provided for @zoneStomach.
  ///
  /// In en, this message translates to:
  /// **'Stomach'**
  String get zoneStomach;

  /// No description provided for @feelingBetterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you feeling better?'**
  String get feelingBetterQuestion;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @readingStays.
  ///
  /// In en, this message translates to:
  /// **'The reading stays as it is.'**
  String get readingStays;

  /// No description provided for @markedPresent.
  ///
  /// In en, this message translates to:
  /// **'Marked as present.'**
  String get markedPresent;

  /// No description provided for @stillMarkedPresent.
  ///
  /// In en, this message translates to:
  /// **'Still marked as present.'**
  String get stillMarkedPresent;

  /// No description provided for @readingNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The reading could not be saved.'**
  String get readingNotSaved;

  /// Title of the box breathing screen.
  ///
  /// In en, this message translates to:
  /// **'Box Breathing'**
  String get boxBreathingTitle;

  /// No description provided for @breathing478Title.
  ///
  /// In en, this message translates to:
  /// **'4-7-8 Breathing'**
  String get breathing478Title;

  /// Button that starts a breathing exercise.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get breathingBegin;

  /// Button that pauses a breathing exercise.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get breathingPause;

  /// Tooltip when the breathing vibration pace is on. The phone does not measure the breath.
  ///
  /// In en, this message translates to:
  /// **'Vibration pace on'**
  String get breathHapticsOn;

  /// Tooltip when the breathing vibration pace is off.
  ///
  /// In en, this message translates to:
  /// **'Vibration pace off'**
  String get breathHapticsOff;

  /// No description provided for @breathingResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get breathingResume;

  /// No description provided for @breathingCycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get breathingCycles;

  /// Which pacing cycle is playing, and how many there are in the round.
  ///
  /// In en, this message translates to:
  /// **'Cycle {current} of {total}'**
  String breathingCycle(int current, int total);

  /// No description provided for @anotherRound.
  ///
  /// In en, this message translates to:
  /// **'Another round'**
  String get anotherRound;

  /// No description provided for @inhale.
  ///
  /// In en, this message translates to:
  /// **'Inhale'**
  String get inhale;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @exhale.
  ///
  /// In en, this message translates to:
  /// **'Exhale'**
  String get exhale;

  /// No description provided for @breathing478NeedsCheckin.
  ///
  /// In en, this message translates to:
  /// **'Check in before using 4-7-8 breathing.'**
  String get breathing478NeedsCheckin;

  /// No description provided for @breathing478Locked.
  ///
  /// In en, this message translates to:
  /// **'4-7-8 breathing is {reason}.'**
  String breathing478Locked(String reason);

  /// No description provided for @regulateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Immediate tools for the state you are in now.'**
  String get regulateSubtitle;

  /// No description provided for @sectionBreathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get sectionBreathing;

  /// No description provided for @sectionGrounding.
  ///
  /// In en, this message translates to:
  /// **'Grounding'**
  String get sectionGrounding;

  /// No description provided for @sectionVagal.
  ///
  /// In en, this message translates to:
  /// **'Vagal nerve activation'**
  String get sectionVagal;

  /// No description provided for @boxBreathingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'4-4-4-4 · Calm the nervous system'**
  String get boxBreathingSubtitle;

  /// No description provided for @sighTitle.
  ///
  /// In en, this message translates to:
  /// **'Physiological sigh'**
  String get sighTitle;

  /// No description provided for @sighSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Double inhale + long exhale · Fastest reset'**
  String get sighSubtitle;

  /// No description provided for @breathing478Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep & acute anxiety'**
  String get breathing478Subtitle;

  /// No description provided for @wimHofTitle.
  ///
  /// In en, this message translates to:
  /// **'Wim Hof Breathing'**
  String get wimHofTitle;

  /// No description provided for @wimHofSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guided round protocol'**
  String get wimHofSubtitle;

  /// No description provided for @groundingTitle.
  ///
  /// In en, this message translates to:
  /// **'5-4-3-2-1 Grounding'**
  String get groundingTitle;

  /// No description provided for @groundingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sensory anchoring — bring yourself back'**
  String get groundingSubtitle;

  /// No description provided for @coldWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Cold Water'**
  String get coldWaterTitle;

  /// No description provided for @coldWaterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Diving reflex · Vagal activation'**
  String get coldWaterSubtitle;

  /// No description provided for @safePlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe Place'**
  String get safePlaceTitle;

  /// No description provided for @safePlaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guided visualisation with ambient sound'**
  String get safePlaceSubtitle;

  /// No description provided for @vagalTitle.
  ///
  /// In en, this message translates to:
  /// **'Vagal Prompts'**
  String get vagalTitle;

  /// No description provided for @vagalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Humming · Gargling · Extended exhale'**
  String get vagalSubtitle;

  /// No description provided for @sighCueIn.
  ///
  /// In en, this message translates to:
  /// **'breathe in through your nose'**
  String get sighCueIn;

  /// No description provided for @sighCueSniff.
  ///
  /// In en, this message translates to:
  /// **'one more sniff'**
  String get sighCueSniff;

  /// No description provided for @sighCueOut.
  ///
  /// In en, this message translates to:
  /// **'breathe out slowly'**
  String get sighCueOut;

  /// No description provided for @sighDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get sighDone;

  /// No description provided for @sighAgain.
  ///
  /// In en, this message translates to:
  /// **'again'**
  String get sighAgain;

  /// No description provided for @sighPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Double inhale, long exhale'**
  String get sighPhaseLabel;

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'you\'re here.'**
  String get youAreHere;

  /// No description provided for @takeYourTime.
  ///
  /// In en, this message translates to:
  /// **'take your time.'**
  String get takeYourTime;

  /// No description provided for @goToRegulate.
  ///
  /// In en, this message translates to:
  /// **'go to regulate'**
  String get goToRegulate;

  /// No description provided for @callCrisisLine.
  ///
  /// In en, this message translates to:
  /// **'call a crisis line'**
  String get callCrisisLine;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @youAreHereSentence.
  ///
  /// In en, this message translates to:
  /// **'You are here.'**
  String get youAreHereSentence;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @humming.
  ///
  /// In en, this message translates to:
  /// **'Humming'**
  String get humming;

  /// No description provided for @gargling.
  ///
  /// In en, this message translates to:
  /// **'Gargling'**
  String get gargling;

  /// No description provided for @extendedExhale.
  ///
  /// In en, this message translates to:
  /// **'Extended Exhale'**
  String get extendedExhale;

  /// No description provided for @divingReflex.
  ///
  /// In en, this message translates to:
  /// **'Diving Reflex'**
  String get divingReflex;

  /// No description provided for @vagalScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Vagal Nerve Activation'**
  String get vagalScreenTitle;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @safePlaceLocked.
  ///
  /// In en, this message translates to:
  /// **'Safe place is {reason}.'**
  String safePlaceLocked(String reason);

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @beginVisualisation.
  ///
  /// In en, this message translates to:
  /// **'Begin visualisation'**
  String get beginVisualisation;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @safePlaceHint.
  ///
  /// In en, this message translates to:
  /// **'A quiet beach, a childhood room, a forest clearing…'**
  String get safePlaceHint;

  /// No description provided for @customiseSafePlace.
  ///
  /// In en, this message translates to:
  /// **'Customise your safe place'**
  String get customiseSafePlace;

  /// No description provided for @wimHofOnlyWhenPresent.
  ///
  /// In en, this message translates to:
  /// **'Wim Hof breathing is only available when present.'**
  String get wimHofOnlyWhenPresent;

  /// No description provided for @wimHofChecksFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete the safety checks before starting.'**
  String get wimHofChecksFirst;

  /// No description provided for @wimHofWarning.
  ///
  /// In en, this message translates to:
  /// **'Never practice in water or while driving. Stop if you feel unwell.'**
  String get wimHofWarning;

  /// No description provided for @roundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String roundNumber(int round);

  /// No description provided for @roundComplete.
  ///
  /// In en, this message translates to:
  /// **'Round {round} complete'**
  String roundComplete(int round);

  /// No description provided for @exhaleAndHold.
  ///
  /// In en, this message translates to:
  /// **'Exhale & Hold'**
  String get exhaleAndHold;

  /// No description provided for @recoveryBreath.
  ///
  /// In en, this message translates to:
  /// **'Recovery Breath'**
  String get recoveryBreath;

  /// No description provided for @retentionHold.
  ///
  /// In en, this message translates to:
  /// **'Retention Hold'**
  String get retentionHold;

  /// No description provided for @readyRecovery.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready — recovery breath'**
  String get readyRecovery;

  /// No description provided for @release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get release;

  /// No description provided for @nextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get nextRound;

  /// No description provided for @thirtyBreaths.
  ///
  /// In en, this message translates to:
  /// **'30 Deep Breaths'**
  String get thirtyBreaths;

  /// No description provided for @thirtyBreathsBody.
  ///
  /// In en, this message translates to:
  /// **'Breathe in fully, let go without forcing. After 30 breaths, exhale and hold only as long as comfortable.'**
  String get thirtyBreathsBody;

  /// No description provided for @wimHofCheck1.
  ///
  /// In en, this message translates to:
  /// **'I am not in water, driving, or standing.'**
  String get wimHofCheck1;

  /// No description provided for @wimHofCheck2.
  ///
  /// In en, this message translates to:
  /// **'I am lying down or seated somewhere safe.'**
  String get wimHofCheck2;

  /// No description provided for @wimHofCheck3.
  ///
  /// In en, this message translates to:
  /// **'I do not have a seizure disorder.'**
  String get wimHofCheck3;

  /// No description provided for @wimHofCheck4.
  ///
  /// In en, this message translates to:
  /// **'I do not have a serious heart, blood pressure, or respiratory condition.'**
  String get wimHofCheck4;

  /// No description provided for @wimHofCheck5.
  ///
  /// In en, this message translates to:
  /// **'I am not pregnant.'**
  String get wimHofCheck5;

  /// No description provided for @wimHofCheck6.
  ///
  /// In en, this message translates to:
  /// **'If this is my first time, another person is nearby.'**
  String get wimHofCheck6;

  /// No description provided for @wimHofCheck7.
  ///
  /// In en, this message translates to:
  /// **'I will stop immediately if I feel unwell.'**
  String get wimHofCheck7;

  /// No description provided for @onboardingKicker1.
  ///
  /// In en, this message translates to:
  /// **'Taming the storm'**
  String get onboardingKicker1;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Tame the Storm'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'The nervous system can feel like weather you did not choose. Taming it means learning the shape of that weather: when to slow down, when to stay, and when a tool stays closed. Like Sun Wukong learning to hold his own chaos, this is practice in self-regulation.'**
  String get onboardingBody1;

  /// No description provided for @onboardingKicker2.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get onboardingKicker2;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Zero Tracking. Zero Guilt.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Check-ins, journal entries, and sensor readings stay on this device. There is no account, no streak, and no score for the days you were away. Nothing here is sent or sold.'**
  String get onboardingBody2;

  /// No description provided for @onboardingCare.
  ///
  /// In en, this message translates to:
  /// **'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy. If you are in immediate danger, contact emergency services.'**
  String get onboardingCare;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @anchorBaseline.
  ///
  /// In en, this message translates to:
  /// **'Anchor your baseline'**
  String get anchorBaseline;

  /// No description provided for @wukongLabel.
  ///
  /// In en, this message translates to:
  /// **'Sun Wukong in red and gold, holding a phone.'**
  String get wukongLabel;

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageLabel(int page);

  /// No description provided for @processSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deeper work. Use when regulated and ready.'**
  String get processSubtitle;

  /// No description provided for @processCaution.
  ///
  /// In en, this message translates to:
  /// **'These tools are for processing, not crisis. Make sure you feel regulated before starting.'**
  String get processCaution;

  /// No description provided for @bilateralTitle.
  ///
  /// In en, this message translates to:
  /// **'Bilateral Stimulation'**
  String get bilateralTitle;

  /// No description provided for @eftTapping.
  ///
  /// In en, this message translates to:
  /// **'EFT Tapping'**
  String get eftTapping;

  /// No description provided for @somaticScan.
  ///
  /// In en, this message translates to:
  /// **'Somatic Body Scan'**
  String get somaticScan;

  /// No description provided for @traumaJournal.
  ///
  /// In en, this message translates to:
  /// **'Trauma-informed Journaling'**
  String get traumaJournal;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @bilateralOnlyWhenPresent.
  ///
  /// In en, this message translates to:
  /// **'Bilateral stimulation is only available when present.'**
  String get bilateralOnlyWhenPresent;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get sessionComplete;

  /// No description provided for @sessionCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Take a moment. Notice what came up, if anything.\n\nThere is no right way to feel.'**
  String get sessionCompleteBody;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @beginSession.
  ///
  /// In en, this message translates to:
  /// **'Begin session'**
  String get beginSession;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @sessionLength.
  ///
  /// In en, this message translates to:
  /// **'Session length'**
  String get sessionLength;

  /// No description provided for @dotSize.
  ///
  /// In en, this message translates to:
  /// **'Dot size'**
  String get dotSize;

  /// No description provided for @dotColour.
  ///
  /// In en, this message translates to:
  /// **'Dot colour'**
  String get dotColour;

  /// No description provided for @visual.
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get visual;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @tactile.
  ///
  /// In en, this message translates to:
  /// **'Tactile'**
  String get tactile;

  /// No description provided for @visualAudio.
  ///
  /// In en, this message translates to:
  /// **'Visual + Audio'**
  String get visualAudio;

  /// No description provided for @visualTactile.
  ///
  /// In en, this message translates to:
  /// **'Visual + Tactile'**
  String get visualTactile;

  /// No description provided for @visualAudioTactile.
  ///
  /// In en, this message translates to:
  /// **'Visual + Audio + Tactile'**
  String get visualAudioTactile;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @visualOnly.
  ///
  /// In en, this message translates to:
  /// **'Visual only'**
  String get visualOnly;

  /// No description provided for @audioOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio only'**
  String get audioOnly;

  /// No description provided for @tactileOnly.
  ///
  /// In en, this message translates to:
  /// **'Tactile only'**
  String get tactileOnly;

  /// No description provided for @allThree.
  ///
  /// In en, this message translates to:
  /// **'All three'**
  String get allThree;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String minutesShort(int minutes);

  /// No description provided for @bilateralCare.
  ///
  /// In en, this message translates to:
  /// **'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy.\nBilateral stimulation — between-session support, not therapy.'**
  String get bilateralCare;

  /// No description provided for @attuneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generated sound tools for steady attention.'**
  String get attuneSubtitle;

  /// No description provided for @binauralBeats.
  ///
  /// In en, this message translates to:
  /// **'Binaural beats'**
  String get binauralBeats;

  /// No description provided for @isochronicTones.
  ///
  /// In en, this message translates to:
  /// **'Isochronic tones'**
  String get isochronicTones;

  /// No description provided for @natureSoundscapes.
  ///
  /// In en, this message translates to:
  /// **'Nature soundscapes'**
  String get natureSoundscapes;

  /// No description provided for @monitorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check in with your nervous system.'**
  String get monitorSubtitle;

  /// No description provided for @hrvTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart rate variability'**
  String get hrvTitle;

  /// No description provided for @hrvTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to measure via camera'**
  String get hrvTap;

  /// No description provided for @hyperarousal.
  ///
  /// In en, this message translates to:
  /// **'Hyperarousal'**
  String get hyperarousal;

  /// No description provided for @windowOfTolerance.
  ///
  /// In en, this message translates to:
  /// **'Window of tolerance'**
  String get windowOfTolerance;

  /// No description provided for @hypoarousal.
  ///
  /// In en, this message translates to:
  /// **'Hypoarousal'**
  String get hypoarousal;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @noCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera found'**
  String get noCamera;

  /// No description provided for @noCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Camera PPG requires a rear camera with flash.'**
  String get noCameraBody;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access denied'**
  String get cameraDenied;

  /// No description provided for @cameraDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in your device settings to use this feature.'**
  String get cameraDeniedBody;

  /// No description provided for @measurementFailed.
  ///
  /// In en, this message translates to:
  /// **'Measurement failed'**
  String get measurementFailed;

  /// No description provided for @measurementFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Not enough signal detected. Make sure your fingertip firmly covers the camera and flash.'**
  String get measurementFailedBody;

  /// No description provided for @measureIn60.
  ///
  /// In en, this message translates to:
  /// **'Measure in 60 seconds'**
  String get measureIn60;

  /// No description provided for @hrvInstructions.
  ///
  /// In en, this message translates to:
  /// **'Place your fingertip firmly over the rear camera and flash. Stay still. Results are stored on this device only.'**
  String get hrvInstructions;

  /// No description provided for @coverLens.
  ///
  /// In en, this message translates to:
  /// **'Cover both the camera lens and the flash with your fingertip.'**
  String get coverLens;

  /// No description provided for @stayStill.
  ///
  /// In en, this message translates to:
  /// **'Stay as still as possible. Motion creates noise in the signal.'**
  String get stayStill;

  /// No description provided for @notAMedicalDevice.
  ///
  /// In en, this message translates to:
  /// **'Not a medical device. For self-awareness only.'**
  String get notAMedicalDevice;

  /// No description provided for @notAMedicalDeviceShort.
  ///
  /// In en, this message translates to:
  /// **'Not a medical device.'**
  String get notAMedicalDeviceShort;

  /// No description provided for @startMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Start measurement'**
  String get startMeasurement;

  /// No description provided for @signalDetected.
  ///
  /// In en, this message translates to:
  /// **'signal detected'**
  String get signalDetected;

  /// No description provided for @placeFinger.
  ///
  /// In en, this message translates to:
  /// **'place finger on camera + flash'**
  String get placeFinger;

  /// No description provided for @waitingForSignal.
  ///
  /// In en, this message translates to:
  /// **'waiting for signal…'**
  String get waitingForSignal;

  /// No description provided for @stopAndCalculate.
  ///
  /// In en, this message translates to:
  /// **'Stop and calculate'**
  String get stopAndCalculate;

  /// No description provided for @yourReading.
  ///
  /// In en, this message translates to:
  /// **'Your reading'**
  String get yourReading;

  /// No description provided for @basedOnHeartbeats.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} heartbeats · not a medical device'**
  String basedOnHeartbeats(int count);

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get heartRate;

  /// No description provided for @hrvTrend.
  ///
  /// In en, this message translates to:
  /// **'HRV is most meaningful as a trend over time, not a single reading. Compare against your own baseline, not population averages.'**
  String get hrvTrend;

  /// No description provided for @measureAgain.
  ///
  /// In en, this message translates to:
  /// **'Measure again'**
  String get measureAgain;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @buildSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A private space to write. Nothing leaves this device.'**
  String get buildSubtitle;

  /// No description provided for @nothingWritten.
  ///
  /// In en, this message translates to:
  /// **'Nothing written yet.\n\nTap the pencil when you\'re ready.'**
  String get nothingWritten;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryTitle;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @emptyEntry.
  ///
  /// In en, this message translates to:
  /// **'empty entry'**
  String get emptyEntry;

  /// No description provided for @journalHint.
  ///
  /// In en, this message translates to:
  /// **'write here…'**
  String get journalHint;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get saved;

  /// No description provided for @prompt.
  ///
  /// In en, this message translates to:
  /// **'prompt'**
  String get prompt;

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordCount(int count);

  /// No description provided for @prompt1.
  ///
  /// In en, this message translates to:
  /// **'what are you noticing right now?'**
  String get prompt1;

  /// No description provided for @prompt2.
  ///
  /// In en, this message translates to:
  /// **'what does your body need today?'**
  String get prompt2;

  /// No description provided for @prompt3.
  ///
  /// In en, this message translates to:
  /// **'is there something you want to put down somewhere safe?'**
  String get prompt3;

  /// No description provided for @prompt4.
  ///
  /// In en, this message translates to:
  /// **'what felt okay today, even if small?'**
  String get prompt4;

  /// No description provided for @prompt5.
  ///
  /// In en, this message translates to:
  /// **'is there something you\'ve been carrying?'**
  String get prompt5;

  /// No description provided for @prompt6.
  ///
  /// In en, this message translates to:
  /// **'you don\'t have to make it make sense. just write.'**
  String get prompt6;

  /// No description provided for @prompt7.
  ///
  /// In en, this message translates to:
  /// **'what\'s present for you right now?'**
  String get prompt7;

  /// No description provided for @prompt8.
  ///
  /// In en, this message translates to:
  /// **'what would you say to yourself if you were being kind?'**
  String get prompt8;

  /// No description provided for @reflectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'a record of what you\'ve explored.'**
  String get reflectSubtitle;

  /// No description provided for @vaultCreateLead.
  ///
  /// In en, this message translates to:
  /// **'Choose a 6-digit key for Reflect.'**
  String get vaultCreateLead;

  /// No description provided for @vaultConfirmLead.
  ///
  /// In en, this message translates to:
  /// **'Enter the same key again.'**
  String get vaultConfirmLead;

  /// No description provided for @vaultEnterLead.
  ///
  /// In en, this message translates to:
  /// **'Enter your key to open Reflect.'**
  String get vaultEnterLead;

  /// No description provided for @vaultMismatch.
  ///
  /// In en, this message translates to:
  /// **'Those keys did not match.'**
  String get vaultMismatch;

  /// No description provided for @vaultWrong.
  ///
  /// In en, this message translates to:
  /// **'That key did not open this vault.'**
  String get vaultWrong;

  /// No description provided for @vaultShort.
  ///
  /// In en, this message translates to:
  /// **'Use 6 digits.'**
  String get vaultShort;

  /// No description provided for @vaultJournalLocked.
  ///
  /// In en, this message translates to:
  /// **'The journal is locked.'**
  String get vaultJournalLocked;

  /// No description provided for @vaultUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get vaultUnlock;

  /// No description provided for @vaultDeleteDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get vaultDeleteDigit;

  /// No description provided for @vaultCopyLocked.
  ///
  /// In en, this message translates to:
  /// **'Unlock Reflect before copying this record.'**
  String get vaultCopyLocked;

  /// No description provided for @vaultUnread.
  ///
  /// In en, this message translates to:
  /// **'The vault could not be read on this device.'**
  String get vaultUnread;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @reflectEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.\n\nUse a few tools and come back.'**
  String get reflectEmpty;

  /// No description provided for @timeWithEachArea.
  ///
  /// In en, this message translates to:
  /// **'time with each area'**
  String get timeWithEachArea;

  /// No description provided for @whatYouReachedFor.
  ///
  /// In en, this message translates to:
  /// **'what you\'ve reached for'**
  String get whatYouReachedFor;

  /// No description provided for @statesPast35.
  ///
  /// In en, this message translates to:
  /// **'YOUR STATES — PAST 35 DAYS'**
  String get statesPast35;

  /// No description provided for @noCheckIn.
  ///
  /// In en, this message translates to:
  /// **'no check-in'**
  String get noCheckIn;

  /// No description provided for @flatShort.
  ///
  /// In en, this message translates to:
  /// **'flat'**
  String get flatShort;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get noData;

  /// No description provided for @crisisSupport.
  ///
  /// In en, this message translates to:
  /// **'Crisis support'**
  String get crisisSupport;

  /// No description provided for @crisisDanger.
  ///
  /// In en, this message translates to:
  /// **'If you are in immediate danger, call the emergency number for where you are.'**
  String get crisisDanger;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @searchNameOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Search name or number'**
  String get searchNameOrNumber;

  /// No description provided for @noLinesStored.
  ///
  /// In en, this message translates to:
  /// **'No lines are stored for this country. Choose International for what to do next.'**
  String get noLinesStored;

  /// No description provided for @supportLines.
  ///
  /// In en, this message translates to:
  /// **'Support lines'**
  String get supportLines;

  /// No description provided for @noSupportMatch.
  ///
  /// In en, this message translates to:
  /// **'No support lines match that search. The emergency number stays listed above.'**
  String get noSupportMatch;

  /// No description provided for @somewhereElse.
  ///
  /// In en, this message translates to:
  /// **'Somewhere else? Choose International in the country list.'**
  String get somewhereElse;

  /// No description provided for @crisisDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These directories are stored completely offline on your device. Calls route through your cellular provider and standard carrier rates or calling rules apply.'**
  String get crisisDisclaimer;

  /// No description provided for @numberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get numberCopied;

  /// No description provided for @copyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get copyNumber;

  /// No description provided for @dialsNumber.
  ///
  /// In en, this message translates to:
  /// **'Dials {number}'**
  String dialsNumber(String number);

  /// No description provided for @sendThisText.
  ///
  /// In en, this message translates to:
  /// **'Send this text?'**
  String get sendThisText;

  /// No description provided for @callThisNumber.
  ///
  /// In en, this message translates to:
  /// **'Call this number?'**
  String get callThisNumber;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @textOpensApp.
  ///
  /// In en, this message translates to:
  /// **'This opens your messages app with the text ready. This app does not send it or use the internet.'**
  String get textOpensApp;

  /// No description provided for @callOpensDialer.
  ///
  /// In en, this message translates to:
  /// **'This opens your phone dialer with the number ready. This app does not place the call or use the internet.'**
  String get callOpensDialer;

  /// No description provided for @textNumber.
  ///
  /// In en, this message translates to:
  /// **'Text {number}'**
  String textNumber(String number);

  /// No description provided for @callNumber.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callNumber(String number);

  /// No description provided for @trustedPerson.
  ///
  /// In en, this message translates to:
  /// **'Trusted person'**
  String get trustedPerson;

  /// No description provided for @saveTrustedPerson.
  ///
  /// In en, this message translates to:
  /// **'Save a trusted person'**
  String get saveTrustedPerson;

  /// No description provided for @editTrustedPeople.
  ///
  /// In en, this message translates to:
  /// **'Edit trusted people'**
  String get editTrustedPeople;

  /// No description provided for @trustedWhenPresent.
  ///
  /// In en, this message translates to:
  /// **'A trusted person can be saved when the reading is present.'**
  String get trustedWhenPresent;

  /// No description provided for @trustedSavedWhenPresent.
  ///
  /// In en, this message translates to:
  /// **'This can be saved when the reading is present.'**
  String get trustedSavedWhenPresent;

  /// No description provided for @availableWhenPresent.
  ///
  /// In en, this message translates to:
  /// **'Available when the reading is present.'**
  String get availableWhenPresent;

  /// No description provided for @savedTextOnDevice.
  ///
  /// In en, this message translates to:
  /// **'A saved text, kept on this device.'**
  String get savedTextOnDevice;

  /// No description provided for @savedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device.'**
  String get savedOnDevice;

  /// No description provided for @trustedPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Text and call open your phone\'s own apps. Nothing is sent from here.'**
  String get trustedPrivacy;

  /// No description provided for @addAnotherPerson.
  ///
  /// In en, this message translates to:
  /// **'Add another person'**
  String get addAnotherPerson;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @removeThisPerson.
  ///
  /// In en, this message translates to:
  /// **'Remove this person?'**
  String get removeThisPerson;

  /// No description provided for @numberWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'The saved number will be removed from this device.'**
  String get numberWillBeRemoved;

  /// No description provided for @addAName.
  ///
  /// In en, this message translates to:
  /// **'Add a name.'**
  String get addAName;

  /// No description provided for @shorterName.
  ///
  /// In en, this message translates to:
  /// **'Use a shorter name.'**
  String get shorterName;

  /// No description provided for @phoneNeedsDigits.
  ///
  /// In en, this message translates to:
  /// **'Use a phone number, with the country code if it needs one.'**
  String get phoneNeedsDigits;

  /// No description provided for @addAMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a short message.'**
  String get addAMessage;

  /// No description provided for @messageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the message to {limit} characters.'**
  String messageTooLong(int limit);

  /// No description provided for @numberCannotOpen.
  ///
  /// In en, this message translates to:
  /// **'That number cannot be opened from here.'**
  String get numberCannotOpen;

  /// No description provided for @messagesDidNotOpen.
  ///
  /// In en, this message translates to:
  /// **'The messages app did not open.'**
  String get messagesDidNotOpen;

  /// No description provided for @phoneDidNotOpen.
  ///
  /// In en, this message translates to:
  /// **'The phone app did not open.'**
  String get phoneDidNotOpen;

  /// No description provided for @textPerson.
  ///
  /// In en, this message translates to:
  /// **'Text {name}'**
  String textPerson(String name);

  /// No description provided for @callPerson.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callPerson(String name);

  /// No description provided for @sitWithMe.
  ///
  /// In en, this message translates to:
  /// **'Sit with me'**
  String get sitWithMe;

  /// No description provided for @justLettingYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Just letting you know'**
  String get justLettingYouKnow;

  /// No description provided for @clearAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all data?'**
  String get clearAllDataTitle;

  /// No description provided for @clearAllDataBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:\n\n• Journal entries\n• HRV readings\n• Check-in history\n• Baseline feedback history\n• Session log\n• Safe place description\n• Trusted people\n\nThis cannot be undone.'**
  String get clearAllDataBody;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared.'**
  String get allDataCleared;

  /// No description provided for @checkinAlreadyOpen.
  ///
  /// In en, this message translates to:
  /// **'A check-in is already open.'**
  String get checkinAlreadyOpen;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @builtFromLivedExperience.
  ///
  /// In en, this message translates to:
  /// **'Built from lived experience.\nFor everyone who is still here.'**
  String get builtFromLivedExperience;

  /// No description provided for @openSourceLine.
  ///
  /// In en, this message translates to:
  /// **'Open source · No ads · No data collection · Free forever.'**
  String get openSourceLine;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @crisisDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Crisis support directory'**
  String get crisisDirectoryLabel;

  /// No description provided for @crisisDirectorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline helplines by country. Stays on this device.'**
  String get crisisDirectorySubtitle;

  /// No description provided for @showBaseline.
  ///
  /// In en, this message translates to:
  /// **'Show baseline check-in'**
  String get showBaseline;

  /// No description provided for @showBaselineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview the local prompt implementation'**
  String get showBaselineSubtitle;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @entriesStay.
  ///
  /// In en, this message translates to:
  /// **'Your entries stay on this device.'**
  String get entriesStay;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Zero network requests. Zero analytics. Zero crash reporting. Everything you enter — check-ins, journal entries, HRV readings, your safe place description, and trusted people — is stored only on this device.\n\nWe cannot provide your data to anyone because we do not have it.'**
  String get privacyBody;

  /// No description provided for @journalDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Journal entries — device only'**
  String get journalDeviceOnly;

  /// No description provided for @hrvDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'HRV readings — device only'**
  String get hrvDeviceOnly;

  /// No description provided for @checkinDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Check-in history — device only'**
  String get checkinDeviceOnly;

  /// No description provided for @sessionDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Session log — device only'**
  String get sessionDeviceOnly;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// No description provided for @settingsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy, and does not diagnose, assess, or treat any condition.\n\nIf you are in crisis, please reach out to a professional or use the crisis resources listed above.'**
  String get settingsDisclaimer;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @exportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Passphrase-sealed file on this device'**
  String get exportSubtitle;

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a sealed copy onto this device'**
  String get importSubtitle;

  /// No description provided for @clearAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Journal, HRV, check-ins, session log, safe place'**
  String get clearAllSubtitle;

  /// No description provided for @redoOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Redo onboarding'**
  String get redoOnboarding;

  /// No description provided for @redoOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your profile questionnaire'**
  String get redoOnboardingSubtitle;

  /// No description provided for @redoOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Redo onboarding?'**
  String get redoOnboardingTitle;

  /// No description provided for @redoOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile will be reset and you\'ll go through the questionnaire again. Your history is not affected.'**
  String get redoOnboardingBody;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @accent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accent;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @contrastSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get contrastSoft;

  /// No description provided for @contrastStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get contrastStandard;

  /// No description provided for @contrastHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get contrastHigh;

  /// No description provided for @passphrasesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The two passphrases do not match.'**
  String get passphrasesDoNotMatch;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @repeatPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Repeat passphrase'**
  String get repeatPassphrase;

  /// No description provided for @exportBody.
  ///
  /// In en, this message translates to:
  /// **'The copy is sealed with a passphrase you choose. MonkeyThrive does not keep that passphrase and cannot open the copy without it. Nothing is uploaded.'**
  String get exportBody;

  /// No description provided for @exportKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep this copy somewhere you control. Opening it on another device needs the same passphrase.'**
  String get exportKeep;

  /// No description provided for @savedAs.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String savedAs(String name);

  /// No description provided for @sealing.
  ///
  /// In en, this message translates to:
  /// **'Sealing'**
  String get sealing;

  /// No description provided for @createCopy.
  ///
  /// In en, this message translates to:
  /// **'Create copy'**
  String get createCopy;

  /// No description provided for @saveFileAndCopy.
  ///
  /// In en, this message translates to:
  /// **'Save file and copy'**
  String get saveFileAndCopy;

  /// No description provided for @copyRestored.
  ///
  /// In en, this message translates to:
  /// **'Copy restored on this device.'**
  String get copyRestored;

  /// No description provided for @importBody.
  ///
  /// In en, this message translates to:
  /// **'This replaces the journal, check-ins, session log, trusted people, and preferences on this device. It does not contact a server.'**
  String get importBody;

  /// No description provided for @pasteTheCopy.
  ///
  /// In en, this message translates to:
  /// **'Paste the copy'**
  String get pasteTheCopy;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring'**
  String get restoring;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @howAreYouDoing.
  ///
  /// In en, this message translates to:
  /// **'How are you doing?'**
  String get howAreYouDoing;

  /// No description provided for @baselineDifferent.
  ///
  /// In en, this message translates to:
  /// **'I noticed things look a little different from your usual baseline.'**
  String get baselineDifferent;

  /// No description provided for @imOkay.
  ///
  /// In en, this message translates to:
  /// **'🙂  I\'m okay'**
  String get imOkay;

  /// No description provided for @wouldOneHelp.
  ///
  /// In en, this message translates to:
  /// **'Would one of these help?'**
  String get wouldOneHelp;

  /// No description provided for @sigh.
  ///
  /// In en, this message translates to:
  /// **'Sigh'**
  String get sigh;

  /// No description provided for @ground.
  ///
  /// In en, this message translates to:
  /// **'Ground'**
  String get ground;

  /// No description provided for @vagal.
  ///
  /// In en, this message translates to:
  /// **'Vagal'**
  String get vagal;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @coldHow.
  ///
  /// In en, this message translates to:
  /// **'How this works'**
  String get coldHow;

  /// No description provided for @coldBody.
  ///
  /// In en, this message translates to:
  /// **'Cold water activates the diving reflex — your body\'s built-in emergency brake. It slows your heart rate and activates the vagus nerve within seconds.\n\nApply cold water to your face, wrists, or the back of your neck.'**
  String get coldBody;

  /// No description provided for @coldFace.
  ///
  /// In en, this message translates to:
  /// **'Splash cold water on your face'**
  String get coldFace;

  /// No description provided for @coldWrists.
  ///
  /// In en, this message translates to:
  /// **'Hold cold water on your wrists'**
  String get coldWrists;

  /// No description provided for @coldNeck.
  ///
  /// In en, this message translates to:
  /// **'Cold cloth on the back of your neck'**
  String get coldNeck;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good.'**
  String get good;

  /// No description provided for @alreadyResponding.
  ///
  /// In en, this message translates to:
  /// **'Your nervous system is already responding.'**
  String get alreadyResponding;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @againLabel.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get againLabel;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get running;

  /// No description provided for @start30.
  ///
  /// In en, this message translates to:
  /// **'Start 30s timer'**
  String get start30;

  /// No description provided for @startSecondsTimer.
  ///
  /// In en, this message translates to:
  /// **'Start {seconds}s timer'**
  String startSecondsTimer(int seconds);

  /// No description provided for @secondsTimer.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s timer'**
  String secondsTimer(int seconds);

  /// No description provided for @wimHofLetGo.
  ///
  /// In en, this message translates to:
  /// **'breathe in · let go'**
  String get wimHofLetGo;

  /// No description provided for @wimHofExhaleBody.
  ///
  /// In en, this message translates to:
  /// **'Let all the air out and hold. Do not force it. Hold as long as comfortable.'**
  String get wimHofExhaleBody;

  /// No description provided for @wimHofRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Take one deep breath in and hold for 15 seconds.'**
  String get wimHofRecoveryBody;

  /// No description provided for @wimHofStillness.
  ///
  /// In en, this message translates to:
  /// **'Hold. Feel the stillness.'**
  String get wimHofStillness;

  /// No description provided for @wimHofRoundRest.
  ///
  /// In en, this message translates to:
  /// **'Rest for a moment before your next round, or finish here.'**
  String get wimHofRoundRest;

  /// No description provided for @timerClock.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String timerClock(int minutes, String seconds);

  /// No description provided for @timerSecondsOnly.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String timerSecondsOnly(int seconds);

  /// No description provided for @breathFraction.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String breathFraction(int current, int total);

  /// No description provided for @sighIntro.
  ///
  /// In en, this message translates to:
  /// **'Double inhale through the nose, then a long slow exhale. One of the fastest ways to calm your nervous system.'**
  String get sighIntro;

  /// No description provided for @sighRounds.
  ///
  /// In en, this message translates to:
  /// **'ROUNDS'**
  String get sighRounds;

  /// No description provided for @sighBegin.
  ///
  /// In en, this message translates to:
  /// **'begin'**
  String get sighBegin;

  /// No description provided for @sighPause.
  ///
  /// In en, this message translates to:
  /// **'pause'**
  String get sighPause;

  /// No description provided for @sighResume.
  ///
  /// In en, this message translates to:
  /// **'resume'**
  String get sighResume;

  /// No description provided for @senseSee.
  ///
  /// In en, this message translates to:
  /// **'See'**
  String get senseSee;

  /// No description provided for @senseHear.
  ///
  /// In en, this message translates to:
  /// **'Hear'**
  String get senseHear;

  /// No description provided for @senseTouch.
  ///
  /// In en, this message translates to:
  /// **'Touch'**
  String get senseTouch;

  /// No description provided for @senseSmell.
  ///
  /// In en, this message translates to:
  /// **'Smell'**
  String get senseSmell;

  /// No description provided for @senseTaste.
  ///
  /// In en, this message translates to:
  /// **'Taste'**
  String get senseTaste;

  /// No description provided for @groundSee.
  ///
  /// In en, this message translates to:
  /// **'Look around you. Find 5 things you can see right now.\n\nTake your time. Notice each one clearly — colour, shape, texture.'**
  String get groundSee;

  /// No description provided for @groundHear.
  ///
  /// In en, this message translates to:
  /// **'Close your eyes if that feels safe. Find 4 things you can hear.\n\nNear and far. Notice the sounds without judgement.'**
  String get groundHear;

  /// No description provided for @groundTouch.
  ///
  /// In en, this message translates to:
  /// **'Find 3 things you can feel right now — the chair beneath you, the fabric on your skin, the air temperature.\n\nPress your feet into the floor if that helps.'**
  String get groundTouch;

  /// No description provided for @groundSmell.
  ///
  /// In en, this message translates to:
  /// **'Find 2 things you can smell, or remember scents that feel safe and familiar to you.\n\nTake a slow breath in through your nose.'**
  String get groundSmell;

  /// No description provided for @groundTaste.
  ///
  /// In en, this message translates to:
  /// **'Notice 1 thing you can taste, or take a sip of water if you have some.\n\nYou are here. You are safe.'**
  String get groundTaste;

  /// No description provided for @groundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} things you can {sense}'**
  String groundCount(int count, String sense);

  /// No description provided for @groundBroughtBack.
  ///
  /// In en, this message translates to:
  /// **'You just brought yourself back with your own senses. That is the skill — and you have it.'**
  String get groundBroughtBack;

  /// No description provided for @youAreSafe.
  ///
  /// In en, this message translates to:
  /// **'You are here. You are safe.'**
  String get youAreSafe;

  /// No description provided for @vagalIntro.
  ///
  /// In en, this message translates to:
  /// **'The vagus nerve is your body\'s main pathway to calm. These techniques activate it directly.'**
  String get vagalIntro;

  /// No description provided for @hummingWhy.
  ///
  /// In en, this message translates to:
  /// **'Humming creates vibrations that directly stimulate the vagus nerve through the larynx. Even 2 minutes can measurably shift your state.'**
  String get hummingWhy;

  /// No description provided for @hummingHow.
  ///
  /// In en, this message translates to:
  /// **'Find a comfortable note and hum steadily. Feel the vibration in your chest and throat. Let the exhale extend naturally as you hum.'**
  String get hummingHow;

  /// No description provided for @garglingWhy.
  ///
  /// In en, this message translates to:
  /// **'Gargling activates muscles at the back of the throat that are connected to the vagus nerve. 30 seconds is enough to notice a shift.'**
  String get garglingWhy;

  /// No description provided for @garglingHow.
  ///
  /// In en, this message translates to:
  /// **'Take a mouthful of water and gargle vigorously for as long as comfortable. Repeat 2-3 times.'**
  String get garglingHow;

  /// No description provided for @extendedWhy.
  ///
  /// In en, this message translates to:
  /// **'The exhale activates the parasympathetic nervous system. Making your exhale twice as long as your inhale slows the heart rate and signals safety to your body.'**
  String get extendedWhy;

  /// No description provided for @extendedHow.
  ///
  /// In en, this message translates to:
  /// **'Breathe in for 4 counts. Breathe out slowly for 8 counts. There is no hold — just a long, steady out-breath. Repeat as many times as you need.'**
  String get extendedHow;

  /// No description provided for @divingWhy.
  ///
  /// In en, this message translates to:
  /// **'Submerging your face in cold water (or splashing it) triggers the mammalian diving reflex — your heart rate slows within seconds. It is one of the fastest calming signals your body responds to.'**
  String get divingWhy;

  /// No description provided for @divingHow.
  ///
  /// In en, this message translates to:
  /// **'Fill a bowl or sink with cold water. Hold your breath and submerge your face for 15-30 seconds, or splash cold water repeatedly over your face and forehead.'**
  String get divingHow;

  /// No description provided for @breathingGuide.
  ///
  /// In en, this message translates to:
  /// **'Breathing guide'**
  String get breathingGuide;

  /// No description provided for @vagalToolTitle.
  ///
  /// In en, this message translates to:
  /// **'Vagal — {title}'**
  String vagalToolTitle(String title);

  /// No description provided for @whyThisWorks.
  ///
  /// In en, this message translates to:
  /// **'WHY THIS WORKS'**
  String get whyThisWorks;

  /// No description provided for @safePlaceDefault.
  ///
  /// In en, this message translates to:
  /// **'Think of a place — real or imagined — where you feel completely safe. It might be a room, a landscape, a memory. It belongs only to you.'**
  String get safePlaceDefault;

  /// No description provided for @safePrompt1.
  ///
  /// In en, this message translates to:
  /// **'Settle in. There is nowhere you need to be right now.\n\nLet your breathing slow naturally.'**
  String get safePrompt1;

  /// No description provided for @safePrompt2.
  ///
  /// In en, this message translates to:
  /// **'Bring your safe place to mind. Allow yourself to arrive there.'**
  String get safePrompt2;

  /// No description provided for @safePrompt3.
  ///
  /// In en, this message translates to:
  /// **'Notice what you can see. The colours, the light, the shapes around you.'**
  String get safePrompt3;

  /// No description provided for @safePrompt4.
  ///
  /// In en, this message translates to:
  /// **'What sounds are here? Gentle, familiar sounds that belong to this place.'**
  String get safePrompt4;

  /// No description provided for @safePrompt5.
  ///
  /// In en, this message translates to:
  /// **'Feel the temperature. The air on your skin. The ground beneath you.'**
  String get safePrompt5;

  /// No description provided for @safePrompt6.
  ///
  /// In en, this message translates to:
  /// **'You are safe here. Nothing can reach you in this place.'**
  String get safePrompt6;

  /// No description provided for @safePrompt7.
  ///
  /// In en, this message translates to:
  /// **'Stay as long as you need. This place is always available to you.\n\nYou can return here any time you close your eyes.'**
  String get safePrompt7;

  /// No description provided for @safePlaceNeedsCheckin.
  ///
  /// In en, this message translates to:
  /// **'Check in before using safe place.'**
  String get safePlaceNeedsCheckin;

  /// No description provided for @yourSafePlace.
  ///
  /// In en, this message translates to:
  /// **'Your safe place'**
  String get yourSafePlace;

  /// No description provided for @describeSafePlace.
  ///
  /// In en, this message translates to:
  /// **'Describe your safe place'**
  String get describeSafePlace;

  /// No description provided for @safePlaceStored.
  ///
  /// In en, this message translates to:
  /// **'This is stored only on your device. Write whatever feels right — it only needs to make sense to you.'**
  String get safePlaceStored;

  /// No description provided for @breathing478Caution.
  ///
  /// In en, this message translates to:
  /// **'4-7-8 breathing is very effective for acute anxiety and sleep. If you feel dizzy, stop and breathe normally.'**
  String get breathing478Caution;

  /// No description provided for @howAreYouNow.
  ///
  /// In en, this message translates to:
  /// **'How are you right now?'**
  String get howAreYouNow;

  /// No description provided for @recentCheckins.
  ///
  /// In en, this message translates to:
  /// **'Recent check-ins'**
  String get recentCheckins;

  /// No description provided for @toolsUsedRecently.
  ///
  /// In en, this message translates to:
  /// **'Tools used recently'**
  String get toolsUsedRecently;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet.\nStart using tools and check back here.'**
  String get noHistory;

  /// No description provided for @hrvSummary.
  ///
  /// In en, this message translates to:
  /// **'{hr} bpm  ·  RMSSD {rmssd} ms'**
  String hrvSummary(int hr, int rmssd);

  /// No description provided for @windowHeading.
  ///
  /// In en, this message translates to:
  /// **'WINDOW OF TOLERANCE'**
  String get windowHeading;

  /// No description provided for @hyperNote.
  ///
  /// In en, this message translates to:
  /// **'Anxiety · Panic · Overwhelm'**
  String get hyperNote;

  /// No description provided for @regulatedNote.
  ///
  /// In en, this message translates to:
  /// **'Regulated · Processing possible'**
  String get regulatedNote;

  /// No description provided for @hypoNote.
  ///
  /// In en, this message translates to:
  /// **'Numbness · Shutdown · Dissociation'**
  String get hypoNote;

  /// No description provided for @checkInBelow.
  ///
  /// In en, this message translates to:
  /// **'Check in below to log where you are.'**
  String get checkInBelow;

  /// No description provided for @labelOverwhelmed.
  ///
  /// In en, this message translates to:
  /// **'Overwhelmed'**
  String get labelOverwhelmed;

  /// No description provided for @labelPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get labelPresent;

  /// No description provided for @labelFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get labelFlat;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String durationSeconds(int seconds);

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @dateSlash.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}'**
  String dateSlash(int day, int month);

  /// No description provided for @noBackCamera.
  ///
  /// In en, this message translates to:
  /// **'No back camera'**
  String get noBackCamera;

  /// No description provided for @hrvMeasurement.
  ///
  /// In en, this message translates to:
  /// **'HRV Measurement'**
  String get hrvMeasurement;

  /// No description provided for @hrvGoodRecovery.
  ///
  /// In en, this message translates to:
  /// **'good recovery'**
  String get hrvGoodRecovery;

  /// No description provided for @hrvModerate.
  ///
  /// In en, this message translates to:
  /// **'moderate'**
  String get hrvModerate;

  /// No description provided for @hrvLow.
  ///
  /// In en, this message translates to:
  /// **'low — rest or regulate'**
  String get hrvLow;

  /// No description provided for @overallVariability.
  ///
  /// In en, this message translates to:
  /// **'overall variability'**
  String get overallVariability;

  /// No description provided for @bpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get bpm;

  /// No description provided for @msUnit.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get msUnit;

  /// No description provided for @rmssdName.
  ///
  /// In en, this message translates to:
  /// **'RMSSD'**
  String get rmssdName;

  /// No description provided for @sdnnName.
  ///
  /// In en, this message translates to:
  /// **'SDNN'**
  String get sdnnName;

  /// No description provided for @daysAgoLong.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgoLong(int days);

  /// No description provided for @wordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String wordsCount(int count);

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @journalStamp.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}  {hour}:{minute}'**
  String journalStamp(
      int day, String month, int year, String hour, String minute);

  /// No description provided for @dayMonthYear.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}'**
  String dayMonthYear(int day, String month, int year);

  /// No description provided for @headphonesNote.
  ///
  /// In en, this message translates to:
  /// **'Binaural beats require stereo headphones to work.'**
  String get headphonesNote;

  /// No description provided for @attuneIntroKicker1.
  ///
  /// In en, this message translates to:
  /// **'Frequencies'**
  String get attuneIntroKicker1;

  /// No description provided for @attuneIntroTitle1.
  ///
  /// In en, this message translates to:
  /// **'Two tones, one in each ear'**
  String get attuneIntroTitle1;

  /// No description provided for @attuneIntroBody1.
  ///
  /// In en, this message translates to:
  /// **'A binaural beat is two steady tones. The left ear hears one frequency. The right ear hears a frequency a few hertz away. The pulse you notice is that difference. It is not a separate tone in the sound. Hearing builds it, and only when each ear receives its own tone.\n\nStereo headphones are required. Speakers, or a single earbud, let both tones into both ears. Then there is no binaural beat.\n\nIsochronic tones are the other choice. One tone is pulsed at the beat rate. They work on speakers, and they can feel sharper.'**
  String get attuneIntroBody1;

  /// No description provided for @attuneIntroKicker2.
  ///
  /// In en, this message translates to:
  /// **'Before you listen'**
  String get attuneIntroKicker2;

  /// No description provided for @attuneIntroTitle2.
  ///
  /// In en, this message translates to:
  /// **'Hemispheric sound is strong'**
  String get attuneIntroTitle2;

  /// No description provided for @attuneIntroBody2.
  ///
  /// In en, this message translates to:
  /// **'Each ear sends its tone along its own path. That split is what people mean by hemispheric synchronization. The bands name the beat rate, not a promise. Delta is about 2 Hz, theta about 6, alpha about 10, and beta about 20. The carrier, from 100 to 400 Hz, is the pitch you hear.\n\nThis app does not read your brain, and it does not place you in a state. Sit or lie down somewhere you can stop. Do not use this while driving, in water, or when your attention is needed elsewhere. Keep the volume comfortable. The sound rises over the first moment. Stop if you feel dizzy, tense, or unwell. If you have a history of seizures, skip this tool.'**
  String get attuneIntroBody2;

  /// No description provided for @attuneIntroFootnote.
  ///
  /// In en, this message translates to:
  /// **'This is not treatment, and it is not EMDR. The Anchor stays available.'**
  String get attuneIntroFootnote;

  /// No description provided for @attuneIntroUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get attuneIntroUnderstand;

  /// No description provided for @attuneIntroAgain.
  ///
  /// In en, this message translates to:
  /// **'About these frequencies'**
  String get attuneIntroAgain;

  /// No description provided for @attuneWaiverTitle.
  ///
  /// In en, this message translates to:
  /// **'Before the tones'**
  String get attuneWaiverTitle;

  /// No description provided for @attuneWaiverRecorded.
  ///
  /// In en, this message translates to:
  /// **'This choice is stored on this device.'**
  String get attuneWaiverRecorded;

  /// No description provided for @attuneWaiverSeizure.
  ///
  /// In en, this message translates to:
  /// **'I do not have a history of epilepsy or seizure disorders.'**
  String get attuneWaiverSeizure;

  /// No description provided for @attuneWaiverMachinery.
  ///
  /// In en, this message translates to:
  /// **'I will not operate heavy machinery or drive while listening.'**
  String get attuneWaiverMachinery;

  /// No description provided for @attuneWaiverRisk.
  ///
  /// In en, this message translates to:
  /// **'I assume all risks associated with brainwave entrainment, releasing the creators from liability regarding adverse psychiatric reactions.'**
  String get attuneWaiverRisk;

  /// No description provided for @attuneWaiverEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get attuneWaiverEnter;

  /// No description provided for @attuneCarouselAccept.
  ///
  /// In en, this message translates to:
  /// **'I Understand and Accept'**
  String get attuneCarouselAccept;

  /// No description provided for @attuneToneLevel.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get attuneToneLevel;

  /// No description provided for @attuneMaskLevel.
  ///
  /// In en, this message translates to:
  /// **'Mask'**
  String get attuneMaskLevel;

  /// No description provided for @attuneMaskWaiting.
  ///
  /// In en, this message translates to:
  /// **'A local recording can be added later. This slider stays quiet until then.'**
  String get attuneMaskWaiting;

  /// No description provided for @attuneMaskMusicNote.
  ///
  /// In en, this message translates to:
  /// **'Using your own music? Choose ambient tracks or classical music around 60 BPM. Fast or aggressive music will clash with the entrainment frequencies and may cause anxiety.'**
  String get attuneMaskMusicNote;

  /// No description provided for @attuneMaskNext.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get attuneMaskNext;

  /// No description provided for @attuneMaskTrackSpring.
  ///
  /// In en, this message translates to:
  /// **'Vivaldi, Spring'**
  String get attuneMaskTrackSpring;

  /// No description provided for @attuneMaskTrackSummer.
  ///
  /// In en, this message translates to:
  /// **'Vivaldi, Summer'**
  String get attuneMaskTrackSummer;

  /// No description provided for @attuneMaskTrackAutumn.
  ///
  /// In en, this message translates to:
  /// **'Vivaldi, Autumn'**
  String get attuneMaskTrackAutumn;

  /// No description provided for @attuneMaskTrackWinter.
  ///
  /// In en, this message translates to:
  /// **'Vivaldi, Winter'**
  String get attuneMaskTrackWinter;

  /// No description provided for @attuneMaskCredit.
  ///
  /// In en, this message translates to:
  /// **'Vivaldi, The Four Seasons, Op. 8. The Modena Chamber Orchestra. Public-domain recordings via Musopen.'**
  String get attuneMaskCredit;

  /// No description provided for @attunePickMusic.
  ///
  /// In en, this message translates to:
  /// **'Choose music'**
  String get attunePickMusic;

  /// No description provided for @attuneAddPack.
  ///
  /// In en, this message translates to:
  /// **'Add a pack from this device'**
  String get attuneAddPack;

  /// No description provided for @attuneIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get attuneIncluded;

  /// No description provided for @attunePackOnDevice.
  ///
  /// In en, this message translates to:
  /// **'This recording stays on this device.'**
  String get attunePackOnDevice;

  /// No description provided for @attunePackAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track added on this device} other{{count} tracks added on this device}}'**
  String attunePackAdded(int count);

  /// No description provided for @attunePackUnusable.
  ///
  /// In en, this message translates to:
  /// **'Name the zip with letters and numbers, then try again.'**
  String get attunePackUnusable;

  /// No description provided for @attunePackNotAPack.
  ///
  /// In en, this message translates to:
  /// **'That file is not a music pack.'**
  String get attunePackNotAPack;

  /// No description provided for @attunePackTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That pack is too large for this device.'**
  String get attunePackTooLarge;

  /// No description provided for @attunePackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Packs can be added in the Android app.'**
  String get attunePackUnavailable;

  /// No description provided for @attunePackSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'That file could not be saved on this device.'**
  String get attunePackSaveFailed;

  /// No description provided for @attuneFocus.
  ///
  /// In en, this message translates to:
  /// **'Slow shape'**
  String get attuneFocus;

  /// No description provided for @attuneDosageTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily limit'**
  String get attuneDosageTitle;

  /// No description provided for @attuneDosageBody.
  ///
  /// In en, this message translates to:
  /// **'Do not use this while driving or operating heavy machinery. A long listen can leave you drowsy. Recommended limit: 45 minutes a day.'**
  String get attuneDosageBody;

  /// No description provided for @attuneDosageToday.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute today} other{{minutes} minutes today}}'**
  String attuneDosageToday(int minutes);

  /// No description provided for @attuneDosageOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Past the daily limit'**
  String get attuneDosageOverTitle;

  /// No description provided for @attuneDosageOverBody.
  ///
  /// In en, this message translates to:
  /// **'You are past 45 minutes of Attune today. More listening can leave you drowsy or groggy.'**
  String get attuneDosageOverBody;

  /// No description provided for @attuneDosageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get attuneDosageContinue;

  /// No description provided for @physicsOpen.
  ///
  /// In en, this message translates to:
  /// **'The physics'**
  String get physicsOpen;

  /// No description provided for @physicsTitle.
  ///
  /// In en, this message translates to:
  /// **'How the sound works'**
  String get physicsTitle;

  /// No description provided for @physicsLead.
  ///
  /// In en, this message translates to:
  /// **'Two tones, and what they do not do.'**
  String get physicsLead;

  /// No description provided for @physicsHearingTitle.
  ///
  /// In en, this message translates to:
  /// **'The hearing barrier'**
  String get physicsHearingTitle;

  /// No description provided for @physicsHearingBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot hear a binaural beat as its own note in the room. One steady tone goes to the left ear. A second tone, a few hertz away, goes to the right ear. Hearing builds the pulse from that split, and only then.\n\nStereo headphones keep the tones apart. Speakers, or one earbud, let both tones into both ears. The barrier fails, and there is no binaural beat.'**
  String get physicsHearingBody;

  /// No description provided for @physicsCarrierTitle.
  ///
  /// In en, this message translates to:
  /// **'Carrier and beat'**
  String get physicsCarrierTitle;

  /// No description provided for @physicsCarrierBody.
  ///
  /// In en, this message translates to:
  /// **'The carrier is the pitch you hear. In this app it runs from 100 to 400 Hz. The beat is the difference between the ears, not a second sound added on top.\n\nThe band names that difference. Delta is about 2 Hz, theta about 6, alpha about 10, and beta about 20. Those are pulse rates. They are not a promise that you will enter a named brain state.'**
  String get physicsCarrierBody;

  /// No description provided for @physicsFollowingTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequency following response'**
  String get physicsFollowingTitle;

  /// No description provided for @physicsFollowingBody.
  ///
  /// In en, this message translates to:
  /// **'Frequency following response is a research name for brain activity that sometimes tracks a repeating sound. The evidence is mixed. It is clearer for some clicks and loudness pulses than for a quiet binaural beat.\n\nThis app does not read your brain. It does not measure a response, and it does not place you in a state. If the sound feels like too much, stop.'**
  String get physicsFollowingBody;

  /// No description provided for @physicsLampTitle.
  ///
  /// In en, this message translates to:
  /// **'Lamp and laser'**
  String get physicsLampTitle;

  /// No description provided for @physicsLampBody.
  ///
  /// In en, this message translates to:
  /// **'A lamp throws light in many directions. A laser holds one wavelength in step. Older writing used that contrast as a picture of scattered attention versus a narrow one.\n\nThe picture is not a measurement. MonkeyThrive does not turn the tone into a laser, and it does not steer the nervous system. Isochronic tones are different again: one tone, pulsed, which can feel sharper and does not need the two-ear split.'**
  String get physicsLampBody;

  /// No description provided for @physicsWarningKicker.
  ///
  /// In en, this message translates to:
  /// **'WARNING'**
  String get physicsWarningKicker;

  /// No description provided for @physicsWarning.
  ///
  /// In en, this message translates to:
  /// **'Do not drive or operate machinery while listening. The sound can make you drowsy or unsteady. It does not put you to sleep, and it does not override your nervous system. Stop if you feel dizzy, tense, or unwell. If you have a history of seizures, skip this tool.'**
  String get physicsWarning;

  /// No description provided for @frequencyBand.
  ///
  /// In en, this message translates to:
  /// **'Frequency band'**
  String get frequencyBand;

  /// No description provided for @carrierFrequency.
  ///
  /// In en, this message translates to:
  /// **'Carrier frequency'**
  String get carrierFrequency;

  /// No description provided for @hertz.
  ///
  /// In en, this message translates to:
  /// **'{hz} Hz'**
  String hertz(String hz);

  /// No description provided for @hertzBeat.
  ///
  /// In en, this message translates to:
  /// **'{hz} Hz beat'**
  String hertzBeat(String hz);

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get generating;

  /// No description provided for @natureSounds.
  ///
  /// In en, this message translates to:
  /// **'Nature sounds'**
  String get natureSounds;

  /// No description provided for @natureLayer.
  ///
  /// In en, this message translates to:
  /// **'Layer ambient sound over any tone, or use on its own.'**
  String get natureLayer;

  /// No description provided for @couldNotStartAudio.
  ///
  /// In en, this message translates to:
  /// **'Could not start audio. Try again.'**
  String get couldNotStartAudio;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @binauralShort.
  ///
  /// In en, this message translates to:
  /// **'Binaural'**
  String get binauralShort;

  /// No description provided for @isochronicShort.
  ///
  /// In en, this message translates to:
  /// **'Isochronic'**
  String get isochronicShort;

  /// No description provided for @binauralBeatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Binaural Beats — {band}'**
  String binauralBeatsTitle(String band);

  /// No description provided for @isochronicTonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Isochronic Tones — {band}'**
  String isochronicTonesTitle(String band);

  /// No description provided for @natureSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Nature Sound — {type}'**
  String natureSoundTitle(String type);

  /// No description provided for @bandDelta.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get bandDelta;

  /// No description provided for @bandTheta.
  ///
  /// In en, this message translates to:
  /// **'Theta'**
  String get bandTheta;

  /// No description provided for @bandAlpha.
  ///
  /// In en, this message translates to:
  /// **'Alpha'**
  String get bandAlpha;

  /// No description provided for @bandBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get bandBeta;

  /// No description provided for @rangeDelta.
  ///
  /// In en, this message translates to:
  /// **'0.5–4 Hz'**
  String get rangeDelta;

  /// No description provided for @rangeTheta.
  ///
  /// In en, this message translates to:
  /// **'4–8 Hz'**
  String get rangeTheta;

  /// No description provided for @rangeAlpha.
  ///
  /// In en, this message translates to:
  /// **'8–14 Hz'**
  String get rangeAlpha;

  /// No description provided for @rangeBeta.
  ///
  /// In en, this message translates to:
  /// **'14–30 Hz'**
  String get rangeBeta;

  /// No description provided for @useDelta.
  ///
  /// In en, this message translates to:
  /// **'Deep sleep · Recovery'**
  String get useDelta;

  /// No description provided for @useTheta.
  ///
  /// In en, this message translates to:
  /// **'Deep relaxation · Processing'**
  String get useTheta;

  /// No description provided for @useAlpha.
  ///
  /// In en, this message translates to:
  /// **'Calm focus · Grounded'**
  String get useAlpha;

  /// No description provided for @useBeta.
  ///
  /// In en, this message translates to:
  /// **'Alert · Present'**
  String get useBeta;

  /// No description provided for @noiseRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get noiseRain;

  /// No description provided for @noiseOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get noiseOcean;

  /// No description provided for @noiseForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get noiseForest;

  /// No description provided for @noiseRiver.
  ///
  /// In en, this message translates to:
  /// **'River'**
  String get noiseRiver;

  /// No description provided for @noiseThunder.
  ///
  /// In en, this message translates to:
  /// **'Thunder'**
  String get noiseThunder;

  /// No description provided for @noiseWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get noiseWind;

  /// No description provided for @messagesStillOnScreen.
  ///
  /// In en, this message translates to:
  /// **'The messages app did not open. The number is still on this screen.'**
  String get messagesStillOnScreen;

  /// No description provided for @phoneStillOnScreen.
  ///
  /// In en, this message translates to:
  /// **'The phone app did not open. The number is still on this screen for you to dial.'**
  String get phoneStillOnScreen;

  /// No description provided for @textKeywordTo.
  ///
  /// In en, this message translates to:
  /// **'Text {keyword} to {number}'**
  String textKeywordTo(String keyword, String number);

  /// No description provided for @notACopy.
  ///
  /// In en, this message translates to:
  /// **'This is not a MonkeyThrive copy.'**
  String get notACopy;

  /// No description provided for @copyUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This copy could not be read.'**
  String get copyUnreadable;

  /// No description provided for @copyNewer.
  ///
  /// In en, this message translates to:
  /// **'This copy is from a newer version.'**
  String get copyNewer;

  /// No description provided for @passphraseWrong.
  ///
  /// In en, this message translates to:
  /// **'That passphrase did not open this copy.'**
  String get passphraseWrong;

  /// No description provided for @passphraseMin.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters.'**
  String passphraseMin(int count);

  /// No description provided for @suggestionSit.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling overwhelmed right now. Could you sit with me or send a quiet check-in? No need to fix anything.'**
  String get suggestionSit;

  /// No description provided for @suggestionRough.
  ///
  /// In en, this message translates to:
  /// **'Having a rough moment and grounding myself. Just letting you know so I\'m not alone.'**
  String get suggestionRough;

  /// No description provided for @personWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from this device.'**
  String personWillBeRemoved(String name);

  /// No description provided for @notReally.
  ///
  /// In en, this message translates to:
  /// **'🙁  Not really'**
  String get notReally;

  /// No description provided for @baselineBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get baselineBox;

  /// No description provided for @acousticMessage.
  ///
  /// In en, this message translates to:
  /// **'Deterministic acoustic synthesis is undergoing calibration to prevent sudden sensory triggers. Available in a future release.'**
  String get acousticMessage;

  /// No description provided for @generalCategory.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalCategory;

  /// No description provided for @countTimes.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String countTimes(int count);

  /// No description provided for @accentTeal.
  ///
  /// In en, this message translates to:
  /// **'teal'**
  String get accentTeal;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get accentGreen;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'blue'**
  String get accentBlue;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'amber'**
  String get accentAmber;

  /// No description provided for @bilateralSupport.
  ///
  /// In en, this message translates to:
  /// **'between-session support, not therapy'**
  String get bilateralSupport;

  /// No description provided for @journaling.
  ///
  /// In en, this message translates to:
  /// **'Journaling'**
  String get journaling;

  /// No description provided for @panicTool.
  ///
  /// In en, this message translates to:
  /// **'Panic / Physiological Sigh'**
  String get panicTool;

  /// No description provided for @sighTracked.
  ///
  /// In en, this message translates to:
  /// **'Physiological Sigh'**
  String get sighTracked;

  /// No description provided for @wimHofTracked.
  ///
  /// In en, this message translates to:
  /// **'Wim Hof'**
  String get wimHofTracked;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get clearAllData;

  /// No description provided for @attuneType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get attuneType;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String hoursShort(int hours);

  /// No description provided for @clock.
  ///
  /// In en, this message translates to:
  /// **'{minutes}:{seconds}'**
  String clock(String minutes, String seconds);

  /// No description provided for @crisisEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get crisisEmergency;

  /// No description provided for @crisisSupportLine.
  ///
  /// In en, this message translates to:
  /// **'Support line'**
  String get crisisSupportLine;

  /// No description provided for @crisisWhereYouAre.
  ///
  /// In en, this message translates to:
  /// **'Where you are'**
  String get crisisWhereYouAre;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
