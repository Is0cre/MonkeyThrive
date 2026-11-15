// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MonkeyThrive';

  @override
  String get navRegulate => 'Regulate';

  @override
  String get navAttune => 'Attune';

  @override
  String get navMonitor => 'Monitor';

  @override
  String get navBuild => 'Build';

  @override
  String get navReflect => 'Reflect';

  @override
  String get navProcess => 'Process';

  @override
  String get anchorLabel => 'Anchor';

  @override
  String get checkinTitle => 'how are you\nright now?';

  @override
  String get checkinHint =>
      'Tap where the body is speaking. Tap again to change it. This shapes what is available.';

  @override
  String readingAs(String state) {
    return 'this reads as $state';
  }

  @override
  String get nothingStandsOut => 'nothing stands out';

  @override
  String get continueLabel => 'continue';

  @override
  String get tight => 'tight';

  @override
  String get heavy => 'heavy';

  @override
  String get unmarked => 'unmarked';

  @override
  String get stateOverwhelmed => 'overwhelmed';

  @override
  String get statePresent => 'present';

  @override
  String get stateFlat => 'flat or numb';

  @override
  String get lockedWhenOverwhelmed => 'not available when overwhelmed';

  @override
  String get lockedWhenFlat => 'not available when flat';

  @override
  String get bodyMasculine => 'Masculine';

  @override
  String get bodyFeminine => 'Feminine';

  @override
  String get bodyNeutral => 'Neutral';

  @override
  String get zoneHead => 'Head';

  @override
  String get zoneThroat => 'Throat';

  @override
  String get zoneChest => 'Chest';

  @override
  String get zoneStomach => 'Stomach';

  @override
  String get feelingBetterQuestion => 'Are you feeling better?';

  @override
  String get yes => 'Yes';

  @override
  String get notYet => 'Not yet';

  @override
  String get readingStays => 'The reading stays as it is.';

  @override
  String get markedPresent => 'Marked as present.';

  @override
  String get stillMarkedPresent => 'Still marked as present.';

  @override
  String get readingNotSaved => 'The reading could not be saved.';

  @override
  String get boxBreathingTitle => 'Box Breathing';

  @override
  String get breathing478Title => '4-7-8 Breathing';

  @override
  String get breathingBegin => 'Begin';

  @override
  String get breathingPause => 'Pause';

  @override
  String get breathHapticsOn => 'Vibration pace on';

  @override
  String get breathHapticsOff => 'Vibration pace off';

  @override
  String get breathingResume => 'Resume';

  @override
  String get breathingCycles => 'Cycles';

  @override
  String breathingCycle(int current, int total) {
    return 'Cycle $current of $total';
  }

  @override
  String get anotherRound => 'Another round';

  @override
  String get inhale => 'Inhale';

  @override
  String get hold => 'Hold';

  @override
  String get exhale => 'Exhale';

  @override
  String get breathing478NeedsCheckin =>
      'Check in before using 4-7-8 breathing.';

  @override
  String breathing478Locked(String reason) {
    return '4-7-8 breathing is $reason.';
  }

  @override
  String get regulateSubtitle =>
      'Immediate tools for the state you are in now.';

  @override
  String get sectionBreathing => 'Breathing';

  @override
  String get sectionGrounding => 'Grounding';

  @override
  String get sectionVagal => 'Vagal nerve activation';

  @override
  String get boxBreathingSubtitle => '4-4-4-4 · Calm the nervous system';

  @override
  String get sighTitle => 'Physiological sigh';

  @override
  String get sighSubtitle => 'Double inhale + long exhale · Fastest reset';

  @override
  String get breathing478Subtitle => 'Sleep & acute anxiety';

  @override
  String get wimHofTitle => 'Wim Hof Breathing';

  @override
  String get wimHofSubtitle => 'Guided round protocol';

  @override
  String get groundingTitle => '5-4-3-2-1 Grounding';

  @override
  String get groundingSubtitle => 'Sensory anchoring — bring yourself back';

  @override
  String get coldWaterTitle => 'Cold Water';

  @override
  String get coldWaterSubtitle => 'Diving reflex · Vagal activation';

  @override
  String get safePlaceTitle => 'Safe Place';

  @override
  String get safePlaceSubtitle => 'Guided visualisation with ambient sound';

  @override
  String get vagalTitle => 'Vagal Prompts';

  @override
  String get vagalSubtitle => 'Humming · Gargling · Extended exhale';

  @override
  String get sighCueIn => 'breathe in through your nose';

  @override
  String get sighCueSniff => 'one more sniff';

  @override
  String get sighCueOut => 'breathe out slowly';

  @override
  String get sighDone => 'done';

  @override
  String get sighAgain => 'again';

  @override
  String get sighPhaseLabel => 'Double inhale, long exhale';

  @override
  String get youAreHere => 'you\'re here.';

  @override
  String get takeYourTime => 'take your time.';

  @override
  String get goToRegulate => 'go to regulate';

  @override
  String get callCrisisLine => 'call a crisis line';

  @override
  String get leave => 'Leave';

  @override
  String get youAreHereSentence => 'You are here.';

  @override
  String get finish => 'Finish';

  @override
  String get next => 'Next';

  @override
  String get complete => 'Complete';

  @override
  String get back => 'Back';

  @override
  String get humming => 'Humming';

  @override
  String get gargling => 'Gargling';

  @override
  String get extendedExhale => 'Extended Exhale';

  @override
  String get divingReflex => 'Diving Reflex';

  @override
  String get vagalScreenTitle => 'Vagal Nerve Activation';

  @override
  String get done => 'Done';

  @override
  String safePlaceLocked(String reason) {
    return 'Safe place is $reason.';
  }

  @override
  String get duration => 'Duration';

  @override
  String get beginVisualisation => 'Begin visualisation';

  @override
  String get endSession => 'End session';

  @override
  String get safePlaceHint =>
      'A quiet beach, a childhood room, a forest clearing…';

  @override
  String get customiseSafePlace => 'Customise your safe place';

  @override
  String get wimHofOnlyWhenPresent =>
      'Wim Hof breathing is only available when present.';

  @override
  String get wimHofChecksFirst => 'Complete the safety checks before starting.';

  @override
  String get wimHofWarning =>
      'Never practice in water or while driving. Stop if you feel unwell.';

  @override
  String roundNumber(int round) {
    return 'Round $round';
  }

  @override
  String roundComplete(int round) {
    return 'Round $round complete';
  }

  @override
  String get exhaleAndHold => 'Exhale & Hold';

  @override
  String get recoveryBreath => 'Recovery Breath';

  @override
  String get retentionHold => 'Retention Hold';

  @override
  String get readyRecovery => 'I\'m ready — recovery breath';

  @override
  String get release => 'Release';

  @override
  String get nextRound => 'Next round';

  @override
  String get thirtyBreaths => '30 Deep Breaths';

  @override
  String get thirtyBreathsBody =>
      'Breathe in fully, let go without forcing. After 30 breaths, exhale and hold only as long as comfortable.';

  @override
  String get wimHofCheck1 => 'I am not in water, driving, or standing.';

  @override
  String get wimHofCheck2 => 'I am lying down or seated somewhere safe.';

  @override
  String get wimHofCheck3 => 'I do not have a seizure disorder.';

  @override
  String get wimHofCheck4 =>
      'I do not have a serious heart, blood pressure, or respiratory condition.';

  @override
  String get wimHofCheck5 => 'I am not pregnant.';

  @override
  String get wimHofCheck6 =>
      'If this is my first time, another person is nearby.';

  @override
  String get wimHofCheck7 => 'I will stop immediately if I feel unwell.';

  @override
  String get onboardingKicker1 => 'Taming the storm';

  @override
  String get onboardingTitle1 => 'Tame the Storm';

  @override
  String get onboardingBody1 =>
      'The nervous system can feel like weather you did not choose. Taming it means learning the shape of that weather: when to slow down, when to stay, and when a tool stays closed. Like Sun Wukong learning to hold his own chaos, this is practice in self-regulation.';

  @override
  String get onboardingKicker2 => 'On this device';

  @override
  String get onboardingTitle2 => 'Zero Tracking. Zero Guilt.';

  @override
  String get onboardingBody2 =>
      'Check-ins, journal entries, and sensor readings stay on this device. There is no account, no streak, and no score for the days you were away. Nothing here is sent or sold.';

  @override
  String get onboardingCare =>
      'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy. If you are in immediate danger, contact emergency services.';

  @override
  String get continueAction => 'Continue';

  @override
  String get anchorBaseline => 'Anchor your baseline';

  @override
  String get wukongLabel => 'Sun Wukong in red and gold, holding a phone.';

  @override
  String pageLabel(int page) {
    return 'Page $page';
  }

  @override
  String get processSubtitle => 'Deeper work. Use when regulated and ready.';

  @override
  String get processCaution =>
      'These tools are for processing, not crisis. Make sure you feel regulated before starting.';

  @override
  String get bilateralTitle => 'Bilateral Stimulation';

  @override
  String get eftTapping => 'EFT Tapping';

  @override
  String get somaticScan => 'Somatic Body Scan';

  @override
  String get traumaJournal => 'Trauma-informed Journaling';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get bilateralOnlyWhenPresent =>
      'Bilateral stimulation is only available when present.';

  @override
  String get sessionComplete => 'Session complete';

  @override
  String get sessionCompleteBody =>
      'Take a moment. Notice what came up, if anything.\n\nThere is no right way to feel.';

  @override
  String get close => 'Close';

  @override
  String get settings => 'Settings';

  @override
  String get beginSession => 'Begin session';

  @override
  String get mode => 'Mode';

  @override
  String get speed => 'Speed';

  @override
  String get sessionLength => 'Session length';

  @override
  String get dotSize => 'Dot size';

  @override
  String get dotColour => 'Dot colour';

  @override
  String get visual => 'Visual';

  @override
  String get audio => 'Audio';

  @override
  String get tactile => 'Tactile';

  @override
  String get visualAudio => 'Visual + Audio';

  @override
  String get visualTactile => 'Visual + Tactile';

  @override
  String get visualAudioTactile => 'Visual + Audio + Tactile';

  @override
  String get slow => 'Slow';

  @override
  String get medium => 'Medium';

  @override
  String get fast => 'Fast';

  @override
  String get visualOnly => 'Visual only';

  @override
  String get audioOnly => 'Audio only';

  @override
  String get tactileOnly => 'Tactile only';

  @override
  String get allThree => 'All three';

  @override
  String get open => 'Open';

  @override
  String minutesShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String get bilateralCare =>
      'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy.\nBilateral stimulation — between-session support, not therapy.';

  @override
  String get attuneSubtitle => 'Generated sound tools for steady attention.';

  @override
  String get binauralBeats => 'Binaural beats';

  @override
  String get isochronicTones => 'Isochronic tones';

  @override
  String get natureSoundscapes => 'Nature soundscapes';

  @override
  String get monitorSubtitle => 'Check in with your nervous system.';

  @override
  String get hrvTitle => 'Heart rate variability';

  @override
  String get hrvTap => 'Tap to measure via camera';

  @override
  String get hyperarousal => 'Hyperarousal';

  @override
  String get windowOfTolerance => 'Window of tolerance';

  @override
  String get hypoarousal => 'Hypoarousal';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get noCamera => 'No camera found';

  @override
  String get noCameraBody => 'Camera PPG requires a rear camera with flash.';

  @override
  String get cameraDenied => 'Camera access denied';

  @override
  String get cameraDeniedBody =>
      'Allow camera access in your device settings to use this feature.';

  @override
  String get measurementFailed => 'Measurement failed';

  @override
  String get measurementFailedBody =>
      'Not enough signal detected. Make sure your fingertip firmly covers the camera and flash.';

  @override
  String get measureIn60 => 'Measure in 60 seconds';

  @override
  String get hrvInstructions =>
      'Place your fingertip firmly over the rear camera and flash. Stay still. Results are stored on this device only.';

  @override
  String get coverLens =>
      'Cover both the camera lens and the flash with your fingertip.';

  @override
  String get stayStill =>
      'Stay as still as possible. Motion creates noise in the signal.';

  @override
  String get notAMedicalDevice =>
      'Not a medical device. For self-awareness only.';

  @override
  String get notAMedicalDeviceShort => 'Not a medical device.';

  @override
  String get startMeasurement => 'Start measurement';

  @override
  String get signalDetected => 'signal detected';

  @override
  String get placeFinger => 'place finger on camera + flash';

  @override
  String get waitingForSignal => 'waiting for signal…';

  @override
  String get stopAndCalculate => 'Stop and calculate';

  @override
  String get yourReading => 'Your reading';

  @override
  String basedOnHeartbeats(int count) {
    return 'Based on $count heartbeats · not a medical device';
  }

  @override
  String get heartRate => 'Heart rate';

  @override
  String get hrvTrend =>
      'HRV is most meaningful as a trend over time, not a single reading. Compare against your own baseline, not population averages.';

  @override
  String get measureAgain => 'Measure again';

  @override
  String get goBack => 'Go back';

  @override
  String get buildSubtitle =>
      'A private space to write. Nothing leaves this device.';

  @override
  String get nothingWritten =>
      'Nothing written yet.\n\nTap the pencil when you\'re ready.';

  @override
  String get newEntry => 'New entry';

  @override
  String get deleteEntryTitle => 'Delete this entry?';

  @override
  String get cannotBeUndone => 'This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String get emptyEntry => 'empty entry';

  @override
  String get journalHint => 'write here…';

  @override
  String get saved => 'saved';

  @override
  String get prompt => 'prompt';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get prompt1 => 'what are you noticing right now?';

  @override
  String get prompt2 => 'what does your body need today?';

  @override
  String get prompt3 =>
      'is there something you want to put down somewhere safe?';

  @override
  String get prompt4 => 'what felt okay today, even if small?';

  @override
  String get prompt5 => 'is there something you\'ve been carrying?';

  @override
  String get prompt6 => 'you don\'t have to make it make sense. just write.';

  @override
  String get prompt7 => 'what\'s present for you right now?';

  @override
  String get prompt8 =>
      'what would you say to yourself if you were being kind?';

  @override
  String get reflectSubtitle => 'a record of what you\'ve explored.';

  @override
  String get vaultCreateLead => 'Choose a 6-digit key for Reflect.';

  @override
  String get vaultConfirmLead => 'Enter the same key again.';

  @override
  String get vaultEnterLead => 'Enter your key to open Reflect.';

  @override
  String get vaultMismatch => 'Those keys did not match.';

  @override
  String get vaultWrong => 'That key did not open this vault.';

  @override
  String get vaultShort => 'Use 6 digits.';

  @override
  String get vaultJournalLocked => 'The journal is locked.';

  @override
  String get vaultUnlock => 'Unlock';

  @override
  String get vaultDeleteDigit => 'Delete';

  @override
  String get vaultCopyLocked => 'Unlock Reflect before copying this record.';

  @override
  String get vaultUnread => 'The vault could not be read on this device.';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get reflectEmpty =>
      'Nothing here yet.\n\nUse a few tools and come back.';

  @override
  String get timeWithEachArea => 'time with each area';

  @override
  String get whatYouReachedFor => 'what you\'ve reached for';

  @override
  String get statesPast35 => 'YOUR STATES — PAST 35 DAYS';

  @override
  String get noCheckIn => 'no check-in';

  @override
  String get flatShort => 'flat';

  @override
  String get noData => 'no data';

  @override
  String get crisisSupport => 'Crisis support';

  @override
  String get crisisDanger =>
      'If you are in immediate danger, call the emergency number for where you are.';

  @override
  String get country => 'Country';

  @override
  String get searchNameOrNumber => 'Search name or number';

  @override
  String get noLinesStored =>
      'No lines are stored for this country. Choose International for what to do next.';

  @override
  String get supportLines => 'Support lines';

  @override
  String get noSupportMatch =>
      'No support lines match that search. The emergency number stays listed above.';

  @override
  String get somewhereElse =>
      'Somewhere else? Choose International in the country list.';

  @override
  String get crisisDisclaimer =>
      'These directories are stored completely offline on your device. Calls route through your cellular provider and standard carrier rates or calling rules apply.';

  @override
  String get numberCopied => 'Number copied';

  @override
  String get copyNumber => 'Copy number';

  @override
  String dialsNumber(String number) {
    return 'Dials $number';
  }

  @override
  String get sendThisText => 'Send this text?';

  @override
  String get callThisNumber => 'Call this number?';

  @override
  String get message => 'Message';

  @override
  String get textOpensApp =>
      'This opens your messages app with the text ready. This app does not send it or use the internet.';

  @override
  String get callOpensDialer =>
      'This opens your phone dialer with the number ready. This app does not place the call or use the internet.';

  @override
  String textNumber(String number) {
    return 'Text $number';
  }

  @override
  String callNumber(String number) {
    return 'Call $number';
  }

  @override
  String get trustedPerson => 'Trusted person';

  @override
  String get saveTrustedPerson => 'Save a trusted person';

  @override
  String get editTrustedPeople => 'Edit trusted people';

  @override
  String get trustedWhenPresent =>
      'A trusted person can be saved when the reading is present.';

  @override
  String get trustedSavedWhenPresent =>
      'This can be saved when the reading is present.';

  @override
  String get availableWhenPresent => 'Available when the reading is present.';

  @override
  String get savedTextOnDevice => 'A saved text, kept on this device.';

  @override
  String get savedOnDevice => 'Saved on this device.';

  @override
  String get trustedPrivacy =>
      'Saved on this device. Text and call open your phone\'s own apps. Nothing is sent from here.';

  @override
  String get addAnotherPerson => 'Add another person';

  @override
  String get name => 'Name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get keep => 'Keep';

  @override
  String get removeThisPerson => 'Remove this person?';

  @override
  String get numberWillBeRemoved =>
      'The saved number will be removed from this device.';

  @override
  String get addAName => 'Add a name.';

  @override
  String get shorterName => 'Use a shorter name.';

  @override
  String get phoneNeedsDigits =>
      'Use a phone number, with the country code if it needs one.';

  @override
  String get addAMessage => 'Add a short message.';

  @override
  String messageTooLong(int limit) {
    return 'Keep the message to $limit characters.';
  }

  @override
  String get numberCannotOpen => 'That number cannot be opened from here.';

  @override
  String get messagesDidNotOpen => 'The messages app did not open.';

  @override
  String get phoneDidNotOpen => 'The phone app did not open.';

  @override
  String textPerson(String name) {
    return 'Text $name';
  }

  @override
  String callPerson(String name) {
    return 'Call $name';
  }

  @override
  String get sitWithMe => 'Sit with me';

  @override
  String get justLettingYouKnow => 'Just letting you know';

  @override
  String get clearAllDataTitle => 'Clear all data?';

  @override
  String get clearAllDataBody =>
      'This will permanently delete:\n\n• Journal entries\n• HRV readings\n• Check-in history\n• Baseline feedback history\n• Session log\n• Safe place description\n• Trusted people\n\nThis cannot be undone.';

  @override
  String get clearAll => 'Clear all';

  @override
  String get allDataCleared => 'All data cleared.';

  @override
  String get checkinAlreadyOpen => 'A check-in is already open.';

  @override
  String get about => 'About';

  @override
  String get builtFromLivedExperience =>
      'Built from lived experience.\nFor everyone who is still here.';

  @override
  String get openSourceLine =>
      'Open source · No ads · No data collection · Free forever.';

  @override
  String get appearance => 'Appearance';

  @override
  String get safety => 'Safety';

  @override
  String get crisisDirectoryLabel => 'Crisis support directory';

  @override
  String get crisisDirectorySubtitle =>
      'Offline helplines by country. Stays on this device.';

  @override
  String get showBaseline => 'Show baseline check-in';

  @override
  String get showBaselineSubtitle => 'Preview the local prompt implementation';

  @override
  String get privacy => 'Privacy';

  @override
  String get entriesStay => 'Your entries stay on this device.';

  @override
  String get privacyBody =>
      'Zero network requests. Zero analytics. Zero crash reporting. Everything you enter — check-ins, journal entries, HRV readings, your safe place description, and trusted people — is stored only on this device.\n\nWe cannot provide your data to anyone because we do not have it.';

  @override
  String get journalDeviceOnly => 'Journal entries — device only';

  @override
  String get hrvDeviceOnly => 'HRV readings — device only';

  @override
  String get checkinDeviceOnly => 'Check-in history — device only';

  @override
  String get sessionDeviceOnly => 'Session log — device only';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get settingsDisclaimer =>
      'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy, and does not diagnose, assess, or treat any condition.\n\nIf you are in crisis, please reach out to a professional or use the crisis resources listed above.';

  @override
  String get yourData => 'Your data';

  @override
  String get exportSubtitle => 'Passphrase-sealed file on this device';

  @override
  String get importSubtitle => 'Restore a sealed copy onto this device';

  @override
  String get clearAllSubtitle =>
      'Journal, HRV, check-ins, session log, safe place';

  @override
  String get redoOnboarding => 'Redo onboarding';

  @override
  String get redoOnboardingSubtitle => 'Reset your profile questionnaire';

  @override
  String get redoOnboardingTitle => 'Redo onboarding?';

  @override
  String get redoOnboardingBody =>
      'Your profile will be reset and you\'ll go through the questionnaire again. Your history is not affected.';

  @override
  String get reset => 'Reset';

  @override
  String get accent => 'Accent';

  @override
  String get contrast => 'Contrast';

  @override
  String get contrastSoft => 'Soft';

  @override
  String get contrastStandard => 'Standard';

  @override
  String get contrastHigh => 'High';

  @override
  String get passphrasesDoNotMatch => 'The two passphrases do not match.';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get repeatPassphrase => 'Repeat passphrase';

  @override
  String get exportBody =>
      'The copy is sealed with a passphrase you choose. MonkeyThrive does not keep that passphrase and cannot open the copy without it. Nothing is uploaded.';

  @override
  String get exportKeep =>
      'Keep this copy somewhere you control. Opening it on another device needs the same passphrase.';

  @override
  String savedAs(String name) {
    return 'Saved: $name';
  }

  @override
  String get sealing => 'Sealing';

  @override
  String get createCopy => 'Create copy';

  @override
  String get saveFileAndCopy => 'Save file and copy';

  @override
  String get copyRestored => 'Copy restored on this device.';

  @override
  String get importBody =>
      'This replaces the journal, check-ins, session log, trusted people, and preferences on this device. It does not contact a server.';

  @override
  String get pasteTheCopy => 'Paste the copy';

  @override
  String get restoring => 'Restoring';

  @override
  String get restore => 'Restore';

  @override
  String get howAreYouDoing => 'How are you doing?';

  @override
  String get baselineDifferent =>
      'I noticed things look a little different from your usual baseline.';

  @override
  String get imOkay => '🙂  I\'m okay';

  @override
  String get wouldOneHelp => 'Would one of these help?';

  @override
  String get sigh => 'Sigh';

  @override
  String get ground => 'Ground';

  @override
  String get vagal => 'Vagal';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get coldHow => 'How this works';

  @override
  String get coldBody =>
      'Cold water activates the diving reflex — your body\'s built-in emergency brake. It slows your heart rate and activates the vagus nerve within seconds.\n\nApply cold water to your face, wrists, or the back of your neck.';

  @override
  String get coldFace => 'Splash cold water on your face';

  @override
  String get coldWrists => 'Hold cold water on your wrists';

  @override
  String get coldNeck => 'Cold cloth on the back of your neck';

  @override
  String get good => 'Good.';

  @override
  String get alreadyResponding => 'Your nervous system is already responding.';

  @override
  String get seconds => 'seconds';

  @override
  String get againLabel => 'Again';

  @override
  String get running => 'Running…';

  @override
  String get start30 => 'Start 30s timer';

  @override
  String startSecondsTimer(int seconds) {
    return 'Start ${seconds}s timer';
  }

  @override
  String secondsTimer(int seconds) {
    return '${seconds}s timer';
  }

  @override
  String get wimHofLetGo => 'breathe in · let go';

  @override
  String get wimHofExhaleBody =>
      'Let all the air out and hold. Do not force it. Hold as long as comfortable.';

  @override
  String get wimHofRecoveryBody =>
      'Take one deep breath in and hold for 15 seconds.';

  @override
  String get wimHofStillness => 'Hold. Feel the stillness.';

  @override
  String get wimHofRoundRest =>
      'Rest for a moment before your next round, or finish here.';

  @override
  String timerClock(int minutes, String seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String timerSecondsOnly(int seconds) {
    return '${seconds}s';
  }

  @override
  String breathFraction(int current, int total) {
    return '$current / $total';
  }

  @override
  String get sighIntro =>
      'Double inhale through the nose, then a long slow exhale. One of the fastest ways to calm your nervous system.';

  @override
  String get sighRounds => 'ROUNDS';

  @override
  String get sighBegin => 'begin';

  @override
  String get sighPause => 'pause';

  @override
  String get sighResume => 'resume';

  @override
  String get senseSee => 'See';

  @override
  String get senseHear => 'Hear';

  @override
  String get senseTouch => 'Touch';

  @override
  String get senseSmell => 'Smell';

  @override
  String get senseTaste => 'Taste';

  @override
  String get groundSee =>
      'Look around you. Find 5 things you can see right now.\n\nTake your time. Notice each one clearly — colour, shape, texture.';

  @override
  String get groundHear =>
      'Close your eyes if that feels safe. Find 4 things you can hear.\n\nNear and far. Notice the sounds without judgement.';

  @override
  String get groundTouch =>
      'Find 3 things you can feel right now — the chair beneath you, the fabric on your skin, the air temperature.\n\nPress your feet into the floor if that helps.';

  @override
  String get groundSmell =>
      'Find 2 things you can smell, or remember scents that feel safe and familiar to you.\n\nTake a slow breath in through your nose.';

  @override
  String get groundTaste =>
      'Notice 1 thing you can taste, or take a sip of water if you have some.\n\nYou are here. You are safe.';

  @override
  String groundCount(int count, String sense) {
    return '$count things you can $sense';
  }

  @override
  String get groundBroughtBack =>
      'You just brought yourself back with your own senses. That is the skill — and you have it.';

  @override
  String get youAreSafe => 'You are here. You are safe.';

  @override
  String get vagalIntro =>
      'The vagus nerve is your body\'s main pathway to calm. These techniques activate it directly.';

  @override
  String get hummingWhy =>
      'Humming creates vibrations that directly stimulate the vagus nerve through the larynx. Even 2 minutes can measurably shift your state.';

  @override
  String get hummingHow =>
      'Find a comfortable note and hum steadily. Feel the vibration in your chest and throat. Let the exhale extend naturally as you hum.';

  @override
  String get garglingWhy =>
      'Gargling activates muscles at the back of the throat that are connected to the vagus nerve. 30 seconds is enough to notice a shift.';

  @override
  String get garglingHow =>
      'Take a mouthful of water and gargle vigorously for as long as comfortable. Repeat 2-3 times.';

  @override
  String get extendedWhy =>
      'The exhale activates the parasympathetic nervous system. Making your exhale twice as long as your inhale slows the heart rate and signals safety to your body.';

  @override
  String get extendedHow =>
      'Breathe in for 4 counts. Breathe out slowly for 8 counts. There is no hold — just a long, steady out-breath. Repeat as many times as you need.';

  @override
  String get divingWhy =>
      'Submerging your face in cold water (or splashing it) triggers the mammalian diving reflex — your heart rate slows within seconds. It is one of the fastest calming signals your body responds to.';

  @override
  String get divingHow =>
      'Fill a bowl or sink with cold water. Hold your breath and submerge your face for 15-30 seconds, or splash cold water repeatedly over your face and forehead.';

  @override
  String get breathingGuide => 'Breathing guide';

  @override
  String vagalToolTitle(String title) {
    return 'Vagal — $title';
  }

  @override
  String get whyThisWorks => 'WHY THIS WORKS';

  @override
  String get safePlaceDefault =>
      'Think of a place — real or imagined — where you feel completely safe. It might be a room, a landscape, a memory. It belongs only to you.';

  @override
  String get safePrompt1 =>
      'Settle in. There is nowhere you need to be right now.\n\nLet your breathing slow naturally.';

  @override
  String get safePrompt2 =>
      'Bring your safe place to mind. Allow yourself to arrive there.';

  @override
  String get safePrompt3 =>
      'Notice what you can see. The colours, the light, the shapes around you.';

  @override
  String get safePrompt4 =>
      'What sounds are here? Gentle, familiar sounds that belong to this place.';

  @override
  String get safePrompt5 =>
      'Feel the temperature. The air on your skin. The ground beneath you.';

  @override
  String get safePrompt6 =>
      'You are safe here. Nothing can reach you in this place.';

  @override
  String get safePrompt7 =>
      'Stay as long as you need. This place is always available to you.\n\nYou can return here any time you close your eyes.';

  @override
  String get safePlaceNeedsCheckin => 'Check in before using safe place.';

  @override
  String get yourSafePlace => 'Your safe place';

  @override
  String get describeSafePlace => 'Describe your safe place';

  @override
  String get safePlaceStored =>
      'This is stored only on your device. Write whatever feels right — it only needs to make sense to you.';

  @override
  String get breathing478Caution =>
      '4-7-8 breathing is very effective for acute anxiety and sleep. If you feel dizzy, stop and breathe normally.';

  @override
  String get howAreYouNow => 'How are you right now?';

  @override
  String get recentCheckins => 'Recent check-ins';

  @override
  String get toolsUsedRecently => 'Tools used recently';

  @override
  String get noHistory =>
      'No history yet.\nStart using tools and check back here.';

  @override
  String hrvSummary(int hr, int rmssd) {
    return '$hr bpm  ·  RMSSD $rmssd ms';
  }

  @override
  String get windowHeading => 'WINDOW OF TOLERANCE';

  @override
  String get hyperNote => 'Anxiety · Panic · Overwhelm';

  @override
  String get regulatedNote => 'Regulated · Processing possible';

  @override
  String get hypoNote => 'Numbness · Shutdown · Dissociation';

  @override
  String get checkInBelow => 'Check in below to log where you are.';

  @override
  String get labelOverwhelmed => 'Overwhelmed';

  @override
  String get labelPresent => 'Present';

  @override
  String get labelFlat => 'Flat';

  @override
  String durationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String dateSlash(int day, int month) {
    return '$day/$month';
  }

  @override
  String get noBackCamera => 'No back camera';

  @override
  String get hrvMeasurement => 'HRV Measurement';

  @override
  String get hrvGoodRecovery => 'good recovery';

  @override
  String get hrvModerate => 'moderate';

  @override
  String get hrvLow => 'low — rest or regulate';

  @override
  String get overallVariability => 'overall variability';

  @override
  String get bpm => 'bpm';

  @override
  String get msUnit => 'ms';

  @override
  String get rmssdName => 'RMSSD';

  @override
  String get sdnnName => 'SDNN';

  @override
  String daysAgoLong(int days) {
    return '$days days ago';
  }

  @override
  String wordsCount(int count) {
    return '$count words';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String journalStamp(
      int day, String month, int year, String hour, String minute) {
    return '$day $month $year  $hour:$minute';
  }

  @override
  String dayMonthYear(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String get headphonesNote =>
      'Binaural beats require stereo headphones to work.';

  @override
  String get attuneIntroKicker1 => 'Frequencies';

  @override
  String get attuneIntroTitle1 => 'Two tones, one in each ear';

  @override
  String get attuneIntroBody1 =>
      'A binaural beat is two steady tones. The left ear hears one frequency. The right ear hears a frequency a few hertz away. The pulse you notice is that difference. It is not a separate tone in the sound. Hearing builds it, and only when each ear receives its own tone.\n\nStereo headphones are required. Speakers, or a single earbud, let both tones into both ears. Then there is no binaural beat.\n\nIsochronic tones are the other choice. One tone is pulsed at the beat rate. They work on speakers, and they can feel sharper.';

  @override
  String get attuneIntroKicker2 => 'Before you listen';

  @override
  String get attuneIntroTitle2 => 'Hemispheric sound is strong';

  @override
  String get attuneIntroBody2 =>
      'Each ear sends its tone along its own path. That split is what people mean by hemispheric synchronization. The bands name the beat rate, not a promise. Delta is about 2 Hz, theta about 6, alpha about 10, and beta about 20. The carrier, from 100 to 400 Hz, is the pitch you hear.\n\nThis app does not read your brain, and it does not place you in a state. Sit or lie down somewhere you can stop. Do not use this while driving, in water, or when your attention is needed elsewhere. Keep the volume comfortable. The sound rises over the first moment. Stop if you feel dizzy, tense, or unwell. If you have a history of seizures, skip this tool.';

  @override
  String get attuneIntroFootnote =>
      'This is not treatment, and it is not EMDR. The Anchor stays available.';

  @override
  String get attuneIntroUnderstand => 'I understand';

  @override
  String get attuneIntroAgain => 'About these frequencies';

  @override
  String get attuneWaiverTitle => 'Before the tones';

  @override
  String get attuneWaiverRecorded => 'This choice is stored on this device.';

  @override
  String get attuneWaiverSeizure =>
      'I do not have a history of epilepsy or seizure disorders.';

  @override
  String get attuneWaiverMachinery =>
      'I will not operate heavy machinery or drive while listening.';

  @override
  String get attuneWaiverRisk =>
      'I assume all risks associated with brainwave entrainment, releasing the creators from liability regarding adverse psychiatric reactions.';

  @override
  String get attuneWaiverEnter => 'Enter';

  @override
  String get attuneCarouselAccept => 'I Understand and Accept';

  @override
  String get attuneToneLevel => 'Tone';

  @override
  String get attuneMaskLevel => 'Mask';

  @override
  String get attuneMaskWaiting =>
      'A local recording can be added later. This slider stays quiet until then.';

  @override
  String get attuneMaskMusicNote =>
      'Using your own music? Choose ambient tracks or classical music around 60 BPM. Fast or aggressive music will clash with the entrainment frequencies and may cause anxiety.';

  @override
  String get attuneMaskNext => 'Next track';

  @override
  String get attuneMaskTrackSpring => 'Vivaldi, Spring';

  @override
  String get attuneMaskTrackSummer => 'Vivaldi, Summer';

  @override
  String get attuneMaskTrackAutumn => 'Vivaldi, Autumn';

  @override
  String get attuneMaskTrackWinter => 'Vivaldi, Winter';

  @override
  String get attuneMaskCredit =>
      'Vivaldi, The Four Seasons, Op. 8. The Modena Chamber Orchestra. Public-domain recordings via Musopen.';

  @override
  String get attuneFocus => 'Slow shape';

  @override
  String get physicsOpen => 'The physics';

  @override
  String get physicsTitle => 'How the sound works';

  @override
  String get physicsLead => 'Two tones, and what they do not do.';

  @override
  String get physicsHearingTitle => 'The hearing barrier';

  @override
  String get physicsHearingBody =>
      'You cannot hear a binaural beat as its own note in the room. One steady tone goes to the left ear. A second tone, a few hertz away, goes to the right ear. Hearing builds the pulse from that split, and only then.\n\nStereo headphones keep the tones apart. Speakers, or one earbud, let both tones into both ears. The barrier fails, and there is no binaural beat.';

  @override
  String get physicsCarrierTitle => 'Carrier and beat';

  @override
  String get physicsCarrierBody =>
      'The carrier is the pitch you hear. In this app it runs from 100 to 400 Hz. The beat is the difference between the ears, not a second sound added on top.\n\nThe band names that difference. Delta is about 2 Hz, theta about 6, alpha about 10, and beta about 20. Those are pulse rates. They are not a promise that you will enter a named brain state.';

  @override
  String get physicsFollowingTitle => 'Frequency following response';

  @override
  String get physicsFollowingBody =>
      'Frequency following response is a research name for brain activity that sometimes tracks a repeating sound. The evidence is mixed. It is clearer for some clicks and loudness pulses than for a quiet binaural beat.\n\nThis app does not read your brain. It does not measure a response, and it does not place you in a state. If the sound feels like too much, stop.';

  @override
  String get physicsLampTitle => 'Lamp and laser';

  @override
  String get physicsLampBody =>
      'A lamp throws light in many directions. A laser holds one wavelength in step. Older writing used that contrast as a picture of scattered attention versus a narrow one.\n\nThe picture is not a measurement. MonkeyThrive does not turn the tone into a laser, and it does not steer the nervous system. Isochronic tones are different again: one tone, pulsed, which can feel sharper and does not need the two-ear split.';

  @override
  String get physicsWarningKicker => 'WARNING';

  @override
  String get physicsWarning =>
      'Do not drive or operate machinery while listening. The sound can make you drowsy or unsteady. It does not put you to sleep, and it does not override your nervous system. Stop if you feel dizzy, tense, or unwell. If you have a history of seizures, skip this tool.';

  @override
  String get frequencyBand => 'Frequency band';

  @override
  String get carrierFrequency => 'Carrier frequency';

  @override
  String hertz(String hz) {
    return '$hz Hz';
  }

  @override
  String hertzBeat(String hz) {
    return '$hz Hz beat';
  }

  @override
  String get generating => 'Generating…';

  @override
  String get natureSounds => 'Nature sounds';

  @override
  String get natureLayer =>
      'Layer ambient sound over any tone, or use on its own.';

  @override
  String get couldNotStartAudio => 'Could not start audio. Try again.';

  @override
  String get play => 'Play';

  @override
  String get stop => 'Stop';

  @override
  String get none => 'None';

  @override
  String get binauralShort => 'Binaural';

  @override
  String get isochronicShort => 'Isochronic';

  @override
  String binauralBeatsTitle(String band) {
    return 'Binaural Beats — $band';
  }

  @override
  String isochronicTonesTitle(String band) {
    return 'Isochronic Tones — $band';
  }

  @override
  String natureSoundTitle(String type) {
    return 'Nature Sound — $type';
  }

  @override
  String get bandDelta => 'Delta';

  @override
  String get bandTheta => 'Theta';

  @override
  String get bandAlpha => 'Alpha';

  @override
  String get bandBeta => 'Beta';

  @override
  String get rangeDelta => '0.5–4 Hz';

  @override
  String get rangeTheta => '4–8 Hz';

  @override
  String get rangeAlpha => '8–14 Hz';

  @override
  String get rangeBeta => '14–30 Hz';

  @override
  String get useDelta => 'Deep sleep · Recovery';

  @override
  String get useTheta => 'Deep relaxation · Processing';

  @override
  String get useAlpha => 'Calm focus · Grounded';

  @override
  String get useBeta => 'Alert · Present';

  @override
  String get noiseRain => 'Rain';

  @override
  String get noiseOcean => 'Ocean';

  @override
  String get noiseForest => 'Forest';

  @override
  String get noiseRiver => 'River';

  @override
  String get noiseThunder => 'Thunder';

  @override
  String get noiseWind => 'Wind';

  @override
  String get messagesStillOnScreen =>
      'The messages app did not open. The number is still on this screen.';

  @override
  String get phoneStillOnScreen =>
      'The phone app did not open. The number is still on this screen for you to dial.';

  @override
  String textKeywordTo(String keyword, String number) {
    return 'Text $keyword to $number';
  }

  @override
  String get notACopy => 'This is not a MonkeyThrive copy.';

  @override
  String get copyUnreadable => 'This copy could not be read.';

  @override
  String get copyNewer => 'This copy is from a newer version.';

  @override
  String get passphraseWrong => 'That passphrase did not open this copy.';

  @override
  String passphraseMin(int count) {
    return 'Use at least $count characters.';
  }

  @override
  String get suggestionSit =>
      'I\'m feeling overwhelmed right now. Could you sit with me or send a quiet check-in? No need to fix anything.';

  @override
  String get suggestionRough =>
      'Having a rough moment and grounding myself. Just letting you know so I\'m not alone.';

  @override
  String personWillBeRemoved(String name) {
    return '$name will be removed from this device.';
  }

  @override
  String get notReally => '🙁  Not really';

  @override
  String get baselineBox => 'Box';

  @override
  String get acousticMessage =>
      'Deterministic acoustic synthesis is undergoing calibration to prevent sudden sensory triggers. Available in a future release.';

  @override
  String get generalCategory => 'General';

  @override
  String countTimes(int count) {
    return '$count×';
  }

  @override
  String get accentTeal => 'teal';

  @override
  String get accentGreen => 'green';

  @override
  String get accentBlue => 'blue';

  @override
  String get accentAmber => 'amber';

  @override
  String get bilateralSupport => 'between-session support, not therapy';

  @override
  String get journaling => 'Journaling';

  @override
  String get panicTool => 'Panic / Physiological Sigh';

  @override
  String get sighTracked => 'Physiological Sigh';

  @override
  String get wimHofTracked => 'Wim Hof';

  @override
  String get clearAllData => 'Clear all data';

  @override
  String get attuneType => 'Type';

  @override
  String hoursShort(int hours) {
    return '${hours}h';
  }

  @override
  String clock(String minutes, String seconds) {
    return '$minutes:$seconds';
  }

  @override
  String get crisisEmergency => 'Emergency';

  @override
  String get crisisSupportLine => 'Support line';

  @override
  String get crisisWhereYouAre => 'Where you are';

  @override
  String get ok => 'OK';
}
