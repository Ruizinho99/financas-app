// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get anCompareOn => 'Comparing with the previous period';

  @override
  String get anCompareOff => 'Compare with the previous period';

  @override
  String get anModeMonth => 'Month';

  @override
  String get anModeYear => 'Year';

  @override
  String get anModeYtd => 'YTD';

  @override
  String get anModeCustom => 'Custom';

  @override
  String anYtdLabel(String year) {
    return 'YTD $year · 1 Jan – today';
  }

  @override
  String get anPickRange => 'Choose date range';

  @override
  String get anApply => 'Apply';

  @override
  String get anTabOverview => 'Overview';

  @override
  String get anTabSpend => 'Spending';

  @override
  String get anTabSave => 'Save';

  @override
  String get anTabTrend => 'Trend';

  @override
  String get anNoDataPeriod =>
      'No transactions in this period (or the filters match nothing).';

  @override
  String get anExpenses => 'Expenses';

  @override
  String anSamePeriodPrev(String amount) {
    return 'Same days of the previous period: $amount';
  }

  @override
  String anPrevPeriodAmount(String amount) {
    return 'Previous period: $amount';
  }

  @override
  String get anPrevPeriod => 'Previous period';

  @override
  String anOngoingToday(int day) {
    return 'Period in progress: amounts up to today (day $day).';
  }

  @override
  String get anIncomes => 'Income';

  @override
  String get anBalance => 'Balance';

  @override
  String get anInvested => 'Invested';

  @override
  String anOfIncome(String percent) {
    return '$percent of income';
  }

  @override
  String get anSavingsRate => 'Savings rate';

  @override
  String anPpVsPrev(String sign, int pp) {
    return '$sign$pp pp vs previous';
  }

  @override
  String get anIncomeExpected => 'Expected income: net salary set in Budget.';

  @override
  String get anIncomeFromSalary =>
      'No categorised income: using the net salary set in Budget.';

  @override
  String get anRateOngoing =>
      'Period in progress: the savings rate will keep changing until the end.';

  @override
  String get anRateExcellent =>
      'You are saving more than 20% of what you earn. Excellent.';

  @override
  String anRateOk(String percent) {
    return 'You are saving $percent. A good goal is 20%.';
  }

  @override
  String get anRateNegative =>
      'You are spending more than you earn in this period.';

  @override
  String get anPace => 'Spending pace';

  @override
  String get anAvgPerDay => 'Average per day';

  @override
  String get anAvgValue => 'Average amount';

  @override
  String anDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String anOfMonth(String percent) {
    return '$percent of the month';
  }

  @override
  String anOfSpending(String percent) {
    return '$percent of spending';
  }

  @override
  String anProjected(String amount) {
    return 'At the current pace, the month closes at $amount';
  }

  @override
  String anPrevMonthSpent(String amount) {
    return 'Last month you spent $amount.';
  }

  @override
  String anAboveBudget(String amount, String budget) {
    return 'That is $amount above the budget of $budget.';
  }

  @override
  String anWithinBudget(String budget, String margin) {
    return 'Within the budget of $budget, with $margin to spare.';
  }

  @override
  String get anMandVsOpt => 'Mandatory vs optional';

  @override
  String get anMandVsOptSub =>
      'What you have to pay vs where you have room to save';

  @override
  String get anMandatory => 'Mandatory';

  @override
  String get anOptional => 'Optional';

  @override
  String get anNoCategory => 'No category';

  @override
  String get anTotal => 'Total';

  @override
  String get anNoSpendPeriod => 'No spending in this period.';

  @override
  String anPctOfIncome(String mand, String opt, String left) {
    return 'As % of income: mandatory $mand, optional $opt, left over $left.';
  }

  @override
  String get anBudgetSub => 'Limits and goals set';

  @override
  String get anBudgetSubFiltered =>
      'Limits and goals set (not affected by filters)';

  @override
  String get anGoalReached => 'Goal reached 🎉';

  @override
  String anGoalLeft(String amount, String percent) {
    return '$amount left to the goal ($percent)';
  }

  @override
  String anOverLimit(String amount) {
    return 'You went over the limit by $amount';
  }

  @override
  String anNearLimit(String amount) {
    return 'Close to the limit: $amount left';
  }

  @override
  String anLeftUsed(String amount, String percent) {
    return '$amount left ($percent used)';
  }

  @override
  String get anWhereSave => 'Where can I save?';

  @override
  String anFoundUpTo(String amount) {
    return 'We found up to $amount a month of room.';
  }

  @override
  String get anNoSpendPeriodFilter =>
      'No spending in this period (or the filters match nothing).';

  @override
  String get anCategories => 'Categories';

  @override
  String get anSubcategories => 'Subcategories';

  @override
  String get anMerchants => 'Merchants';

  @override
  String get anAccounts => 'Accounts';

  @override
  String get anWhereMoneyGoes => 'Where the money goes';

  @override
  String get anSubDetail => 'Detail by subcategory';

  @override
  String get anWhereMostSpend => 'Where you spend the most';

  @override
  String get anSpendByAccount => 'Spending by account';

  @override
  String get anTapRowHint => 'Tap a row to see its transactions';

  @override
  String get anOthers => 'Others';

  @override
  String get anShowLess => 'Show less';

  @override
  String anSeeAllCount(int count) {
    return 'See all ($count)';
  }

  @override
  String get anWdMon => 'Mon';

  @override
  String get anWdTue => 'Tue';

  @override
  String get anWdWed => 'Wed';

  @override
  String get anWdThu => 'Thu';

  @override
  String get anWdFri => 'Fri';

  @override
  String get anWdSat => 'Sat';

  @override
  String get anWdSun => 'Sun';

  @override
  String get anDayMon => 'on Mondays';

  @override
  String get anDayTue => 'on Tuesdays';

  @override
  String get anDayWed => 'on Wednesdays';

  @override
  String get anDayThu => 'on Thursdays';

  @override
  String get anDayFri => 'on Fridays';

  @override
  String get anDaySat => 'on Saturdays';

  @override
  String get anDaySun => 'on Sundays';

  @override
  String anSpendMostOn(String day, String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return 'You spend the most $day: $amount in $_temp0';
  }

  @override
  String get anWhichDays => 'Which days you spend the most';

  @override
  String get anLargestSpends => 'Largest expenses';

  @override
  String get anLargestSub => 'The ones that weighed most in this period';

  @override
  String get anMonthByMonth => 'Month by month';

  @override
  String anTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return '$_temp0';
  }

  @override
  String get anWhereFrom => 'Where it comes from';

  @override
  String get anPerMonthCap => 'Per month';

  @override
  String anGeneralCat(String name) {
    return '$name (general)';
  }

  @override
  String get anAnalyseOnly => 'Analyse only this one';

  @override
  String anAndMore(int count) {
    return '… and $count more';
  }

  @override
  String get anNoAccount => 'No account';

  @override
  String get anNotEnoughTrend => 'Not enough data to show the trend yet.';

  @override
  String anLastMonths(int count, String avg) {
    return 'Last $count months · the dashed line is the average ($avg)';
  }

  @override
  String get anSpendByMonth => 'Spending by month';

  @override
  String anBestMonth(String month) {
    return 'Best month: $month';
  }

  @override
  String anBestMonthBody(String amount, String diff) {
    return 'You spent $amount, $diff below average.';
  }

  @override
  String anWorstMonth(String month) {
    return 'Most expensive month: $month';
  }

  @override
  String anWorstMonthBody(String amount, String diff) {
    return 'You spent $amount, $diff above average.';
  }

  @override
  String get anIncomeVsSpend => 'Income vs spending';

  @override
  String get anIncomeVsSpendSub =>
      'If the spending line rises above the income line, you are spending more than you earn';

  @override
  String get anMonth => 'Month';

  @override
  String get anSavingsShort => 'Rate';

  @override
  String get anTrendByCategory => 'Trend by category';

  @override
  String get anPickCategoryHint => 'Choose a category to see it month by month';

  @override
  String get anChooseCategory => 'Choose a category';

  @override
  String get anNone => '— none —';

  @override
  String anAvgMonthsWithSpend(String amount) {
    return 'Average in months with spending: $amount.';
  }

  @override
  String get anNoSpendToAnalyse => 'No spending in this period to analyse.';

  @override
  String get anSavingPotential => 'Saving potential';

  @override
  String get anPerMonth => 'per month';

  @override
  String anUpToYear(String amount) {
    return 'That is up to $amount a year, from the suggestions below alone.';
  }

  @override
  String get anNoObviousMargins =>
      'We found no obvious room in this period. Try another range or the simulator.';

  @override
  String get anWhatIfCut => 'What if you cut optional spending?';

  @override
  String anOptionalThisPeriod(String amount) {
    return 'Optional spending this period: $amount';
  }

  @override
  String get anCut => 'Cut';

  @override
  String get anSaveMonthly => 'You save per month';

  @override
  String get anSaveYearly => 'You save per year';

  @override
  String get anSuggestions => 'Suggestions';

  @override
  String get anSuggestionsSub => 'Sorted by how much they save';

  @override
  String get anRecurringPayments => 'Recurring payments';

  @override
  String anRecOptional(String monthly, String yearly) {
    return 'Optional: $monthly/month ($yearly/year)';
  }

  @override
  String anRecMandatory(String monthly) {
    return 'Mandatory: $monthly/month';
  }

  @override
  String anMonthsLast(int count, String date) {
    return '$count months · last $date';
  }

  @override
  String anAmountPerMonth(String amount) {
    return '$amount/month';
  }

  @override
  String anAmountPerYear(String amount) {
    return '$amount/year';
  }

  @override
  String get anCancelAdvice =>
      'Cancelling what you no longer use is the easiest way to save.';

  @override
  String get anFrequentSmall => 'Frequent small purchases';

  @override
  String get anSmallSub => 'Low-value purchases that repeat often';

  @override
  String anPurchasesAvg(int count, String avg) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count purchases',
      one: '1 purchase',
      zero: '$count purchases',
    );
    return '$_temp0 · average $avg';
  }

  @override
  String get anMandatoryTag => 'mandatory';

  @override
  String get anOptionalTag => 'optional';

  @override
  String get anTypeAll => 'All';

  @override
  String get anCategory => 'Category';

  @override
  String anCategoriesCount(int count) {
    return '$count categories';
  }

  @override
  String get anAccount => 'Account';

  @override
  String anAccountsCount(int count) {
    return '$count accounts';
  }

  @override
  String get anFilters => 'Filters';

  @override
  String get anClearAll => 'Clear all';

  @override
  String get anClear => 'Clear';

  @override
  String get anExpenseType => 'Expense type';

  @override
  String get anSearch => 'Search';

  @override
  String get anSearchHint => 'Name, note, category…';

  @override
  String get anTxAmount => 'Transaction amount';

  @override
  String anMinAmount(String sym) {
    return 'Minimum ($sym)';
  }

  @override
  String anMaxAmount(String sym) {
    return 'Maximum ($sym)';
  }

  @override
  String get anNoCategoriesYet => 'No categories yet.';

  @override
  String get anApplyFilters => 'Apply filters';

  @override
  String get anStable => 'stable';

  @override
  String get anNew => 'new';

  @override
  String anUpToPerMonth(String amount) {
    return 'up to $amount/month';
  }

  @override
  String anOverLimitTitle(String name) {
    return '$name over limit';
  }

  @override
  String anOverLimitDetail(String spent, String target) {
    return 'You spent $spent against a limit of $target.';
  }

  @override
  String anIncreaseTitle(String name, String percent) {
    return '$name up $percent';
  }

  @override
  String anIncreaseDetail(String delta, String prev, String cur) {
    return '$delta more than in the previous period ($prev → $cur).';
  }

  @override
  String anTopOptionalTitle(String name, String percent) {
    return '$name: $percent of spending';
  }

  @override
  String anTopOptionalDetail(String amount) {
    return 'This is optional spending. Cutting 10% would save $amount a month.';
  }

  @override
  String anSmallDetail(
    int count,
    int places,
    String total,
    String examples,
    String saving,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count purchases',
      one: '1 purchase',
      zero: '$count purchases',
    );
    String _temp1 = intl.Intl.pluralLogic(
      places,
      locale: localeName,
      other: '$places places',
      one: '1 place',
      zero: '$places places',
    );
    return '$_temp0 at $_temp1 add up to $total ($examples). Cutting a third would save $saving a month.';
  }

  @override
  String anRecurringTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count optional recurring payments',
      one: '1 optional recurring payment',
      zero: '$count optional recurring payments',
    );
    return '$_temp0';
  }

  @override
  String anRecurringDetail(String monthly, String yearly) {
    return 'Together they come to $monthly a month ($yearly a year). Check whether you still need all of them.';
  }

  @override
  String get anUnclassifiedSpend => 'Spending without category';

  @override
  String anUnclassifiedDetail(String amount) {
    return '$amount to classify. The more you classify, the more accurate the suggestions.';
  }

  @override
  String get bpCopySalaryTooltip => 'Copy salary to all months';

  @override
  String get bpNetSalary => 'Net salary';

  @override
  String get bpSet => 'Set';

  @override
  String get bpSpecificThisMonth => 'Specific amount for this month';

  @override
  String bpAllocatedSummary(String amount, String percent) {
    return 'Allocated $amount ($percent)';
  }

  @override
  String bpUnallocatedLeft(String amount) {
    return 'Unallocated $amount';
  }

  @override
  String bpOverAllocated(String amount) {
    return 'Over by $amount';
  }

  @override
  String bpIncomeThisMonth(String amount) {
    return 'Income received this month: $amount';
  }

  @override
  String get bpDefineSalaryHint =>
      'Set your net salary to split it across categories.';

  @override
  String get bpNoCategoriesBudget =>
      'You have no categories yet. Create the first one below (e.g. Housing) and set a budget for each.';

  @override
  String get bpCategories => 'Categories';

  @override
  String get bpNewCategory => 'New category';

  @override
  String get bpBudgetLimit => 'Limit';

  @override
  String get bpBudgetGoal => 'Goal';

  @override
  String bpSpentOfTarget(String spent, String target, String type) {
    return '$spent of $target · $type';
  }

  @override
  String bpSpentNoBudget(String spent) {
    return 'Spent: $spent · no budget';
  }

  @override
  String bpSpentSetBudget(String spent) {
    return 'Spent: $spent · set a budget';
  }

  @override
  String bpMandatoryInMonth(String month) {
    return 'Mandatory in $month';
  }

  @override
  String get bpInheritedFromParent => 'Inherited from the parent category';

  @override
  String get bpOnlyThisMonthHint =>
      'This month only; for several months use “Periods”';

  @override
  String get bpCategoryBudgetOptional => 'Category budget (optional)';

  @override
  String get bpSumOfSubcategories => 'Sum of subcategories';

  @override
  String bpBudgetDescPercent(String type, String percent, String amount) {
    return '$type: $percent% of salary ($amount)';
  }

  @override
  String bpBudgetDescValue(String type, String amount) {
    return '$type: $amount';
  }

  @override
  String get bpSubcategory => 'Subcategory';

  @override
  String get bpPeriods => 'Periods';

  @override
  String get bpEdit => 'Edit';

  @override
  String bpBudgetEditorTitle(String name) {
    return 'Budget · $name';
  }

  @override
  String get bpHasBudget => 'Has a budget';

  @override
  String get bpLimitHint => 'Limit: you want to spend at most this amount.';

  @override
  String get bpGoalHint =>
      'Goal: you want to reach at least this amount (e.g. savings).';

  @override
  String bpValueWithCurrency(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String get bpPercentOfSalary => '% of salary';

  @override
  String get bpMonthlyAmount => 'Monthly amount';

  @override
  String get bpPercentage => 'Percentage';

  @override
  String get bpSave => 'Save';

  @override
  String get bpNetSalaryMonthly => 'Monthly net salary';

  @override
  String get bpOnlyThisMonth => 'Only for this month';

  @override
  String get bpSalaryDefaultHint =>
      'Off: becomes the default amount for every month';

  @override
  String get bpUseBaseSalary => 'Use base amount';

  @override
  String get bpCopyPreviousPlan => 'Copy plan from previous month';

  @override
  String bpCopiedPlanItems(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count expenses from $month.',
      one: 'Copied 1 expense from $month.',
      zero: 'Copied $count expenses from $month.',
    );
    return '$_temp0';
  }

  @override
  String get bpMandatoryPlanned => 'Planned mandatory';

  @override
  String get bpOptionalPlanned => 'Planned optional';

  @override
  String get bpExceedsSalaryBy => 'Exceeds salary by';

  @override
  String get bpUnplanned => 'Unplanned';

  @override
  String get bpSetMonthSalaryHint =>
      'Set the salary for this month to see what is left.';

  @override
  String get bpNoPlanCopyHint =>
      'No planned expenses yet. Use the copy icon to bring in the plan from the previous month.';

  @override
  String get bpNoPlanHint =>
      'No planned expenses yet. Add mandatory ones (rent, electricity…) and optional ones (leisure, subscriptions…).';

  @override
  String get bpMandatoryItems => 'Mandatory';

  @override
  String get bpOptionalItems => 'Optional';

  @override
  String get bpPlannedExpense => 'Planned expense';

  @override
  String get bpCategoryAlreadyPlannedEdit =>
      'This category is already planned for this month. Edit the existing line.';

  @override
  String get bpCategoryAlreadyPlanned =>
      'This category is already planned for this month.';

  @override
  String bpSpentOver(String spent, String over) {
    return 'Spent $spent · over by $over';
  }

  @override
  String bpSpentLeft(String spent, String left) {
    return 'Spent $spent · $left left';
  }

  @override
  String bpPlannedAmount(String currency) {
    return 'Planned amount ($currency)';
  }

  @override
  String get bpMandatoryType => 'Mandatory';

  @override
  String get bpOptionalType => 'Optional';

  @override
  String get bpGoal => 'Goal';

  @override
  String get bpNoGoalsHint =>
      'You have no goals yet.\nCreate one (e.g. holidays) and transfers to its subcategory count towards it.';

  @override
  String bpGoalReachedAmount(String amount) {
    return 'Reached · $amount';
  }

  @override
  String bpGoalProgress(String saved, String target, String remaining) {
    return '$saved of $target · $remaining to go';
  }

  @override
  String get bpNewGoal => 'New goal';

  @override
  String get bpEditGoal => 'Edit goal';

  @override
  String get bpName => 'Name';

  @override
  String get bpGoalNameHint => 'E.g. Summer holiday';

  @override
  String bpGoalAmount(String currency) {
    return 'Goal amount ($currency)';
  }

  @override
  String get bpPreviousAmountKept =>
      'If you change it, the previous amount stays in the history.';

  @override
  String get bpDeadlineOptional => 'Deadline (optional)';

  @override
  String get bpNoDeadline => 'No deadline';

  @override
  String get bpRemoveDeadline => 'Remove deadline';

  @override
  String get bpDescriptionOptional => 'Description (optional)';

  @override
  String get bpCategoryWhere => 'Category it goes in';

  @override
  String get bpChooseCategory => 'Choose category';

  @override
  String get bpGoalCategoryHint =>
      'The goal becomes a subcategory of this category. Transactions in that subcategory count as savings.';

  @override
  String get bpEnterName => 'Enter a name.';

  @override
  String get bpEnterGoalAmount => 'Enter the goal amount.';

  @override
  String get bpChooseGoalCategory => 'Choose the category the goal goes in.';

  @override
  String get bpGoalDeleted => 'Goal deleted.';

  @override
  String bpDeleteGoalQuestion(String name) {
    return 'Delete the goal “$name”? Transactions stay, but are no longer linked to it.';
  }

  @override
  String get bpAlreadyHave => 'You have';

  @override
  String get bpExceeded => 'Over';

  @override
  String get bpRemaining => 'To go';

  @override
  String bpGoalPercentDeadline(String percent, String deadline) {
    return '$percent% · $deadline';
  }

  @override
  String get bpNoDeadlineLower => 'no deadline';

  @override
  String bpDeadlineDate(String date) {
    return 'deadline $date';
  }

  @override
  String get bpLinkTransaction => 'Link transaction';

  @override
  String get bpChangeAmount => 'Change amount';

  @override
  String get bpAmountHistory => 'Amount history';

  @override
  String get bpNoGoalEntriesHint =>
      'Nothing yet. Transfers to the goal subcategory count automatically; link payments made from another category with “Link transaction”.';

  @override
  String bpEntrySubtitle(String date, String kind) {
    return '$date · $kind';
  }

  @override
  String get bpLinkedManual => 'linked';

  @override
  String get bpLinkedByCategory => 'by category';

  @override
  String get bpUnlink => 'Unlink';

  @override
  String get bpStatusReached => 'Goal reached.';

  @override
  String bpStatusOnTrack(String monthly, String needed) {
    return 'At the current pace you will make it in time: you save $monthly/month and need $needed/month.';
  }

  @override
  String bpStatusBehind(String needed, String monthly) {
    return 'To make it in time you need $needed/month; you are saving $monthly/month.';
  }

  @override
  String bpStatusEta(String monthly, String date) {
    return 'At the current pace ($monthly/month) you will reach it by $date.';
  }

  @override
  String bpStatusNoRecent(String amount) {
    return 'No recent transactions. $amount to go.';
  }

  @override
  String get bpChangeGoalAmountTitle => 'Change goal amount';

  @override
  String bpNewAmount(String currency) {
    return 'New amount ($currency)';
  }

  @override
  String get bpChangeAmountHint =>
      'The previous amount stays in the history. Linked transactions stay linked.';

  @override
  String get bpSearchTransaction => 'Search transaction';

  @override
  String get bpNoTransactionsToLink => 'No transactions to link.';

  @override
  String bpTxnLinkSubtitle(String date, String amount, String left) {
    return '$date · $amount · $left unlinked';
  }

  @override
  String bpAmountForGoal(String goal, String currency) {
    return 'Amount for “$goal” ($currency)';
  }

  @override
  String bpUnlinkedHint(String left) {
    return 'Unlinked: $left. You can split the transaction across several goals.';
  }

  @override
  String get bpLink => 'Link';

  @override
  String get bpMonday => 'Monday';

  @override
  String get bpTuesday => 'Tuesday';

  @override
  String get bpWednesday => 'Wednesday';

  @override
  String get bpThursday => 'Thursday';

  @override
  String get bpFriday => 'Friday';

  @override
  String get bpSaturday => 'Saturday';

  @override
  String get bpSunday => 'Sunday';

  @override
  String get bpJanuary => 'January';

  @override
  String get bpFebruary => 'February';

  @override
  String get bpMarch => 'March';

  @override
  String get bpApril => 'April';

  @override
  String get bpMay => 'May';

  @override
  String get bpJune => 'June';

  @override
  String get bpJuly => 'July';

  @override
  String get bpAugust => 'August';

  @override
  String get bpSeptember => 'September';

  @override
  String get bpOctober => 'October';

  @override
  String get bpNovember => 'November';

  @override
  String get bpDecember => 'December';

  @override
  String get bpFreqMonthly => 'Monthly';

  @override
  String get bpFreqWeekly => 'Weekly';

  @override
  String get bpFreqYearly => 'Yearly';

  @override
  String bpWhenMonthly(int day) {
    return 'day $day';
  }

  @override
  String bpWhenYearly(int day, String month) {
    return '$month $day';
  }

  @override
  String get bpNoRecurringHint =>
      'No recurring transactions yet.\n\nRecord your salary, rent or a subscription here: the transaction is created automatically on the right date.';

  @override
  String get bpRecurringTitle => 'Recurring transactions';

  @override
  String get bpNew => 'New';

  @override
  String get bpPaused => 'paused';

  @override
  String get bpEnded => 'ended';

  @override
  String bpNextDate(String date) {
    return 'next $date';
  }

  @override
  String get bpEditRecurring => 'Edit recurring';

  @override
  String get bpNewRecurring => 'New recurring';

  @override
  String get bpEnterDescription => 'Enter a description.';

  @override
  String get bpEnterAmount => 'Enter an amount.';

  @override
  String get bpEndBeforeStart => 'The end date is before the start date.';

  @override
  String bpDeleteRecurringQuestion(String description) {
    return 'Delete “$description”? Transactions already recorded stay.';
  }

  @override
  String get bpExpenseType => 'Expense';

  @override
  String get bpIncomeType => 'Income';

  @override
  String get bpDescription => 'Description';

  @override
  String get bpDescriptionHint => 'E.g. Salary, Rent, Netflix';

  @override
  String get bpCategory => 'Category';

  @override
  String get bpAccount => 'Account';

  @override
  String get bpNoAccount => 'No account';

  @override
  String get bpFrequency => 'Frequency';

  @override
  String get bpDayOfWeek => 'Day of the week';

  @override
  String get bpDayOfMonth => 'Day of the month';

  @override
  String get bpShortMonthHint =>
      'In shorter months, it moves to the last day of the month.';

  @override
  String get bpStart => 'Start';

  @override
  String get bpPastStartHint =>
      'If the start date has already passed, the transactions since then are created when you open the app.';

  @override
  String get bpEndOptional => 'End (optional)';

  @override
  String get bpNoEndDate => 'No end date';

  @override
  String get bpRemoveEndDate => 'Remove end date';

  @override
  String get bpActive => 'Active';

  @override
  String get bpActiveHint => 'Turn off to pause, without deleting';

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

  @override
  String get frmReceipt => 'Receipt';

  @override
  String get frmViewReceipt => 'View receipt';

  @override
  String get frmTakePhoto => 'Take photo';

  @override
  String get frmChooseFromGallery => 'Choose from gallery';

  @override
  String get frmChooseFile => 'Choose file (PDF or image)';

  @override
  String get frmRemoveReceipt => 'Remove receipt';

  @override
  String frmReceiptAttachError(String error) {
    return 'Couldn\'t attach the receipt: $error';
  }

  @override
  String get frmReceiptFileNotFound => 'Receipt file not found.';

  @override
  String get frmEnterValidAmount => 'Enter a valid amount.';

  @override
  String frmAllocatedToGoals(String amount) {
    return 'You already have $amount allocated to goals. Reduce the allocations first.';
  }

  @override
  String frmTransferTo(String name) {
    return 'Transfer to $name';
  }

  @override
  String get frmTransfer => 'Transfer';

  @override
  String get frmExpense => 'Expense';

  @override
  String get frmIncome => 'Income';

  @override
  String get frmReversedGone => 'The reversed expense no longer exists.';

  @override
  String get frmEnterReversedAmount =>
      'Enter how much of the expense is reversed.';

  @override
  String get frmReversalTooBig =>
      'A reversal can\'t be larger than the income.';

  @override
  String frmOnlyLeftToReverse(String amount) {
    return 'Only $amount is left to reverse on this expense.';
  }

  @override
  String frmReversalHelp(String amount) {
    return 'You can still reverse $amount of this expense. The reversed part doesn\'t count as spending or income in Analysis.';
  }

  @override
  String get frmSearchExpense => 'Search expense';

  @override
  String get frmNoReversal => 'Doesn\'t reverse any expense';

  @override
  String frmToReverseSubtitle(String date, String amount, String left) {
    return '$date · $amount · $left left to reverse';
  }

  @override
  String get frmNoExpenseToReverse => 'No expense to reverse.';

  @override
  String get frmInvestPlatform => 'Investment platform';

  @override
  String get frmNone => 'None';

  @override
  String get frmExpenseGone => 'Expense no longer exists';

  @override
  String get frmSaveToSplit => 'Save the transaction to split it across goals.';

  @override
  String get frmChangeAmount => 'Change amount';

  @override
  String get frmUnlink => 'Unlink';

  @override
  String frmToAllocate(String amount) {
    return 'To allocate: $amount';
  }

  @override
  String get frmSplitByGoals => 'Split by goals';

  @override
  String get frmSplitByGoal => 'Split by goal';

  @override
  String get frmAllocate => 'Allocate';

  @override
  String get frmSave => 'Save';

  @override
  String get frmAccount => 'Account';

  @override
  String get frmFromAccount => 'From account';

  @override
  String get frmDestinationAccount => 'Destination account';

  @override
  String get frmSelectAccount => 'Select an account';

  @override
  String get frmSelectDestinationAccount => 'Select the destination account';

  @override
  String get frmToAccount => 'To account';

  @override
  String get frmTakePhotoOrChoose => 'Take a photo or choose a file';

  @override
  String get frmEditTransaction => 'Edit transaction';

  @override
  String get frmNewTransaction => 'New transaction';

  @override
  String get frmImportStatementTip => 'Import statement';

  @override
  String get frmDeleteThisTransaction => 'Delete this transaction?';

  @override
  String get frmCalculator => 'Calculator';

  @override
  String get frmCategory => 'Category';

  @override
  String get frmChooseCategory => 'Choose category';

  @override
  String get frmReversesExpense => 'Reverses an expense (refund, return)';

  @override
  String frmReversedAmount(String currency) {
    return 'Reversed amount ($currency)';
  }

  @override
  String get frmDescriptionOptional => 'Description (optional)';

  @override
  String get frmToday => 'Today';

  @override
  String get frmYesterday => 'Yesterday';

  @override
  String get frmOtherDate => 'Other date';

  @override
  String get frmToInvestOptional => 'To invest (optional)';

  @override
  String get frmOutgoing => 'Outgoing';

  @override
  String get frmIncoming => 'Incoming';

  @override
  String get frmNotCountedNote =>
      'Doesn\'t count as expense or income in Analysis.';

  @override
  String get frmMoreOptions => 'More options (account, receipt)';

  @override
  String frmAmountCurrency(String currency) {
    return 'Amount ($currency)';
  }

  @override
  String frmOnlyLeftToAllocate(String amount) {
    return 'Only $amount is left to allocate.';
  }

  @override
  String get frmOptional => ' (optional)';

  @override
  String get frmCalcHint => 'E.g.: 12.50+3*2';

  @override
  String get frmUse => 'Use';

  @override
  String get frmWholeFile => 'Whole file';

  @override
  String get frmPeriodToImport => 'Period to import';

  @override
  String frmFileDataRange(String from, String to) {
    return 'The file has data from $from to $to. Choose only the range you want to import.';
  }

  @override
  String get frmFrom => 'From';

  @override
  String get frmUntil => 'Until';

  @override
  String frmInRangeOfTotal(int inRange, int total) {
    return '$inRange of $total in the period';
  }

  @override
  String frmTotalInFile(int total) {
    return '$total in the file';
  }

  @override
  String get frmSelectCategory => 'Select a category';

  @override
  String get frmNewCategory => '➕  New category…';

  @override
  String get frmNoCategoryItem => '✖️  No category';

  @override
  String get frmHideEndedFuture => '🙈  Hide ended and upcoming';

  @override
  String get frmShowEndedFuture => '👁  Show ended and upcoming';

  @override
  String get frmEnded => '  · ended';

  @override
  String get frmUpcoming => '  · upcoming';

  @override
  String get frmSelectSubcategory => 'Select a subcategory';

  @override
  String get frmSubcategory => 'Subcategory';

  @override
  String get frmNewSubcategory => '➕  New subcategory…';

  @override
  String get frmNoSubcategory => '— No subcategory —';

  @override
  String get frmChoose => 'Choose';

  @override
  String get frmChooseEmoji => 'Choose emoji';

  @override
  String get frmOrUseKeyboardEmoji => 'Or use another emoji from the keyboard';

  @override
  String get frmRemove => 'Remove';

  @override
  String get frmChooseColor => 'Choose color';

  @override
  String get frmHue => 'Hue';

  @override
  String get frmSaturation => 'Saturation';

  @override
  String get frmBrightness => 'Brightness';

  @override
  String get frmHex => 'Hex';

  @override
  String frmMandatoryTitle(String name) {
    return 'Mandatory · $name';
  }

  @override
  String get frmMandatoryExplain =>
      'The months below count as mandatory spending in this category. In other months it\'s optional.';

  @override
  String get frmNoPeriodDefined => 'No period defined.';

  @override
  String frmFromMonth(String month) {
    return 'From $month';
  }

  @override
  String get frmClose => 'Close';

  @override
  String get frmAddPeriod => 'Add period';

  @override
  String get frmAdd => 'Add';

  @override
  String get frmPickAnyDayOfMonth => 'Pick any day of the month';

  @override
  String get frmNewPeriod => 'New period';

  @override
  String frmSinceMonth(String month) {
    return 'Since $month';
  }

  @override
  String get frmNoEndDate => 'No end date';

  @override
  String frmUntilMonth(String month) {
    return 'Until $month';
  }

  @override
  String get frmMainCategories => 'Main';

  @override
  String frmOnlyName(String name) {
    return 'Only $name';
  }

  @override
  String get frmNoSubcategories => 'This category has no subcategories.';

  @override
  String get frmSearchCategory => 'Search category';

  @override
  String get frmNoCategoriesYet =>
      'You don\'t have any categories yet. Create the first one.';

  @override
  String get frmNoCategoryFound => 'No category found.';

  @override
  String get frmNewCategoryTitle => 'New category';

  @override
  String get frmChooseMonth => 'Choose month';

  @override
  String get frmEnterName => 'Enter a name';

  @override
  String get frmMainCategoryExists =>
      'A main category with this name already exists';

  @override
  String frmSubcategoryExists(String parent) {
    return 'This subcategory already exists in $parent';
  }

  @override
  String get frmThisCategory => 'this category';

  @override
  String get frmRepeatedName => 'Repeated name';

  @override
  String frmRemoveSubQuestion(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count transactions will',
      one: 'The transaction will',
      zero: 'The $count transactions will',
    );
    return 'Remove “$name”? $_temp0 be left without a category (only after you save).';
  }

  @override
  String get frmEditCategory => 'Edit category';

  @override
  String get frmEditSubcategory => 'Edit subcategory';

  @override
  String get frmNewSubcategoryTitle => 'New subcategory';

  @override
  String get frmEditCategoryHint => 'Edit the details and subcategories';

  @override
  String get frmEditSubcategoryHint => 'Edit the details of this subcategory';

  @override
  String frmCreateSubsIn(String name) {
    return 'Create subcategories inside $name';
  }

  @override
  String get frmCreateCategoryHint => 'Create a category and its subcategories';

  @override
  String get frmSubcategoryName => 'Subcategory name';

  @override
  String get frmName => 'Name';

  @override
  String get frmParentCategory => 'Parent category';

  @override
  String get frmNoneMainCategory => 'None (main category)';

  @override
  String get frmHasSubsLock =>
      'It has subcategories, so it can\'t be a subcategory.';

  @override
  String get frmSubcategoryOf => 'Subcategory of ';

  @override
  String get frmCreatingSubcategoryOf => 'Creating a subcategory of ';

  @override
  String frmMoreSubsOf(String name) {
    return 'More subcategories of $name';
  }

  @override
  String get frmSubcategories => 'Subcategories';

  @override
  String get frmRemoveSubcategory => 'Remove subcategory';

  @override
  String get frmAddSubcategory => 'Add subcategory';

  @override
  String get frmOptions => 'Options';

  @override
  String get frmType => 'Type';

  @override
  String get frmOnlyInPeriod => 'Only exists for a period';

  @override
  String get frmOnlyInPeriodHint =>
      'E.g.: “Holidays 2027”. Outside the period it stops showing in the choices.';

  @override
  String get frmSince => 'Since';

  @override
  String get frmSetEnd => 'Set end';

  @override
  String get frmMandatoryIn => 'Mandatory in…';

  @override
  String get frmOptionalAllMonths => 'Optional in all months';

  @override
  String frmPeriodsDefined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count periods set',
      one: '1 period set',
      zero: '$count periods set',
    );
    return '$_temp0';
  }

  @override
  String get frmKindOptional => 'Optional expense';

  @override
  String get frmKindMandatory => 'Mandatory expense';

  @override
  String get frmKindIncome => 'Income';

  @override
  String get frmKindInvestment => 'Investment';

  @override
  String get frmKindBoth => 'Expenses and income';

  @override
  String get frmKindOptionalHelp =>
      'Spending you can cut (leisure, restaurants…).';

  @override
  String get frmKindMandatoryHelp =>
      'Fixed monthly spending (rent, insurance…). You can then pick only some months.';

  @override
  String get frmKindIncomeHelp =>
      'Money coming in (e.g. salary). Doesn\'t count as an expense.';

  @override
  String get frmKindInvestmentHelp =>
      'Money you put to work. Doesn\'t count as spending; it shows as invested.';

  @override
  String get frmKindBothHelp =>
      'Accepts spending and income (e.g. sales, refunds). Spending counts as an expense and income as income.';

  @override
  String get frmAccounts => 'Accounts';

  @override
  String get frmNewAccount => 'New account';

  @override
  String get frmEditAccount => 'Edit account';

  @override
  String get frmAccountNameHint => 'E.g.: Current account';

  @override
  String frmOpeningBalanceCurrency(String currency) {
    return 'Opening balance ($currency)';
  }

  @override
  String get frmOpeningBalanceHelp =>
      'How much you had in the account before the transactions recorded here.';

  @override
  String get frmNewAccountItem => 'New account…';

  @override
  String get frmNoAccount => 'No account';

  @override
  String get frmNoAccountsYet =>
      'You don\'t have any accounts yet.\nCreate one to see where each transaction comes from and to record transfers between accounts.';

  @override
  String frmAccountSubtitle(int count, String balance) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return '$_temp0 · balance $balance';
  }

  @override
  String frmDeleteAccountQuestion(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count transactions will',
      one: 'The transaction will',
      zero: 'The $count transactions will',
    );
    return 'Delete the account “$name”? $_temp0 be left without an account.';
  }

  @override
  String get frmAccountDeleted => 'Account deleted.';

  @override
  String get frmEdit => 'Edit';

  @override
  String get frmBalance => 'Balance';

  @override
  String frmOpeningBalanceLine(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return 'Opening balance $amount · $_temp0';
  }

  @override
  String get frmThisMonth => 'This month';

  @override
  String get frmMonthBalance => 'Month balance';

  @override
  String get frmGoalsFedByAccount => 'Goals fed by this account';

  @override
  String get frmNoGoalFunded => 'No goal receives money from this account yet.';

  @override
  String get frmNoTransactionsInAccount => 'No transactions in this account.';

  @override
  String get frmObWelcome => 'Welcome';

  @override
  String get frmObFirstAccount => 'First account';

  @override
  String get frmObSalary => 'Salary';

  @override
  String get frmObDone => 'Done';

  @override
  String get frmObEnterAmount1250 => 'Enter an amount, for example 1250.00';

  @override
  String get frmObEnterAmount1500 => 'Enter an amount, for example 1500.00';

  @override
  String get frmObWelcomeTitle => 'Welcome to Finances';

  @override
  String get frmObWelcomeText =>
      'Record the money that comes in and goes out, and see where it goes. Your data stays only on this phone, with no accounts or sharing.';

  @override
  String get frmObAccountTitle => 'What\'s your main account?';

  @override
  String get frmObAccountText =>
      'You can add more accounts later. If you don\'t want to now, leave it blank.';

  @override
  String get frmObAccountName => 'Account name';

  @override
  String get frmObSalaryTitle => 'How much do you get per month?';

  @override
  String get frmObSalaryText =>
      'Net salary. It\'s used for planning and to see how much you can still spend. You can change it or leave it blank.';

  @override
  String frmObSalaryField(String currency) {
    return 'Monthly net salary ($currency)';
  }

  @override
  String get frmObReadyTitle => 'You\'re all set';

  @override
  String get frmObReadyText =>
      'Add transactions by hand or import a statement. You can change everything later on the dedicated screens.';

  @override
  String get frmBack => 'Back';

  @override
  String get frmFinish => 'Finish';

  @override
  String get frmNext => 'Next';

  @override
  String get frmAll => 'All';

  @override
  String get frmExpenses => 'Expenses';

  @override
  String get frmTransfers => 'Transfers';

  @override
  String frmTransactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return '$_temp0';
  }

  @override
  String frmInvestmentOf(String name) {
    return 'Investment · $name';
  }

  @override
  String frmOfAmount(String amount) {
    return 'of $amount';
  }

  @override
  String get frmNoIncomeDefined => 'no income set';

  @override
  String get frmSetSalaryToSpend =>
      'Set your salary in Budget to see how much you can still spend.';

  @override
  String frmOverPlanned(String amount) {
    return 'You\'re $amount over plan';
  }

  @override
  String get frmIncomeExpected => 'Income (expected)';

  @override
  String frmPercentOfIncome(int percent) {
    return '$percent% of income';
  }

  @override
  String frmToClassify(int count) {
    return '$count to classify';
  }

  @override
  String frmDeliveriesCount(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deliveries',
      one: '1 delivery',
      zero: '$count deliveries',
    );
    return '$_temp0 · $total';
  }

  @override
  String get frmSetSalaryLeft =>
      'Set your salary in Budget to see what\'s left.';

  @override
  String frmPlanExceeds(String amount) {
    return 'The plan exceeds the salary by $amount';
  }

  @override
  String frmSavedOfTarget(String saved, String target, String deadline) {
    return '$saved of $target$deadline';
  }

  @override
  String frmUntilDate(String date) {
    return ' · until $date';
  }

  @override
  String get impImportTitle => 'Import Statement';

  @override
  String get impFormatsInfo =>
      'Supported formats: PDF (with text), CSV and Excel (.xlsx). The file is read only on the phone and never leaves it.';

  @override
  String get impChooseFile => 'Choose file';

  @override
  String get impChooseOtherFile => 'Choose another file';

  @override
  String impFileName(String name) {
    return 'File: $name';
  }

  @override
  String get impPdfNoRows =>
      'No transactions found in this PDF. It may be a scanned (image) PDF or a different format. Try exporting CSV/Excel from your online banking.';

  @override
  String get impCsvNoRows =>
      'Couldn\'t read any transactions. Adjust the columns below.';

  @override
  String impReadError(String error) {
    return 'Error reading the file: $error';
  }

  @override
  String get impStatementAccount => 'Account for this statement';

  @override
  String get impPickAccountOptional => 'Select an account (optional)';

  @override
  String impTxnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return '$_temp0';
  }

  @override
  String impIncomeExpense(String income, String expense) {
    return 'Income $income   ·   Expenses $expense';
  }

  @override
  String get impInvertSigns => 'Invert signs';

  @override
  String get impInvertSignsHint => 'Use this if expenses show as positive';

  @override
  String impImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count transactions',
      one: 'Import 1 transaction',
      zero: 'Import $count transactions',
    );
    return '$_temp0';
  }

  @override
  String impImportDone(int added, int duplicates, int unclassified) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added imported',
      one: '1 imported',
      zero: '$added imported',
    );
    String _temp1 = intl.Intl.pluralLogic(
      duplicates,
      locale: localeName,
      other: '$duplicates duplicates skipped',
      one: '1 duplicate skipped',
      zero: '$duplicates duplicates skipped',
    );
    String _temp2 = intl.Intl.pluralLogic(
      unclassified,
      locale: localeName,
      other: '$unclassified groups to classify.',
      one: '1 group to classify.',
      zero: '$unclassified groups to classify.',
    );
    return '$_temp0, $_temp1. $_temp2';
  }

  @override
  String impClassifiedOf(int classified, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total groups',
      one: '1 group',
      zero: '$total groups',
    );
    return 'Classified: $classified of $_temp0';
  }

  @override
  String get impGroupsExplain =>
      'Transactions with the same name are grouped together. Choose the category and subcategory for each group (or leave it unclassified). Rules you already saved are filled in.';

  @override
  String impTransfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers between accounts',
      one: '1 transfer between accounts',
      zero: '$count transfers between accounts',
    );
    return '$_temp0';
  }

  @override
  String get impTransfersHint =>
      'They don\'t need a category and are kept out of expenses and income.';

  @override
  String impOriginal(String description) {
    return 'Original: $description';
  }

  @override
  String impActiveOfTotal(int active, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total transactions',
      one: '1 transaction',
      zero: '$total transactions',
    );
    return '$active of $_temp0';
  }

  @override
  String get impRememberedRule => ' · remembered rule';

  @override
  String get impNameOrGroup => 'Name or group (optional)';

  @override
  String get impNameHint => 'E.g.: Gym, Arminda Restaurant…';

  @override
  String impJoinsGroup(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
      zero: '$count titles',
    );
    return 'Joins the group “$name” ($_temp0)';
  }

  @override
  String get impRememberNameCategory =>
      'Remember name and category for the future';

  @override
  String get impViewTransactions => 'View transactions';

  @override
  String get impAccountsInStatement => 'Accounts in this statement';

  @override
  String impAccountsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts detected',
      one: '1 account detected',
      zero: '$count accounts detected',
    );
    return '$_temp0. Choose the one that matches each in the app.';
  }

  @override
  String impAccountTxns(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String impCreateAccount(String name) {
    return '➕  Create account “$name”';
  }

  @override
  String get impNoAccount => 'No account';

  @override
  String get impDetectTransfers => 'Detect transfers between these accounts';

  @override
  String get impDetectTransfersHint =>
      'An outflow from one account and an inflow to another of the same amount don\'t count as expense or income.';

  @override
  String impSkippedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines look like transactions but were not recognized',
      one: '1 line looks like transactions but was not recognized',
      zero: '$count lines look like transactions but were not recognized',
    );
    return '$_temp0';
  }

  @override
  String impSkippedSub(int count) {
    return 'Read: $count. Tap to see the skipped lines.';
  }

  @override
  String impAndMore(int count) {
    return '… and $count more';
  }

  @override
  String get impSkippedHelp =>
      'If this is a statement from your bank, export it as CSV/Excel from online banking, or send me an example (with the data hidden) so I can adjust the reader.';

  @override
  String get impYearForDates => 'Year for dates without a year';

  @override
  String get impYearHint => 'Only affects dates written as dd-mm';

  @override
  String get impFileColumns => 'File columns';

  @override
  String get impHeaderRow => 'Header row';

  @override
  String get impDate => 'Date';

  @override
  String get impDescription => 'Description';

  @override
  String get impAmountSigned => 'Amount (signed)';

  @override
  String get impDebitOut => 'Debit (outflows)';

  @override
  String get impCreditIn => 'Credit (inflows)';

  @override
  String get impBalanceOptional => 'Balance (optional)';

  @override
  String get impDoNotUse => '— don\'t use —';

  @override
  String impColumnN(int n) {
    return 'Column $n';
  }

  @override
  String get impClassifyTitle => 'Classify';

  @override
  String get impClassifySubtitle =>
      'Review and categorize your imported transactions';

  @override
  String get impSort => 'Sort';

  @override
  String get impSortCount => 'Most transactions';

  @override
  String get impSortTotal => 'Highest amount';

  @override
  String get impSortRecent => 'Most recent';

  @override
  String get impSortName => 'Name (A-Z)';

  @override
  String get impGroups => 'Groups';

  @override
  String get impRules => 'Remembered rules';

  @override
  String get impSearchGroups => 'Search groups or merchants…';

  @override
  String impToClassifyChip(int count) {
    return 'To classify ($count)';
  }

  @override
  String get impAll => 'All';

  @override
  String get impApplyRules => 'Apply rules';

  @override
  String impClassifiedByRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions classified by the rules.',
      one: '1 transaction classified by the rules.',
      zero: '$count transactions classified by the rules.',
    );
    return '$_temp0';
  }

  @override
  String get impAllClassified => 'All classified! 🎉';

  @override
  String get impNoTransactionsYet => 'No transactions yet.';

  @override
  String impClassifiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions classified.',
      one: '1 transaction classified.',
      zero: '$count transactions classified.',
    );
    return '$_temp0';
  }

  @override
  String get impSelectAll => 'Select all';

  @override
  String impApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return 'Apply to $_temp0';
  }

  @override
  String impTxnCountDate(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return '$_temp0 · $date';
  }

  @override
  String impGroupChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
      zero: '$count titles',
    );
    return 'Group · $_temp0';
  }

  @override
  String get impRemembered => 'Remembered';

  @override
  String impSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get impChooseCategory => 'Choose a category';

  @override
  String impMoveTo(String category) {
    return 'Move to $category';
  }

  @override
  String get impRememberForFuture => 'Remember for future';

  @override
  String get impWhatIsThis => 'What is this?';

  @override
  String get impRememberHelp =>
      'Saves a rule: the next time a transaction with this title appears, the app immediately applies the name and category you chose.';

  @override
  String get impOk => 'OK';

  @override
  String get impNameAndNotes => 'Name and notes';

  @override
  String get impForgetRule => 'Forget rule';

  @override
  String impForgetRuleQuestion(String key) {
    return 'Forget the rule for “$key”? Transactions already classified stay that way.';
  }

  @override
  String get impForget => 'Forget';

  @override
  String get impJoinGroup => 'Join group';

  @override
  String get impManageGroup => 'Manage group';

  @override
  String get impJoinAGroup => 'Join a group';

  @override
  String get impFriendlyName => 'Friendly name (optional)';

  @override
  String get impExampleGym => 'E.g.: Gym';

  @override
  String get impRuleDescription => 'Rule description (optional)';

  @override
  String get impNoteAllTx => 'Note on all transactions (optional)';

  @override
  String get impNameSavedHint =>
      'The name and description are saved with the rule for future imports.';

  @override
  String get impSave => 'Save';

  @override
  String get impNoRules =>
      'No rules yet. When you move transactions with “Remember”, the rules show up here.';

  @override
  String get impEquals => 'Equals';

  @override
  String get impContains => 'Contains';

  @override
  String get impRule => 'Rule';

  @override
  String get impNewRule => 'New rule';

  @override
  String get impEditRule => 'Edit rule';

  @override
  String get impTextToRecognize => 'Text to match (UPPERCASE)';

  @override
  String get impExactName => 'Exact name match';

  @override
  String get impExactNameOff => 'Off: containing the text is enough';

  @override
  String get impDescriptionOptional => 'Description (optional)';

  @override
  String get impNewGroup => 'New group';

  @override
  String get impName => 'Name';

  @override
  String get impExampleRestaurant => 'E.g.: Arminda Restaurant';

  @override
  String get impCreate => 'Create';

  @override
  String get impGroupsEmpty =>
      'You don\'t have any groups yet.\n\nA group joins different titles that are the same thing, for example “TRANS RESTAURANTE ARMINDA” and “MB WAY RESTAURANTE ARMINDA” → “Restaurante Arminda”, with a single category.';

  @override
  String get impDeleteGroup => 'Delete group';

  @override
  String get impGroupDeleted => 'Group deleted.';

  @override
  String impDeleteGroupQuestion(String name) {
    return 'Delete the group “$name”? The titles keep the name and category they had in the group, but are no longer grouped together.';
  }

  @override
  String get impJoinTitles => 'Join titles';

  @override
  String get impGroupName => 'Group name';

  @override
  String get impGroupSaved => 'Group saved.';

  @override
  String impGroupExists(String name) {
    return 'A group named “$name” already exists.';
  }

  @override
  String impTitlesInGroup(int count) {
    return 'Titles in this group ($count)';
  }

  @override
  String get impGroupAnyTitle =>
      'Any transaction with one of these titles gets the group\'s name and category, now and in future imports.';

  @override
  String get impGroupEmptyHint => 'Still empty. Use “Join titles”.';

  @override
  String get impRemoveFromGroup => 'Remove from group';

  @override
  String get impSearchTitles => 'Search titles';

  @override
  String get impNoTitlesFound => 'No titles found.';

  @override
  String impAlreadyInGroup(String name) {
    return ' · already in “$name”';
  }

  @override
  String get impOrAnyTitle => 'Or: any title containing…';

  @override
  String get impJoin => 'Join';

  @override
  String impTitleLabel(String title) {
    return 'Title: $title';
  }

  @override
  String impTitlesList(int count, String list) {
    return '$count titles: $list';
  }

  @override
  String get impExistingGroup => 'Existing group';

  @override
  String get impOr => 'or';

  @override
  String impExistsJoins(String name) {
    return 'Already exists: will join “$name”';
  }

  @override
  String impTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
      zero: '$count titles',
    );
    return '$_temp0';
  }

  @override
  String get invAdd => 'Add';

  @override
  String get invRecordOperation => 'Record operation';

  @override
  String get invRecordOperationHint =>
      'Buy, sell, dividend or what you already had';

  @override
  String get invImportFromFile => 'Import from a file';

  @override
  String get invImportFileHint => 'PDF, CSV or Excel from your broker';

  @override
  String get invNewHolding => 'New asset';

  @override
  String get invNewHoldingHint => 'ETF, stock, crypto, fund…';

  @override
  String get invNewAccount => 'New platform';

  @override
  String get invNewAccountHint => 'XTB, Trade Republic, exchange…';

  @override
  String get invTitle => 'Investments';

  @override
  String get invImportTrades => 'Import buys and sells';

  @override
  String get invRefreshPrices => 'Update prices';

  @override
  String get invImportCardHint =>
      'Pick a PDF, CSV or Excel file from your broker';

  @override
  String get invMyPortfolio => 'My portfolio';

  @override
  String get invTotalValue => 'Total value';

  @override
  String get invInvested => 'Invested';

  @override
  String get invCurrentValue => 'Current value';

  @override
  String get invGainLoss => 'Gain / loss';

  @override
  String get invUnallocated => 'Unallocated';

  @override
  String get invUnallocatedStandby => 'Unallocated (standby)';

  @override
  String get invRealizedGain => 'Realized gain';

  @override
  String get invDividends => 'Dividends';

  @override
  String invPricesUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prices updated.',
      one: '1 price updated.',
      zero: '$count prices updated.',
    );
    return '$_temp0';
  }

  @override
  String invPricesFailed(String details) {
    return 'Failed: $details';
  }

  @override
  String get invNoAutoPrices => 'No asset with an automatic price.';

  @override
  String invPricesUpdatedAgo(String ago) {
    return 'Prices updated $ago';
  }

  @override
  String get invNoPricesYet => 'No prices yet. Tap refresh.';

  @override
  String get invPricesManual => 'Prices set by hand for each asset.';

  @override
  String get invUnpricedNote =>
      'Assets without a price count at cost, so the total is not skewed.';

  @override
  String get invWhereMoneyIs => 'Where the money is';

  @override
  String get invByAsset => 'By asset';

  @override
  String get invByPlatform => 'By platform';

  @override
  String get invByType => 'By type';

  @override
  String get invTotal => 'Total';

  @override
  String get invCashToAllocate => 'Cash to allocate';

  @override
  String get invCashSubtitle =>
      'Sent to the platforms and not invested yet (standby)';

  @override
  String get invNegativeCashHint =>
      'Negative: a transfer or a cash adjustment is missing';

  @override
  String get invAllocate => 'Allocate';

  @override
  String get invAdjust => 'Adjust';

  @override
  String get invPlatforms => 'Platforms';

  @override
  String invAssetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assets',
      one: '1 asset',
      zero: '$count assets',
    );
    return '$_temp0';
  }

  @override
  String invAccountLine(String cash, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assets',
      one: '1 asset',
      zero: '$count assets',
    );
    return 'Unallocated $cash · $_temp0';
  }

  @override
  String get invIntroTitle => 'Track what you\'ve invested';

  @override
  String get invIntroSubtitle =>
      'Where your money is, what it is worth and what is still unallocated';

  @override
  String get invStep1Title => '1. Create a platform';

  @override
  String get invStep1Desc => 'XTB, Trade Republic, a crypto exchange…';

  @override
  String get invStep2Title => '2. Link bank transfers';

  @override
  String get invStep2Desc =>
      'Mark which ones were money sent to the platform. They stop counting as expenses.';

  @override
  String get invStep3Title => '3. Say what you already had';

  @override
  String get invStep3Desc =>
      'Quantity and average purchase price of what you invested before using the app.';

  @override
  String get invStep4Title => '4. Allocate the money';

  @override
  String get invStep4Desc =>
      'Record purchases. What is left stays unallocated (standby).';

  @override
  String get invStep5Title => '5. Update prices';

  @override
  String get invStep5Desc =>
      'With free APIs (Yahoo Finance and CoinGecko), only when you ask.';

  @override
  String get invCreateFirstPlatform => 'Create the first platform';

  @override
  String get invImportFromFileButton => 'Import buys and sells from a file';

  @override
  String invTopAssetWeight(String label, String share) {
    return '$label makes up $share of the portfolio.';
  }

  @override
  String get invKindEtf => 'ETF';

  @override
  String get invKindStock => 'Stock';

  @override
  String get invKindCrypto => 'Crypto';

  @override
  String get invKindFund => 'Fund';

  @override
  String get invKindBond => 'Bond';

  @override
  String get invKindOther => 'Other';

  @override
  String get invProviderManual => 'Manual';

  @override
  String get invProviderYahoo => 'Yahoo Finance';

  @override
  String get invProviderCoingecko => 'CoinGecko';

  @override
  String get invOpInitial => 'Opening position';

  @override
  String get invOpBuy => 'Buy';

  @override
  String get invOpSell => 'Sell';

  @override
  String get invOpDividend => 'Dividend';

  @override
  String get invOpCash => 'Cash adjustment';

  @override
  String invAddToAccount(String name) {
    return 'Add to $name';
  }

  @override
  String invDeleteAccountConfirm(String name) {
    return 'Delete the platform “$name” with its assets and transactions? Bank transactions stay (they are no longer linked).';
  }

  @override
  String get invSummary => 'Summary';

  @override
  String get invCashAccountSubtitle =>
      'What is on the platform and not invested yet';

  @override
  String get invBankDepositsNet => 'Bank transfers in (net)';

  @override
  String get invCashAdjustments => 'Cash adjustments';

  @override
  String get invSales => 'Sales';

  @override
  String get invPurchases => 'Purchases';

  @override
  String get invNegativeAccountCash =>
      'The amount is negative: you spent more than the recorded money. Link the bank transfer or adjust the cash that was already there.';

  @override
  String get invAllocateMoney => 'Allocate money';

  @override
  String get invBankTransfers => 'Bank transfers';

  @override
  String invMarkTransfersFor(String name) {
    return 'Mark which were money sent to $name';
  }

  @override
  String invLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linked · not counted as expenses',
      one: '1 linked · not counted as an expense',
      zero: '$count linked · not counted as expenses',
    );
    return '$_temp0';
  }

  @override
  String get invLinkBankTransfers => 'Link bank transfers';

  @override
  String invSuggestedMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions look like they belong to this platform',
      one: '1 transaction looks like it belongs to this platform',
      zero: '$count transactions look like they belong to this platform',
    );
    return '$_temp0';
  }

  @override
  String invSuggestedBody(String name) {
    return 'They have “$name” in the name. Tap to review and link.';
  }

  @override
  String get invUnlink => 'Unlink';

  @override
  String get invDeliveryLower => 'deposit';

  @override
  String get invWithdrawalLower => 'withdrawal';

  @override
  String invAndMore(int count) {
    return '… and $count more';
  }

  @override
  String get invRememberedTitles => 'Titles remembered for future imports';

  @override
  String get invAssets => 'Assets';

  @override
  String get invNew => 'New';

  @override
  String get invNoAssetsYet =>
      'No assets yet. Create one (e.g. the ETF or stock you bought) and record the position you already had or a purchase.';

  @override
  String get invHistory => 'History';

  @override
  String get invTapToEdit => 'Tap to edit';

  @override
  String get invEdit => 'Edit';

  @override
  String get invHoldingDeleted => 'Asset deleted.';

  @override
  String get invHoldingDeletedShort => 'Asset deleted';

  @override
  String get invAccountDeleted => 'Platform deleted.';

  @override
  String get invTransferDeleted => 'Transfer deleted.';

  @override
  String get invTransfersTitle => 'Transfers to invest';

  @override
  String invTapToAssignWithAmount(String amount) {
    return 'Tap one to say which purchases used it. To invest: $amount';
  }

  @override
  String get invTapToAssign => 'Tap one to say which purchases used it';

  @override
  String invSeeAll(int count) {
    return 'See all ($count)';
  }

  @override
  String get invNoTransfersYet =>
      'You have not linked any bank transfers to a platform yet.';

  @override
  String get invNothingAssigned =>
      'Nothing assigned yet · tap to choose the purchases';

  @override
  String invAllocationSummary(String allocated, String holdText) {
    return 'Invested $allocated · $holdText';
  }

  @override
  String invOnHoldLower(String amount) {
    return 'on hold $amount';
  }

  @override
  String invOverAllocatedLower(String amount) {
    return '$amount more than the transfer';
  }

  @override
  String invInvestedAmount(String amount) {
    return 'Invested $amount';
  }

  @override
  String invOnHold(String amount) {
    return 'On hold $amount';
  }

  @override
  String invMoreThanAmount(String amount) {
    return '$amount over';
  }

  @override
  String get invUseTransfer => 'Use this transfer';

  @override
  String get invPlatformDefault => 'Platform';

  @override
  String get invThePlatform => 'the platform';

  @override
  String invTransferTo(String amount, String name) {
    return '$amount to $name';
  }

  @override
  String get invOverAllocatedNote =>
      'The chosen purchases add up to more than the transfer. Some money must have come in before; you can continue.';

  @override
  String invHoldRemainder(String amount) {
    return '$amount of this transfer is on hold, not invested yet.';
  }

  @override
  String get invSuggest => 'Suggest';

  @override
  String get invClearAll => 'Clear (all on hold)';

  @override
  String get invSaveAllOnHold => 'Save (all on hold)';

  @override
  String get invSave => 'Save';

  @override
  String get invBuysOnPlatform => 'Purchases on this platform';

  @override
  String get invMarkBuysHint => 'Mark the ones paid with this transfer.';

  @override
  String get invNoBuysYet => 'No purchases recorded on this platform yet.';

  @override
  String get invUsedElsewhere => 'used in another transfer';

  @override
  String invUnits(String qty) {
    return '$qty units';
  }

  @override
  String get invSetPrice => 'Set price';

  @override
  String get invSetPriceManual => 'Set by hand';

  @override
  String invPricePerUnit(String currency) {
    return 'Price per unit ($currency)';
  }

  @override
  String invFxRate(String base, String currency) {
    return 'Exchange rate: 1 $base = ? $currency';
  }

  @override
  String get invCurrentPrice => 'Current price';

  @override
  String get invNoPrice => 'No price';

  @override
  String invCurrencyChip(String currency, String mode) {
    return 'Currency: $currency · $mode';
  }

  @override
  String get invCurrencyChosen => 'chosen';

  @override
  String get invCurrencyAuto => 'automatic';

  @override
  String invUpdatedAgo(String ago, String date) {
    return 'Updated $ago · $date';
  }

  @override
  String get invRefreshPrice => 'Refresh price';

  @override
  String get invPriceUpdated => 'Price updated.';

  @override
  String invRefreshFailedReason(String reason) {
    return 'Could not update: $reason';
  }

  @override
  String get invErrorWord => 'error';

  @override
  String invDeleteHoldingConfirm(String name) {
    return 'Delete the asset “$name” and its transactions?';
  }

  @override
  String get invMyPosition => 'My position';

  @override
  String get invNoPositionYet =>
      'No position yet. Record the quantity and average price of what you already had, or a purchase.';

  @override
  String get invQuantity => 'Quantity';

  @override
  String get invAvgCost => 'Average purchase price';

  @override
  String invGainIn(String currency) {
    return 'Gain in $currency';
  }

  @override
  String get invPriceOnly => 'price only';

  @override
  String get invSetPriceToSeePl =>
      'Set the current price to see the gain or loss.';

  @override
  String get invBuy => 'Buy';

  @override
  String get invSell => 'Sell';

  @override
  String get invOperations => 'Transactions';

  @override
  String invFeeLabel(String amount) {
    return 'fee $amount';
  }

  @override
  String get invPlanTitle => 'Investment plan';

  @override
  String get invPlanCardDesc =>
      'When a transfer comes into a platform, the Portfolio shows how much goes to each asset. The app does not record purchases.';

  @override
  String get invNoPlan => 'No plan';

  @override
  String invMissingPercent(String pct) {
    return '$pct% left to allocate';
  }

  @override
  String invPlanOf(String name) {
    return 'Plan for $name';
  }

  @override
  String get invPlanEditorHint =>
      'Percentage of each transfer for each asset. You can leave part of it unallocated.';

  @override
  String get invPlanNoAssets =>
      'This platform has no assets yet. Add assets in the Portfolio.';

  @override
  String invPlanOver(String pct) {
    return 'Over 100% by $pct%.';
  }

  @override
  String invPlanTotal(String pct) {
    return 'Total: $pct%';
  }

  @override
  String get invSumOver100 => 'The total cannot exceed 100%.';

  @override
  String get invInvalidValue => 'Invalid value.';

  @override
  String get invSavePlan => 'Save plan';

  @override
  String get invRemovePlan => 'Remove plan';

  @override
  String invPendingDeliveries(int count) {
    return 'Transfers to allocate ($count)';
  }

  @override
  String invUndistributed(String amount) {
    return 'To allocate: $amount';
  }

  @override
  String get invSeen => 'Seen';

  @override
  String get invAvgShort => 'avg';

  @override
  String get invNoPriceShort => 'no price';

  @override
  String get invClosedPosition => 'Closed position';

  @override
  String get invfAccountNewTitle => 'New platform';

  @override
  String get invfAccountEditTitle => 'Edit platform';

  @override
  String get invfName => 'Name';

  @override
  String get invfAccountNameHint => 'e.g. XTB, Trade Republic';

  @override
  String get invfNoteOptional => 'Note (optional)';

  @override
  String get invfNote => 'Note';

  @override
  String get invfSave => 'Save';

  @override
  String get invfSaveChanges => 'Save changes';

  @override
  String get invfEnterName => 'Enter a name';

  @override
  String get invfAccountNameTaken => 'A platform with this name already exists';

  @override
  String invfSearchIn(String provider) {
    return 'Search in $provider';
  }

  @override
  String get invfCryptoSearchHint => 'e.g. bitcoin';

  @override
  String get invfSymbolSearchHint => 'e.g. VWCE, Apple, S&P 500';

  @override
  String get invfSearchFailed => 'Couldn’t search.';

  @override
  String get invfNothingFound => 'Nothing found.';

  @override
  String get invfClose => 'Close';

  @override
  String get invfHoldingNewTitle => 'New asset';

  @override
  String get invfHoldingEditTitle => 'Edit asset';

  @override
  String get invfHoldingNameHint => 'e.g. Vanguard FTSE All-World';

  @override
  String get invfPlatform => 'Platform';

  @override
  String get invfType => 'Type';

  @override
  String get invfAssetCurrency => 'Asset currency';

  @override
  String get invfAutoCurrency => 'Automatic (from the price)';

  @override
  String invfBaseCurrencyOption(String ccy) {
    return '$ccy · base currency';
  }

  @override
  String invfCurrencyAutoHint(String ccy) {
    return 'Uses the currency the asset is quoted in ($ccy). You can pick another one manually.';
  }

  @override
  String get invfDetectedOnPrice => 'detected when fetching the price';

  @override
  String get invfUsdHint =>
      'For stocks or ETFs in dollars, choose USD: purchase prices stay in the asset’s currency, with the exchange rate of each purchase.';

  @override
  String invfForeignCcyHint(String ccy) {
    return 'Purchases and average price stay in $ccy; the portfolio value and gain are converted to the base currency at the market rate (updated in “Update prices”).';
  }

  @override
  String invfPriceWithCcy(String ccy) {
    return 'Price ($ccy)';
  }

  @override
  String invfAvgPriceWithCcy(String ccy) {
    return 'Average price ($ccy)';
  }

  @override
  String get invfYahooHint =>
      'Free, no key needed. ETFs, stocks and exchange rates (e.g. VWCE.DE, AAPL, BTC-EUR). Converts to euros.';

  @override
  String get invfCoingeckoHint =>
      'Free, no key needed. Cryptocurrencies, by id (e.g. bitcoin, ethereum).';

  @override
  String get invfManualHint =>
      'You set the price whenever you like. Nothing is sent to the internet.';

  @override
  String get invfCoingeckoId => 'CoinGecko id';

  @override
  String get invfNewPlatformItem => '➕  New platform…';

  @override
  String get invfSymbol => 'Symbol';

  @override
  String get invfPrice => 'Price';

  @override
  String get invfSearchTooltip => 'Search';

  @override
  String invfCurrentPriceOptional(String ccy) {
    return 'Current price ($ccy, optional)';
  }

  @override
  String invfFxLabel(String base, String ccy) {
    return 'Exchange rate: 1 $base = ? $ccy';
  }

  @override
  String invfFxRateLabel(String base, String ccy) {
    return 'Exchange rate (1 $base = ? $ccy)';
  }

  @override
  String invfAvgFxLabel(String base, String ccy) {
    return 'Average exchange rate (1 $base = ? $ccy)';
  }

  @override
  String get invfLiveFxTooltip => 'Current market exchange rate (internet)';

  @override
  String invfFxFetchFailed(String message) {
    return 'Couldn’t get the exchange rate: $message';
  }

  @override
  String invfPriceFetchFailed(String message) {
    return 'Couldn’t get the price: $message';
  }

  @override
  String get invfSymbolRequired => 'Enter the symbol (or use search)';

  @override
  String get invfFxOrSyncRequired =>
      'Enter the exchange rate, or use the sync button for the market rate.';

  @override
  String invfCurrencyPickerHint(String base) {
    return 'The value is converted to $base at the market rate, updated in “Update prices”. Transactions already recorded keep the values they have.';
  }

  @override
  String get invfOpNewTitle => 'New transaction';

  @override
  String invfOpEditTitle(String type) {
    return 'Edit · $type';
  }

  @override
  String get invfOpInitial => 'Opening position';

  @override
  String get invfOpBuy => 'Buy';

  @override
  String get invfOpSell => 'Sell';

  @override
  String get invfOpDividend => 'Dividend';

  @override
  String get invfOpCash => 'Cash adjustment';

  @override
  String get invfOpAlreadyHeld => 'Already held';

  @override
  String get invfOpCashChip => 'Cash';

  @override
  String get invfPlatformLower => 'platform';

  @override
  String invfTotalToPay(String amount) {
    return 'Total to pay: $amount';
  }

  @override
  String invfTotalToPayFee(String amount, String fee) {
    return 'Total to pay: $amount (incl. $fee fee)';
  }

  @override
  String get invfNoAllocationHint =>
      'No allocation: nothing is deducted from unallocated cash. You can record the bank transfer whenever you like.';

  @override
  String invfNotEnoughUnallocated(String amount, String cash) {
    return 'You don’t have $amount unallocated on this platform yet (you have $cash). Record the bank transfer later, or turn off “Deduct from unallocated cash” in More options.';
  }

  @override
  String invfUnallocatedChange(String before, String after) {
    return 'Unallocated cash: $before → $after.';
  }

  @override
  String invfUnallocatedChangeTitle(String before, String after) {
    return 'Unallocated cash: $before → $after';
  }

  @override
  String invfBalanceChange(String before, String after) {
    return '$before → $after.';
  }

  @override
  String invfYouReceive(String amount) {
    return 'You receive $amount';
  }

  @override
  String invfRealizedGain(String gain, String avg) {
    return 'Realized gain: $gain (average price $avg).';
  }

  @override
  String invfPositionCost(String amount) {
    return 'Position cost: $amount';
  }

  @override
  String get invfInitialHint =>
      'Position you already held before using the app. Sets the average purchase price and doesn’t touch unallocated cash.';

  @override
  String invfDividendIn(String amount) {
    return '$amount added to unallocated cash';
  }

  @override
  String get invfCashHint =>
      'Use this for cash that was already on the platform before you started using the app.';

  @override
  String invfValueWithCcy(String base) {
    return 'Amount ($base)';
  }

  @override
  String invfReceivedWithCcy(String base) {
    return 'Amount received ($base)';
  }

  @override
  String invfFeeWithCcy(String base) {
    return 'Fee ($base)';
  }

  @override
  String get invfQuantity => 'Quantity';

  @override
  String invfUnitsEquals(String qty) {
    return '= $qty units';
  }

  @override
  String get invfCashIn => 'Money in';

  @override
  String get invfCashOut => 'Money out';

  @override
  String get invfDate => 'Date';

  @override
  String get invfHolding => 'Asset';

  @override
  String get invfNewAssetItem => '➕  New asset…';

  @override
  String get invfChoosePlatformHint => 'Choose platform';

  @override
  String get invfChoosePlatformShort => 'Choose the platform';

  @override
  String get invfChoosePlatform => 'Choose the platform.';

  @override
  String get invfChooseAsset => 'Choose the asset (or create one).';

  @override
  String get invfEnterValidAmounts => 'Enter valid amounts.';

  @override
  String invfFxRequired(String base, String ccy) {
    return 'Enter the exchange rate (1 $base = ? $ccy).';
  }

  @override
  String get invfEnterQtyPrice => 'Enter the quantity and price.';

  @override
  String invfOnlyHaveUnits(String qty) {
    return 'You only have $qty units to sell.';
  }

  @override
  String get invfMoreOptionsTrade => 'More options (fee, note…)';

  @override
  String get invfDeductUnallocated => 'Deduct from unallocated cash';

  @override
  String get invfDeductHint =>
      'Turn off if you haven’t recorded the bank transfer to the platform yet, or if this transaction is already counted elsewhere.';

  @override
  String get invfUseTotalInstead =>
      'Enter the total amount instead of the quantity';

  @override
  String invfAssetCurrencyChange(String ccy) {
    return 'Asset currency: $ccy · change';
  }

  @override
  String get invfHasInitialTitle =>
      'This asset already has an opening position';

  @override
  String get invfHasInitialBody =>
      'It’s loaded here. Saving replaces the previous one.';

  @override
  String get invfDeleteOp => 'Delete transaction';

  @override
  String invfLinkTitle(String name) {
    return 'Link to $name';
  }

  @override
  String get invfLinkButton => 'Link';

  @override
  String invfLinkCount(int count, String amount) {
    return 'Link $count ($amount to the platform)';
  }

  @override
  String get invfLinkHint =>
      'Choose the bank transactions that were money sent to (or received from) this platform. They stop counting as expenses.';

  @override
  String get invfSearchTransactions => 'Search transactions';

  @override
  String get invfNoTransactionsToLink => 'No transactions to link.';

  @override
  String get invfLooksLikeThis => ' · looks like this platform';

  @override
  String get invfRememberTitles => 'Remember these titles';

  @override
  String get invfRememberHint =>
      'In future imports, transactions with the same title are linked automatically.';

  @override
  String get invfImportTitle => 'Import buys and sells';

  @override
  String get invfImportIntro =>
      'Formats: PDF (with text), CSV and Excel (.xlsx). The file is read on your phone and never leaves it. Recognizes buys, sells and dividends; everything else (deposits, taxes…) is ignored.';

  @override
  String get invfChooseFile => 'Choose file';

  @override
  String get invfChooseOtherFile => 'Choose another file';

  @override
  String invfFileName(String name) {
    return 'File: $name';
  }

  @override
  String invfReadError(String error) {
    return 'Error reading the file: $error';
  }

  @override
  String get invfExcelNoData => 'The Excel file has no data.';

  @override
  String get invfPdfNotFound =>
      'I couldn’t find any buys or sells in this PDF. It may be scanned (an image) or use a different format. If your broker allows it, export it as CSV or Excel.';

  @override
  String get invfNotFoundTrades =>
      'I couldn’t find any buys or sells. Indicate below which column is which.';

  @override
  String get invfNotFoundWithColumns =>
      'I couldn’t find any buys or sells with these columns.';

  @override
  String get invfCurrencyAndRate => 'Currency and exchange rate';

  @override
  String invfCurrencyIntro(String base) {
    return 'Rows without a currency use the currency below. For currencies other than $base, enter the average exchange rate; you can adjust each transaction later.';
  }

  @override
  String get invfTransactionCurrency => 'Transaction currency';

  @override
  String invfAllInBase(String base) {
    return 'All transactions are in $base.';
  }

  @override
  String get invfAssetsFound => 'Assets found';

  @override
  String get invfAssetsHint =>
      'Link each one to one of your assets, create a new one, or ignore it.';

  @override
  String invfTradeCountLabel(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '$count transaction',
      zero: '$count transactions',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String get invfCreateNewAsset => '➕  Create new asset';

  @override
  String get invfIgnore => 'Ignore';

  @override
  String get invfOperations => 'Transactions';

  @override
  String invfBuysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buys',
      one: '$count buy',
      zero: '$count buys',
    );
    return '$_temp0';
  }

  @override
  String invfSellsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '$count sale',
      zero: '$count sales',
    );
    return '$_temp0';
  }

  @override
  String invfDividendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dividends',
      one: '$count dividend',
      zero: '$count dividends',
    );
    return '$_temp0';
  }

  @override
  String invfDuplicatesIgnored(int count) {
    return '$count already existing (skipped)';
  }

  @override
  String get invfMissingRate => 'Exchange rate missing';

  @override
  String invfMissingRateBody(String currencies) {
    return 'Enter the exchange rate for $currencies to import these transactions.';
  }

  @override
  String get invfAllCurrencies => 'all currencies';

  @override
  String invfMissingQtyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions without quantity',
      one: '1 transaction without quantity',
      zero: '$count transactions without quantity',
    );
    return '$_temp0';
  }

  @override
  String get invfMissingQtyBody =>
      'The file only has the amount paid. Choose the column that has the quantity and price (e.g. the comment) under “File columns”.';

  @override
  String invfShowingFirst(int total) {
    return 'Showing the first 300 of $total.';
  }

  @override
  String get invfAlreadyExists => ' · already exists';

  @override
  String invfTradeQtyPart(String qty, String price, String ccy) {
    return ' · $qty units × $price $ccy';
  }

  @override
  String invfImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '0 transactions',
    );
    return 'Import $_temp0';
  }

  @override
  String get invfFileColumns => 'File columns';

  @override
  String get invfAutoRecognized => 'Recognized automatically. Tap to adjust.';

  @override
  String get invfIndicateColumns => 'Indicate which column is which.';

  @override
  String get invfExcelSheet => 'Excel sheet';

  @override
  String invfSheetRows(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows',
      one: '1 row',
      zero: '$count rows',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String get invfHeaderRow => 'Column headers row';

  @override
  String get invfNoHeaders => 'No headers';

  @override
  String invfHeaderRowItem(int n, String text) {
    return 'Row $n: $text';
  }

  @override
  String get invfNotExists => '— none —';

  @override
  String invfColumnNumber(int n) {
    return 'Column $n';
  }

  @override
  String invfColumnNumberLower(int n) {
    return 'column $n';
  }

  @override
  String get invfFileValidation => 'File validation';

  @override
  String get invfRequiredNote =>
      'I need at least the date, the quantity and the price (or the total amount).';

  @override
  String get invfQuantityOrComment => 'Quantity (or the comment that has it)';

  @override
  String get invfPriceOrTotal => 'Price or total amount';

  @override
  String invfMissingColumn(String name) {
    return 'Choose the column for: $name';
  }

  @override
  String invfValidationSummary(int dataRows, int recognized) {
    String _temp0 = intl.Intl.pluralLogic(
      dataRows,
      locale: localeName,
      other: '$dataRows rows with data',
      one: '1 row with data',
      zero: '0 rows with data',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recognized,
      locale: localeName,
      other: '$recognized transactions recognized',
      one: '1 transaction recognized',
      zero: '0 transactions recognized',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String invfWithProblems(int count) {
    return ' · $count with problems';
  }

  @override
  String invfIgnoredByUser(int count) {
    return ' · $count ignored (not buys or sells)';
  }

  @override
  String invfColumnValid(String label, int ok, int total) {
    return '$label: $ok of $total valid';
  }

  @override
  String invfColumnValidNamed(String label, String column, int ok, int total) {
    return '$label ($column): $ok of $total valid';
  }

  @override
  String get invfUnknownTypes => 'Types I didn’t recognize';

  @override
  String get invfUnknownTypesHint =>
      'Tell me what they are so I can import them (or ignore them).';

  @override
  String invfUnknownTypeRows(String type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows',
      one: '1 row',
      zero: '$count rows',
    );
    return '“$type” · $_temp0';
  }

  @override
  String get invfEmpty => '(empty)';

  @override
  String get invfChoose => 'Choose';

  @override
  String invfSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows not imported',
      one: '1 row not imported',
      zero: '$count rows not imported',
    );
    return '$_temp0';
  }

  @override
  String invfRowReason(int row, String reason) {
    return 'Row $row: $reason';
  }

  @override
  String invfAndMore(int count) {
    return '… and $count more';
  }

  @override
  String get invfAllRowsOk => 'All rows were read without problems.';

  @override
  String invfImportedOps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions imported',
      one: '1 transaction imported',
      zero: '$count transactions imported',
    );
    return '$_temp0';
  }

  @override
  String invfImportedHoldings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assets created',
      one: '1 asset created',
      zero: '$count assets created',
    );
    return ' and $_temp0';
  }

  @override
  String get invfUpdatePrices => '. Update prices in the Portfolio.';

  @override
  String get invfNegativeCashWarning =>
      ' Unallocated cash went negative: link the bank transfers to this platform or adjust the cash.';

  @override
  String get invfFieldDate => 'Date';

  @override
  String get invfFieldType => 'Type (buy / sell)';

  @override
  String get invfFieldName => 'Asset name';

  @override
  String get invfFieldCategory => 'Category (ETF, stock…)';

  @override
  String get invfFieldComment => 'Comment (e.g. OPEN BUY 0.5 @ 100)';

  @override
  String get invfFieldSymbol => 'Symbol';

  @override
  String get invfFieldIsin => 'ISIN';

  @override
  String get invfFieldQuantity => 'Quantity';

  @override
  String get invfFieldPrice => 'Price per unit';

  @override
  String get invfFieldTotal => 'Total amount';

  @override
  String get invfFieldFee => 'Fee';

  @override
  String get invfFieldCurrency => 'Currency';

  @override
  String get invfFieldRate =>
      'Exchange rate (units of currency per 1 base currency)';

  @override
  String get invfKindEtf => 'ETF';

  @override
  String get invfKindStock => 'Stock';

  @override
  String get invfKindCrypto => 'Crypto';

  @override
  String get invfKindFund => 'Fund';

  @override
  String get invfKindBond => 'Bond';

  @override
  String get invfKindOther => 'Other';

  @override
  String get morMoreTitle => 'More';

  @override
  String get morBudgetSubtitle => 'Salary and limits per category';

  @override
  String get morPlanningSubtitle => 'Salary and planned expenses per month';

  @override
  String get morGoalsSubtitle => 'Save for a holiday, a car…';

  @override
  String get morAnalysisSubtitle => 'Where you spend and where you can save';

  @override
  String get morClassifyTitle => 'Classify transactions';

  @override
  String get morClassifySubtitle => 'One card per name';

  @override
  String get morUpdatesTitle => 'Updates';

  @override
  String get morUpdatesSubtitle => 'Look for and install a new version';

  @override
  String get morAppearanceSubtitle => 'Dark mode and colors';

  @override
  String get morAccountsTitle => 'Accounts';

  @override
  String morAccountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
      zero: '$count accounts',
    );
    return '$_temp0';
  }

  @override
  String get morRecurringTitle => 'Recurring transactions';

  @override
  String morRecurringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recurring',
      one: '1 recurring',
      zero: '$count recurring',
    );
    return '$_temp0 · salary, rent, subscriptions';
  }

  @override
  String get morCategoriesTitle => 'Categories and subcategories';

  @override
  String morCategoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
      zero: '$count categories',
    );
    return '$_temp0';
  }

  @override
  String get morGroupsTitle => 'Security groups';

  @override
  String morGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '1 group',
      zero: '$count groups',
    );
    return '$_temp0';
  }

  @override
  String get morRulesTitle => 'Saved rules';

  @override
  String morRulesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rules',
      one: '1 rule',
      zero: '$count rules',
    );
    return '$_temp0';
  }

  @override
  String get morImportTitle => 'Import statement';

  @override
  String get morImportSubtitle => 'PDF, CSV or Excel';

  @override
  String get morImportsHistoryTitle => 'Import history';

  @override
  String get morExportTitle => 'Export transactions (CSV)';

  @override
  String get morBackupTitle => 'Backup';

  @override
  String get morBackupSubtitle => 'Save or restore to Google Drive or a file';

  @override
  String get morWipeTransactionsTitle => 'Delete all transactions';

  @override
  String get morWipeTransactionsConfirm =>
      'Delete ALL transactions, rules and salaries? Categories are kept. This cannot be undone.';

  @override
  String get morWipeAllTitle => 'Delete everything, including categories';

  @override
  String get morWipeAllConfirm =>
      'Delete EVERYTHING: transactions, categories, budgets, rules, salaries and investments? This cannot be undone.';

  @override
  String get morPrivacyNote =>
      'All data stays only on this phone. The internet is only used if you tap “Update prices” in Portfolio (only the asset symbol is sent).';

  @override
  String get morImportsTitle => 'Imports';

  @override
  String get morNoImports => 'No imports yet.';

  @override
  String get morUndoImport => 'Undo import';

  @override
  String morImportItemSubtitle(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date · $count transactions',
      one: '$date · 1 transaction',
      zero: '$date · $count transactions',
    );
    return '$_temp0';
  }

  @override
  String morRemoveImportQuestion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove the $count transactions from this import?',
      one: 'Remove the transaction from this import?',
      zero: 'Remove the $count transactions from this import?',
    );
    return '$_temp0';
  }

  @override
  String get morCategoriesScreenTitle => 'Categories';

  @override
  String get morNewCategory => 'Category';

  @override
  String get morIncomeKind => 'Income';

  @override
  String get morInvestmentKind => 'Investment';

  @override
  String get morBothKinds => 'Expenses and income';

  @override
  String get morFromStart => 'from the start';

  @override
  String morFromMonth(String month) {
    return 'from $month';
  }

  @override
  String get morOpenEnded => 'onwards';

  @override
  String morToMonth(String month) {
    return 'to $month';
  }

  @override
  String get morEnded => 'ended';

  @override
  String get morFuture => 'upcoming';

  @override
  String morTxnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '$count transactions',
    );
    return '$_temp0';
  }

  @override
  String morMandatoryPeriods(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Required in $count periods',
      one: 'Required in 1 period',
      zero: 'Required in $count periods',
    );
    return '$_temp0';
  }

  @override
  String get morNewSubcategory => 'New subcategory';

  @override
  String get morDuplicateNextYear => 'Duplicate for next year';

  @override
  String get morReactivate => 'Reactivate';

  @override
  String get morArchive => 'Archive';

  @override
  String morCreatedCategory(String name) {
    return 'Created “$name”.';
  }

  @override
  String morDeleteCategoryQuestion(String name, int count, String subs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions are left',
      one: 'The transaction is left',
      zero: '$count transactions are left',
    );
    return 'Delete “$name”? $_temp0 without a category$subs.';
  }

  @override
  String get morSubcategoriesDeleted => ' and its subcategories are deleted';

  @override
  String get morThemeTitle => 'Theme';

  @override
  String get morThemeSystem => 'System';

  @override
  String get morThemeLight => 'Light';

  @override
  String get morThemeDark => 'Dark';

  @override
  String get morAmoledTitle => 'Pure black (AMOLED)';

  @override
  String get morAmoledSubtitle => 'In dark mode, a fully black background';

  @override
  String get morBaseCurrencyTitle => 'Base currency';

  @override
  String get morBaseCurrencyHint =>
      'It is the currency of your transactions, budgets and portfolio. Assets in other currencies (USD, GBP…) are converted to it.';

  @override
  String morBaseCurrencyChanged(String code) {
    return 'Base currency: $code. Values already recorded are not converted; update the prices in Portfolio.';
  }

  @override
  String get morMainColor => 'Main color';

  @override
  String get morMainColorHint =>
      'Sets the color of the navigation bar, buttons and charts.';

  @override
  String get morIncomeColor => 'Income color';

  @override
  String get morExpenseColor => 'Expense color';

  @override
  String get morPreview => 'Preview';

  @override
  String get morSamplePlace => 'Groceries';

  @override
  String get morSampleCategory => 'Category › Subcategory';

  @override
  String get morSampleSalary => 'Salary';

  @override
  String get morResetAppearance => 'Reset appearance';

  @override
  String get morEmojiHint =>
      'Each category and subcategory has its own emoji, which you choose when creating or editing it.';

  @override
  String get morBackupDescription =>
      'Saves all your data (transactions, categories, budgets, portfolio…) to a file. Receipt photos are not included.';

  @override
  String get morBackupDriveHint =>
      'There is no need to connect an account in the app: when saving, choose “Google Drive” (or another folder) on the Android screen. To restore, pick the file, from the phone or from Drive.';

  @override
  String morLastBackup(String date, String ago) {
    return 'Last backup: $date ($ago)';
  }

  @override
  String get morSaveBackup => 'Save backup (Google Drive or file)';

  @override
  String get morRestoreFromFile => 'Restore from a file';

  @override
  String get morBackupSaved => 'Backup saved.';

  @override
  String get morDataRestored => 'Data restored.';

  @override
  String morRestoreConfirm(String name) {
    return 'This replaces ALL the data on this phone with the backup “$name”. It cannot be undone. Continue?';
  }

  @override
  String get morRestore => 'Restore';

  @override
  String morCouldNotFinish(String error) {
    return 'Could not finish: $error';
  }

  @override
  String get morInstalledVersion => 'Installed version';

  @override
  String get morUpdateDescription =>
      'Looks on GitHub for a newer version and installs it over this one, without losing data. The internet is only used when you tap the button.';

  @override
  String get morChecking => 'Checking…';

  @override
  String get morCheckUpdates => 'Check for updates';

  @override
  String morNewVersion(String version) {
    return 'There is a new version: $version';
  }

  @override
  String get morUpToDate => 'You already have the latest version';

  @override
  String get morDownloadInstall => 'Download and install';

  @override
  String morDownloadInstallSize(String mb) {
    return 'Download and install ($mb MB)';
  }

  @override
  String morDownloadingPercent(String percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get morDownloading => 'Downloading…';

  @override
  String get morOpenReleasePage => 'Open the release page';

  @override
  String get morWhatsNew => 'What’s new';

  @override
  String morInstallerError(String message) {
    return 'Could not open the installer ($message). If Android asked for permission to install apps from this source, turn it on and tap \"Download and install\" again.';
  }

  @override
  String get morUpdateAvailableTitle => 'Update available';

  @override
  String morUpdateAvailableBody(String version) {
    return 'Finanças $version is available. Open More › Updates to install it.';
  }

  @override
  String get morUpdateChannelName => 'Updates';

  @override
  String get morUpdateChannelDescription =>
      'Notice when a new version comes out';

  @override
  String morRecurringNotifBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recurring transactions recorded',
      one: '1 recurring transaction recorded',
      zero: '$count recurring transactions recorded',
    );
    return '$_temp0';
  }

  @override
  String get morAllocationTitle => 'Investment delivery';

  @override
  String morAllocationBody(String account, String deliveries, String details) {
    return '$account$deliveries: $details';
  }

  @override
  String morDeliveriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count deliveries)',
      one: '(1 delivery)',
      zero: '($count deliveries)',
    );
    return '$_temp0';
  }

  @override
  String morUndistributed(String amount) {
    return '$amount to distribute';
  }

  @override
  String get morAlertsChannelName => 'Alerts';

  @override
  String get morAlertsChannelDescription =>
      'Recurring transactions and investment deliveries';

  @override
  String get morAssetFallback => 'Asset';

  @override
  String get morNavMonth => 'Month';

  @override
  String get morNavPortfolio => 'Portfolio';
}
