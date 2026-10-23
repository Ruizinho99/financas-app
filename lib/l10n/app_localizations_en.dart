// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Finances';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'Automatic';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get monthPrevious => 'Previous month';

  @override
  String get monthNext => 'Next month';

  @override
  String get pickDayOfMonth => 'Pick a day of the month';

  @override
  String get transaction => 'Transaction';

  @override
  String get transactions => 'Transactions';

  @override
  String get startHere => 'Start here';

  @override
  String get monthAppearsHint =>
      'The month appears as soon as you have transactions';

  @override
  String get importStatement => 'Import a statement';

  @override
  String get addTransaction => 'Add a transaction';

  @override
  String get spent => 'Spent';

  @override
  String canStillSpend(String amount) {
    return 'You can still spend $amount';
  }

  @override
  String dailyAverage(String amount) {
    return 'Average $amount per day';
  }

  @override
  String get income => 'Income';

  @override
  String get saved => 'Saved';

  @override
  String get sentToInvest => 'Sent to invest';

  @override
  String get whereSpendMost => 'Where you spend the most';

  @override
  String get seeAnalysis => 'See analysis';

  @override
  String get classifyHint => 'One card per name; remembered for next time';

  @override
  String get budget => 'Budget';

  @override
  String get analysis => 'Analysis';

  @override
  String get backToThisMonth => 'Back to this month';

  @override
  String get goals => 'Goals';

  @override
  String get seeAll => 'See all';

  @override
  String get deliveriesToDistribute => 'Deliveries to distribute';

  @override
  String get distribute => 'Distribute';

  @override
  String get deliveriesHint =>
      'Bank transfers you have not split across assets yet.';

  @override
  String get planning => 'Planning';

  @override
  String get seePlan => 'See plan';

  @override
  String get planned => 'Planned';

  @override
  String get actualSpent => 'Actual spending';

  @override
  String leftAfterPlan(String amount) {
    return 'Left from salary after the plan: $amount';
  }

  @override
  String get reached => 'Reached';

  @override
  String missingAmount(String amount) {
    return '$amount to go';
  }

  @override
  String get categorize => 'Categorize';

  @override
  String get delete => 'Delete';

  @override
  String deleteTransactionsQuestion(int count) {
    return 'Delete $count transactions?';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get search => 'Search…';

  @override
  String get noCategory => 'No category';

  @override
  String get allAccounts => 'All accounts';

  @override
  String get accountFallback => 'Account';

  @override
  String get allMonths => 'All months';

  @override
  String get noTransactionsHint =>
      'No transactions.\nImport a statement (icon at the top) or add one by hand.';

  @override
  String reversalDeleted(String amount) {
    return 'Cancels an expense that was deleted ($amount)';
  }

  @override
  String reversalOf(String name, String amount) {
    return 'Cancels $name ($amount)';
  }

  @override
  String reversedLeft(String done, String left) {
    return 'Cancelled $done · left $left';
  }

  @override
  String get goalFallback => 'Goal';

  @override
  String goalsSplit(String parts) {
    return 'Goals: $parts';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get monthStartTitle => 'Start of the month';

  @override
  String get monthStartSubtitle => 'Fixed day or payday';

  @override
  String get monthModeCalendar => 'Calendar';

  @override
  String get monthModeFixed => 'Fixed day';

  @override
  String get monthModeSalary => 'Salary';

  @override
  String get monthStartDayLabel => 'Day the month starts';

  @override
  String get monthNamedByEnd =>
      'A month is named after the month it ends in: 25 Aug – 24 Sep is September.';

  @override
  String get monthCalendarHint =>
      'The month runs from the 1st to the last day, like the calendar.';

  @override
  String get salaryCategoryLabel => 'Salary category';

  @override
  String get salaryCategoryChoose => 'Choose category';

  @override
  String get salaryCategoryHint =>
      'The month starts on the day a positive transaction arrives in this category.';

  @override
  String salaryDatesFound(int count) {
    return 'Paydays found: $count';
  }

  @override
  String get salaryNoneFound =>
      'No salaries in this category yet. Until then, the month is the calendar month.';

  @override
  String thisMonthIs(String range) {
    return 'This month: $range';
  }

  @override
  String dayOfMonthItem(int day) {
    return 'Day $day';
  }
}
