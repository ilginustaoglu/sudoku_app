import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../services/locale_manager.dart';
import '../services/statistics_visibility_manager.dart';
import 'app_strings.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('tr'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('it'),
    Locale('ja'),
    Locale('zh'),
    Locale('ko'),
    Locale('nl'),
    Locale('ru'),
  ];

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get _lang => locale.languageCode;

  String tr(String key, [Map<String, String> params = const {}]) {
    var value = AppStrings.get(key, _lang);
    params.forEach((k, v) => value = value.replaceAll('{$k}', v));
    return value;
  }

  // Common
  String get appName => tr('appName');
  String get ok => tr('ok');
  String get close => tr('close');
  String get cancel => tr('cancel');
  String get save => tr('save');
  String get error => tr('error');
  String errorWithMessage(String message) =>
      tr('errorWithMessage', {'message': message});

  // Settings
  String get settings => tr('settings');
  String get appSettings => tr('appSettings');
  String get theme => tr('theme');
  String get themeSystem => tr('themeSystem');
  String get themeLight => tr('themeLight');
  String get themeDark => tr('themeDark');
  String get themeSelection => tr('themeSelection');
  String get selectTheme => tr('selectTheme');
  String get themeSystemSubtitle => tr('themeSystemSubtitle');
  String get themeLightSubtitle => tr('themeLightSubtitle');
  String get themeDarkSubtitle => tr('themeDarkSubtitle');
  String get language => tr('language');
  String get languageSubtitle => tr('languageSubtitle');
  String get langSystem => tr('langSystem');
  String get langEnglish => tr('langEnglish');
  String get langTurkish => tr('langTurkish');
  String get langGerman => tr('langGerman');
  String get langFrench => tr('langFrench');
  String get langSpanish => tr('langSpanish');
  String get langItalian => tr('langItalian');
  String get langJapanese => tr('langJapanese');
  String get langChinese => tr('langChinese');
  String get langKorean => tr('langKorean');
  String get langDutch => tr('langDutch');
  String get langRussian => tr('langRussian');
  String get sound => tr('sound');
  String get soundSubtitle => tr('soundSubtitle');
  String get highlightColor => tr('highlightColor');
  String selectedColor(String name) => tr('selectedColor', {'name': name});
  String get profileVisibility => tr('profileVisibility');
  String get showName => tr('showName');
  String get showNameSubtitle => tr('showNameSubtitle');
  String get showEmail => tr('showEmail');
  String get showEmailSubtitle => tr('showEmailSubtitle');
  String get statisticsVisibility => tr('statisticsVisibility');
  String get visibilityOnlyMe => tr('visibilityOnlyMe');
  String get visibilityFriends => tr('visibilityFriends');
  String get visibilityEveryone => tr('visibilityEveryone');
  String get displayName => tr('displayName');
  String get displayNameNotSet => tr('displayNameNotSet');
  String get profileColor => tr('profileColor');
  String get profileColorSubtitle => tr('profileColorSubtitle');
  String get profileColorUpdated => tr('profileColorUpdated');
  String get setDisplayName => tr('setDisplayName');
  String get displayNameHint => tr('displayNameHint');
  String get displayNamePersonalSubtitle => tr('displayNamePersonalSubtitle');
  String get displayNameUpdated => tr('displayNameUpdated');

  // Colors
  String get colorPurple => tr('colorPurple');
  String get colorBlue => tr('colorBlue');
  String get colorRed => tr('colorRed');
  String get colorGreen => tr('colorGreen');
  String get colorOrange => tr('colorOrange');
  String get colorPink => tr('colorPink');
  String get colorTeal => tr('colorTeal');
  String get colorCyan => tr('colorCyan');
  String get colorIndigo => tr('colorIndigo');
  String get colorAmber => tr('colorAmber');
  String get colorBrown => tr('colorBrown');
  String get colorGrey => tr('colorGrey');
  String get colorCustom => tr('colorCustom');
  String get colorUnknown => tr('colorUnknown');

  String colorNameKey(Color color) {
    if (color == Colors.blue) return 'colorBlue';
    if (color == Colors.green) return 'colorGreen';
    if (color == Colors.orange) return 'colorOrange';
    if (color == Colors.purple) return 'colorPurple';
    if (color == Colors.red) return 'colorRed';
    if (color == Colors.teal) return 'colorTeal';
    if (color == Colors.pink) return 'colorPink';
    if (color == Colors.indigo) return 'colorIndigo';
    if (color == Colors.amber) return 'colorAmber';
    if (color == Colors.cyan) return 'colorCyan';
    if (color == Colors.brown) return 'colorBrown';
    if (color == Colors.grey) return 'colorGrey';
    return 'colorUnknown';
  }

  String localizedColorName(String key) => tr(key);

  String localizedColor(Color color) =>
      localizedColorName(colorNameKey(color));

  // Home
  String get play => tr('play');
  String get continueGame => tr('continueGame');
  String get newGame => tr('newGame');
  String get todaysGame => tr('todaysGame');
  String get logout => tr('logout');
  String get loggedOutSuccess => tr('loggedOutSuccess');
  String get deleteAccount => tr('deleteAccount');
  String get deleteAccountSubtitle => tr('deleteAccountSubtitle');
  String get deleteAccountConfirmTitle => tr('deleteAccountConfirmTitle');
  String get deleteAccountConfirmMessage => tr('deleteAccountConfirmMessage');
  String get deleteAccountSuccess => tr('deleteAccountSuccess');
  String get deleteAccountFailed => tr('deleteAccountFailed');
  String get selectDifficulty => tr('selectDifficulty');
  String get easy => tr('easy');
  String get medium => tr('medium');
  String get hard => tr('hard');
  String get sendFeedback => tr('sendFeedback');

  // Guide
  String get guideSkip => tr('guideSkip');
  String get guideNext => tr('guideNext');
  String get guideDone => tr('guideDone');
  String get guidePlayTitle => tr('guidePlayTitle');
  String get guidePlayDesc => tr('guidePlayDesc');
  String get guideDailyTitle => tr('guideDailyTitle');
  String get guideDailyDesc => tr('guideDailyDesc');
  String get guideCalendarTitle => tr('guideCalendarTitle');
  String get guideCalendarDesc => tr('guideCalendarDesc');
  String get guideProfileTitle => tr('guideProfileTitle');
  String get guideProfileDesc => tr('guideProfileDesc');
  String get guideFeedbackTitle => tr('guideFeedbackTitle');
  String get guideFeedbackDesc => tr('guideFeedbackDesc');
  String get guideSettingsTitle => tr('guideSettingsTitle');
  String get guideSettingsDesc => tr('guideSettingsDesc');
  String get showGuide => tr('showGuide');

  // Profile
  String get profile => tr('profile');
  String get myFriends => tr('myFriends');
  String get addFriend => tr('addFriend');
  String get comingSoon => tr('comingSoon');
  String get statistics => tr('statistics');
  String get gamesByDifficulty => tr('gamesByDifficulty');
  String get noProfileAvailable => tr('noProfileAvailable');
  String get noStatisticsAvailable => tr('noStatisticsAvailable');
  String get statOverall => tr('statOverall');
  String get statTotalGames => tr('statTotalGames');
  String get statTotalScore => tr('statTotalScore');
  String get statBestScore => tr('statBestScore');
  String get statAverageScore => tr('statAverageScore');
  String get statTotalTime => tr('statTotalTime');
  String statGamesPlayed(int count) =>
      tr('statGamesPlayed', {'count': count.toString()});
  String get anonymousUser => tr('anonymousUser');

  // Login / Register
  String get loginTitle => tr('loginTitle');
  String get welcomeBack => tr('welcomeBack');
  String get loginSubtitle => tr('loginSubtitle');
  String get email => tr('email');
  String get emailHint => tr('emailHint');
  String get password => tr('password');
  String get passwordHint => tr('passwordHint');
  String get login => tr('login');
  String get noAccount => tr('noAccount');
  String get loggedInSuccess => tr('loggedInSuccess');
  String get enterEmail => tr('enterEmail');
  String get validEmail => tr('validEmail');
  String get enterPassword => tr('enterPassword');
  String get createAccount => tr('createAccount');
  String get sendVerificationCode => tr('sendVerificationCode');
  String get resendCode => tr('resendCode');
  String get verificationCode => tr('verificationCode');
  String get verificationCodeHint => tr('verificationCodeHint');
  String get firstName => tr('firstName');
  String get firstNameHint => tr('firstNameHint');
  String get lastName => tr('lastName');
  String get lastNameHint => tr('lastNameHint');
  String get confirmPassword => tr('confirmPassword');
  String get confirmPasswordHint => tr('confirmPasswordHint');
  String get birthDate => tr('birthDate');
  String get selectBirthDateHelp => tr('selectBirthDateHelp');
  String get selectBirthDate => tr('selectBirthDate');
  String get chooseAvatarColor => tr('chooseAvatarColor');
  String get accountCreated => tr('accountCreated');
  String get codeVerified => tr('codeVerified');
  String get invalidCode => tr('invalidCode');
  String get verificationCodeTitle => tr('verificationCodeTitle');
  String get yourVerificationCode => tr('yourVerificationCode');
  String get sending => tr('sending');
  String get selectBirthDateError => tr('selectBirthDateError');
  String get fillRequiredFields => tr('fillRequiredFields');
  String get sendCodeFirst => tr('sendCodeFirst');
  String get enterSixDigitCode => tr('enterSixDigitCode');
  String get verifyCodeFirst => tr('verifyCodeFirst');
  String get enterFirstName => tr('enterFirstName');
  String get enterLastName => tr('enterLastName');
  String get passwordMinLength => tr('passwordMinLength');
  String get confirmPasswordRequired => tr('confirmPasswordRequired');
  String get passwordsDoNotMatch => tr('passwordsDoNotMatch');
  String get verifyCodeRequired => tr('verifyCodeRequired');
  String get codeSixDigits => tr('codeSixDigits');
  String get enterValidEmail => tr('enterValidEmail');
  String get enterEmailAddress => tr('enterEmailAddress');
  String get enterSixDigitCodeShort => tr('enterSixDigitCodeShort');
  String get profileAlreadyExists => tr('profileAlreadyExists');
  String get profileNotFound => tr('profileNotFound');
  String get invalidPassword => tr('invalidPassword');

  // Feedback
  String get feedbackIntro => tr('feedbackIntro');
  String get category => tr('category');
  String get message => tr('message');
  String get messageHint => tr('messageHint');
  String get feedbackThanks => tr('feedbackThanks');
  String get suggestion => tr('suggestion');
  String get bugReport => tr('bugReport');
  String get general => tr('general');
  String get enterMessage => tr('enterMessage');
  String get messageMinLength => tr('messageMinLength');
  String get feedbackNotConfigured => tr('feedbackNotConfigured');
  String get feedbackSendFailed => tr('feedbackSendFailed');
  String get feedbackConnectionError => tr('feedbackConnectionError');

  // Game
  String get gameScore => tr('gameScore');
  String get gameError => tr('gameError');
  String get gameCongratulations => tr('gameCongratulations');
  String gameCompletionMessage(int score) =>
      tr('gameCompletionMessage', {'score': score.toString()});
  String get backToHome => tr('backToHome');
  String get gameOver => tr('gameOver');
  String get gameOverMessage => tr('gameOverMessage');
  String get sudoku => tr('sudoku');

  // Calendar
  String get dailyCalendarTitle => tr('dailyCalendarTitle');
  String get futureDateUnavailable => tr('futureDateUnavailable');
  String get completed => tr('completed');
  String get playTodaysGame => tr('playTodaysGame');
  String get playDaysGame => tr('playDaysGame');
  String difficultyLabel(String difficulty) =>
      tr('difficultyLabel', {'difficulty': difficultyName(difficulty)});

  // Other apps
  String get otherApps => tr('otherApps');
  String get followOnInstagram => tr('followOnInstagram');
  String get instagramLinkComingSoon => tr('instagramLinkComingSoon');
  String get moreApps => tr('moreApps');
  String get moreAppsComingSoon => tr('moreAppsComingSoon');

  // Statistics page
  String get statYearly => tr('statYearly');
  String get statMonthly => tr('statMonthly');
  String get statWeekly => tr('statWeekly');
  String get weeklyCompletedGames => tr('weeklyCompletedGames');
  List<String> get weekdayShortLabels => List.generate(7, (i) => tr('day$i'));

  String difficultyName(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return easy;
      case 'Medium':
        return medium;
      case 'Hard':
        return hard;
      default:
        return difficulty;
    }
  }

  String visibilityLabel(StatisticsVisibility visibility) {
    switch (visibility) {
      case StatisticsVisibility.onlyMe:
        return visibilityOnlyMe;
      case StatisticsVisibility.friends:
        return visibilityFriends;
      case StatisticsVisibility.everyone:
        return visibilityEveryone;
    }
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return tr('durationHoursMinutes', {
        'hours': hours.toString(),
        'minutes': minutes.toString(),
      });
    }
    if (minutes > 0) {
      return tr('durationMinutesSeconds', {
        'minutes': minutes.toString(),
        'seconds': secs.toString(),
      });
    }
    return tr('durationSeconds', {'seconds': secs.toString()});
  }

  String languageLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.system:
        return langSystem;
      case AppLanguage.english:
        return langEnglish;
      case AppLanguage.turkish:
        return langTurkish;
      case AppLanguage.german:
        return langGerman;
      case AppLanguage.french:
        return langFrench;
      case AppLanguage.spanish:
        return langSpanish;
      case AppLanguage.italian:
        return langItalian;
      case AppLanguage.japanese:
        return langJapanese;
      case AppLanguage.chinese:
        return langChinese;
      case AppLanguage.korean:
        return langKorean;
      case AppLanguage.dutch:
        return langDutch;
      case AppLanguage.russian:
        return langRussian;
    }
  }

  String themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return themeSystem;
      case ThemeMode.light:
        return themeLight;
      case ThemeMode.dark:
        return themeDark;
    }
  }

  /// Maps backend/exception messages to localized strings when possible.
  String localizeErrorMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid verification code')) return invalidCode;
    if (lower.contains('password must be at least')) return passwordMinLength;
    if (lower.contains('profile already exists')) return profileAlreadyExists;
    if (lower.contains('profile not found')) return profileNotFound;
    if (lower.contains('invalid password')) return invalidPassword;
    if (lower.contains('feedback service is not configured')) {
      return feedbackNotConfigured;
    }
    if (lower.contains('check your connection')) {
      return feedbackConnectionError;
    }
    if (lower.contains('could not send feedback')) return feedbackSendFailed;
    return message;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
