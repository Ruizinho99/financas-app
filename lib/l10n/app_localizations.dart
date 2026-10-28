import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pt'),
  ];

  /// No description provided for @anCompareOn.
  ///
  /// In pt, this message translates to:
  /// **'A comparar com o período anterior'**
  String get anCompareOn;

  /// No description provided for @anCompareOff.
  ///
  /// In pt, this message translates to:
  /// **'Comparar com o período anterior'**
  String get anCompareOff;

  /// No description provided for @anModeMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get anModeMonth;

  /// No description provided for @anModeYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get anModeYear;

  /// No description provided for @anModeYtd.
  ///
  /// In pt, this message translates to:
  /// **'YTD'**
  String get anModeYtd;

  /// No description provided for @anModeCustom.
  ///
  /// In pt, this message translates to:
  /// **'Custom'**
  String get anModeCustom;

  /// No description provided for @anYtdLabel.
  ///
  /// In pt, this message translates to:
  /// **'YTD {year} · 1 jan – hoje'**
  String anYtdLabel(String year);

  /// No description provided for @anPickRange.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o intervalo'**
  String get anPickRange;

  /// No description provided for @anApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get anApply;

  /// No description provided for @anTabOverview.
  ///
  /// In pt, this message translates to:
  /// **'Visão geral'**
  String get anTabOverview;

  /// No description provided for @anTabSpend.
  ///
  /// In pt, this message translates to:
  /// **'Gastos'**
  String get anTabSpend;

  /// No description provided for @anTabSave.
  ///
  /// In pt, this message translates to:
  /// **'Poupar'**
  String get anTabSave;

  /// No description provided for @anTabTrend.
  ///
  /// In pt, this message translates to:
  /// **'Evolução'**
  String get anTabTrend;

  /// No description provided for @anNoDataPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Sem movimentos neste período (ou os filtros não encontram nada).'**
  String get anNoDataPeriod;

  /// No description provided for @anExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get anExpenses;

  /// No description provided for @anSamePeriodPrev.
  ///
  /// In pt, this message translates to:
  /// **'Mesmos dias do período anterior: {amount}'**
  String anSamePeriodPrev(String amount);

  /// No description provided for @anPrevPeriodAmount.
  ///
  /// In pt, this message translates to:
  /// **'Período anterior: {amount}'**
  String anPrevPeriodAmount(String amount);

  /// No description provided for @anPrevPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período anterior'**
  String get anPrevPeriod;

  /// No description provided for @anOngoingToday.
  ///
  /// In pt, this message translates to:
  /// **'Período em curso: valores até hoje (dia {day}).'**
  String anOngoingToday(int day);

  /// No description provided for @anIncomes.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos'**
  String get anIncomes;

  /// No description provided for @anBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get anBalance;

  /// No description provided for @anInvested.
  ///
  /// In pt, this message translates to:
  /// **'Investido'**
  String get anInvested;

  /// No description provided for @anOfIncome.
  ///
  /// In pt, this message translates to:
  /// **'{percent} dos rendimentos'**
  String anOfIncome(String percent);

  /// No description provided for @anSavingsRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de poupança'**
  String get anSavingsRate;

  /// No description provided for @anPpVsPrev.
  ///
  /// In pt, this message translates to:
  /// **'{sign}{pp} pp vs anterior'**
  String anPpVsPrev(String sign, int pp);

  /// No description provided for @anIncomeExpected.
  ///
  /// In pt, this message translates to:
  /// **'Rendimento esperado: salário líquido definido no Orçamento.'**
  String get anIncomeExpected;

  /// No description provided for @anIncomeFromSalary.
  ///
  /// In pt, this message translates to:
  /// **'Sem rendimentos categorizados: a usar o salário líquido definido no Orçamento.'**
  String get anIncomeFromSalary;

  /// No description provided for @anRateOngoing.
  ///
  /// In pt, this message translates to:
  /// **'Período em curso: a taxa de poupança vai mudando até ao fim.'**
  String get anRateOngoing;

  /// No description provided for @anRateExcellent.
  ///
  /// In pt, this message translates to:
  /// **'Estás a poupar mais de 20% do que ganhas. Excelente.'**
  String get anRateExcellent;

  /// No description provided for @anRateOk.
  ///
  /// In pt, this message translates to:
  /// **'Poupas {percent}. Uma boa meta é 20%.'**
  String anRateOk(String percent);

  /// No description provided for @anRateNegative.
  ///
  /// In pt, this message translates to:
  /// **'Estás a gastar mais do que ganhas neste período.'**
  String get anRateNegative;

  /// No description provided for @anPace.
  ///
  /// In pt, this message translates to:
  /// **'Ritmo de gastos'**
  String get anPace;

  /// No description provided for @anAvgPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Média por dia'**
  String get anAvgPerDay;

  /// No description provided for @anAvgValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor médio'**
  String get anAvgValue;

  /// No description provided for @anDayOf.
  ///
  /// In pt, this message translates to:
  /// **'Dia {day} de {total}'**
  String anDayOf(int day, int total);

  /// No description provided for @anOfMonth.
  ///
  /// In pt, this message translates to:
  /// **'{percent} do mês'**
  String anOfMonth(String percent);

  /// No description provided for @anOfSpending.
  ///
  /// In pt, this message translates to:
  /// **'{percent} das despesas'**
  String anOfSpending(String percent);

  /// No description provided for @anProjected.
  ///
  /// In pt, this message translates to:
  /// **'Ao ritmo atual, o mês fecha em {amount}'**
  String anProjected(String amount);

  /// No description provided for @anPrevMonthSpent.
  ///
  /// In pt, this message translates to:
  /// **'No mês anterior gastaste {amount}.'**
  String anPrevMonthSpent(String amount);

  /// No description provided for @anAboveBudget.
  ///
  /// In pt, this message translates to:
  /// **'Isso são {amount} acima do orçamento de {budget}.'**
  String anAboveBudget(String amount, String budget);

  /// No description provided for @anWithinBudget.
  ///
  /// In pt, this message translates to:
  /// **'Dentro do orçamento de {budget}, com folga de {margin}.'**
  String anWithinBudget(String budget, String margin);

  /// No description provided for @anMandVsOpt.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatórias vs opcionais'**
  String get anMandVsOpt;

  /// No description provided for @anMandVsOptSub.
  ///
  /// In pt, this message translates to:
  /// **'O que tens de pagar vs onde tens margem para poupar'**
  String get anMandVsOptSub;

  /// No description provided for @anMandatory.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatórias'**
  String get anMandatory;

  /// No description provided for @anOptional.
  ///
  /// In pt, this message translates to:
  /// **'Opcionais'**
  String get anOptional;

  /// No description provided for @anNoCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem categoria'**
  String get anNoCategory;

  /// No description provided for @anTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get anTotal;

  /// No description provided for @anNoSpendPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Sem despesas neste período.'**
  String get anNoSpendPeriod;

  /// No description provided for @anPctOfIncome.
  ///
  /// In pt, this message translates to:
  /// **'Em % dos rendimentos: obrigatórias {mand}, opcionais {opt}, sobra {left}.'**
  String anPctOfIncome(String mand, String opt, String left);

  /// No description provided for @anBudgetSub.
  ///
  /// In pt, this message translates to:
  /// **'Limites e objetivos definidos'**
  String get anBudgetSub;

  /// No description provided for @anBudgetSubFiltered.
  ///
  /// In pt, this message translates to:
  /// **'Limites e objetivos definidos (não depende dos filtros)'**
  String get anBudgetSubFiltered;

  /// No description provided for @anGoalReached.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo atingido 🎉'**
  String get anGoalReached;

  /// No description provided for @anGoalLeft.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount} para o objetivo ({percent})'**
  String anGoalLeft(String amount, String percent);

  /// No description provided for @anOverLimit.
  ///
  /// In pt, this message translates to:
  /// **'Excedeste o limite em {amount}'**
  String anOverLimit(String amount);

  /// No description provided for @anNearLimit.
  ///
  /// In pt, this message translates to:
  /// **'Perto do limite: restam {amount}'**
  String anNearLimit(String amount);

  /// No description provided for @anLeftUsed.
  ///
  /// In pt, this message translates to:
  /// **'Restam {amount} ({percent} usado)'**
  String anLeftUsed(String amount, String percent);

  /// No description provided for @anWhereSave.
  ///
  /// In pt, this message translates to:
  /// **'Onde posso poupar?'**
  String get anWhereSave;

  /// No description provided for @anFoundUpTo.
  ///
  /// In pt, this message translates to:
  /// **'Encontrámos até {amount} por mês de margem.'**
  String anFoundUpTo(String amount);

  /// No description provided for @anNoSpendPeriodFilter.
  ///
  /// In pt, this message translates to:
  /// **'Sem despesas neste período (ou os filtros não encontram nada).'**
  String get anNoSpendPeriodFilter;

  /// No description provided for @anCategories.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get anCategories;

  /// No description provided for @anSubcategories.
  ///
  /// In pt, this message translates to:
  /// **'Subcategorias'**
  String get anSubcategories;

  /// No description provided for @anMerchants.
  ///
  /// In pt, this message translates to:
  /// **'Comerciantes'**
  String get anMerchants;

  /// No description provided for @anAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get anAccounts;

  /// No description provided for @anWhereMoneyGoes.
  ///
  /// In pt, this message translates to:
  /// **'Para onde vai o dinheiro'**
  String get anWhereMoneyGoes;

  /// No description provided for @anSubDetail.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe por subcategoria'**
  String get anSubDetail;

  /// No description provided for @anWhereMostSpend.
  ///
  /// In pt, this message translates to:
  /// **'Onde mais gastas'**
  String get anWhereMostSpend;

  /// No description provided for @anSpendByAccount.
  ///
  /// In pt, this message translates to:
  /// **'Gastos por conta'**
  String get anSpendByAccount;

  /// No description provided for @anTapRowHint.
  ///
  /// In pt, this message translates to:
  /// **'Toca numa linha para ver os movimentos'**
  String get anTapRowHint;

  /// No description provided for @anOthers.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get anOthers;

  /// No description provided for @anShowLess.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar menos'**
  String get anShowLess;

  /// No description provided for @anSeeAllCount.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos ({count})'**
  String anSeeAllCount(int count);

  /// No description provided for @anWdMon.
  ///
  /// In pt, this message translates to:
  /// **'Seg'**
  String get anWdMon;

  /// No description provided for @anWdTue.
  ///
  /// In pt, this message translates to:
  /// **'Ter'**
  String get anWdTue;

  /// No description provided for @anWdWed.
  ///
  /// In pt, this message translates to:
  /// **'Qua'**
  String get anWdWed;

  /// No description provided for @anWdThu.
  ///
  /// In pt, this message translates to:
  /// **'Qui'**
  String get anWdThu;

  /// No description provided for @anWdFri.
  ///
  /// In pt, this message translates to:
  /// **'Sex'**
  String get anWdFri;

  /// No description provided for @anWdSat.
  ///
  /// In pt, this message translates to:
  /// **'Sáb'**
  String get anWdSat;

  /// No description provided for @anWdSun.
  ///
  /// In pt, this message translates to:
  /// **'Dom'**
  String get anWdSun;

  /// No description provided for @anDayMon.
  ///
  /// In pt, this message translates to:
  /// **'à segunda'**
  String get anDayMon;

  /// No description provided for @anDayTue.
  ///
  /// In pt, this message translates to:
  /// **'à terça'**
  String get anDayTue;

  /// No description provided for @anDayWed.
  ///
  /// In pt, this message translates to:
  /// **'à quarta'**
  String get anDayWed;

  /// No description provided for @anDayThu.
  ///
  /// In pt, this message translates to:
  /// **'à quinta'**
  String get anDayThu;

  /// No description provided for @anDayFri.
  ///
  /// In pt, this message translates to:
  /// **'à sexta'**
  String get anDayFri;

  /// No description provided for @anDaySat.
  ///
  /// In pt, this message translates to:
  /// **'ao sábado'**
  String get anDaySat;

  /// No description provided for @anDaySun.
  ///
  /// In pt, this message translates to:
  /// **'ao domingo'**
  String get anDaySun;

  /// No description provided for @anSpendMostOn.
  ///
  /// In pt, this message translates to:
  /// **'Gastas mais {day}: {amount} em {count} movimentos'**
  String anSpendMostOn(String day, String amount, int count);

  /// No description provided for @anWhichDays.
  ///
  /// In pt, this message translates to:
  /// **'Em que dias gastas mais'**
  String get anWhichDays;

  /// No description provided for @anLargestSpends.
  ///
  /// In pt, this message translates to:
  /// **'Maiores despesas'**
  String get anLargestSpends;

  /// No description provided for @anLargestSub.
  ///
  /// In pt, this message translates to:
  /// **'As que mais pesaram neste período'**
  String get anLargestSub;

  /// No description provided for @anMonthByMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês a mês'**
  String get anMonthByMonth;

  /// No description provided for @anTxCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}}'**
  String anTxCount(int count);

  /// No description provided for @anWhereFrom.
  ///
  /// In pt, this message translates to:
  /// **'De onde vem'**
  String get anWhereFrom;

  /// No description provided for @anPerMonthCap.
  ///
  /// In pt, this message translates to:
  /// **'Por mês'**
  String get anPerMonthCap;

  /// No description provided for @anGeneralCat.
  ///
  /// In pt, this message translates to:
  /// **'{name} (geral)'**
  String anGeneralCat(String name);

  /// No description provided for @anAnalyseOnly.
  ///
  /// In pt, this message translates to:
  /// **'Analisar só esta'**
  String get anAnalyseOnly;

  /// No description provided for @anAndMore.
  ///
  /// In pt, this message translates to:
  /// **'… e mais {count}'**
  String anAndMore(int count);

  /// No description provided for @anNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Sem conta'**
  String get anNoAccount;

  /// No description provided for @anNotEnoughTrend.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há dados suficientes para mostrar a evolução.'**
  String get anNotEnoughTrend;

  /// No description provided for @anLastMonths.
  ///
  /// In pt, this message translates to:
  /// **'Últimos {count} meses · a linha tracejada é a média ({avg})'**
  String anLastMonths(int count, String avg);

  /// No description provided for @anSpendByMonth.
  ///
  /// In pt, this message translates to:
  /// **'Despesas por mês'**
  String get anSpendByMonth;

  /// No description provided for @anBestMonth.
  ///
  /// In pt, this message translates to:
  /// **'Melhor mês: {month}'**
  String anBestMonth(String month);

  /// No description provided for @anBestMonthBody.
  ///
  /// In pt, this message translates to:
  /// **'Gastaste {amount}, {diff} abaixo da média.'**
  String anBestMonthBody(String amount, String diff);

  /// No description provided for @anWorstMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês mais caro: {month}'**
  String anWorstMonth(String month);

  /// No description provided for @anWorstMonthBody.
  ///
  /// In pt, this message translates to:
  /// **'Gastaste {amount}, {diff} acima da média.'**
  String anWorstMonthBody(String amount, String diff);

  /// No description provided for @anIncomeVsSpend.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos vs despesas'**
  String get anIncomeVsSpend;

  /// No description provided for @anIncomeVsSpendSub.
  ///
  /// In pt, this message translates to:
  /// **'Se a linha das despesas passa a dos rendimentos, estás a gastar mais do que ganhas'**
  String get anIncomeVsSpendSub;

  /// No description provided for @anMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get anMonth;

  /// No description provided for @anSavingsShort.
  ///
  /// In pt, this message translates to:
  /// **'Poup.'**
  String get anSavingsShort;

  /// No description provided for @anTrendByCategory.
  ///
  /// In pt, this message translates to:
  /// **'Evolução por categoria'**
  String get anTrendByCategory;

  /// No description provided for @anPickCategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe uma categoria para a ver mês a mês'**
  String get anPickCategoryHint;

  /// No description provided for @anChooseCategory.
  ///
  /// In pt, this message translates to:
  /// **'Escolher categoria'**
  String get anChooseCategory;

  /// No description provided for @anNone.
  ///
  /// In pt, this message translates to:
  /// **'— nenhuma —'**
  String get anNone;

  /// No description provided for @anAvgMonthsWithSpend.
  ///
  /// In pt, this message translates to:
  /// **'Média nos meses com gasto: {amount}.'**
  String anAvgMonthsWithSpend(String amount);

  /// No description provided for @anNoSpendToAnalyse.
  ///
  /// In pt, this message translates to:
  /// **'Sem despesas neste período para analisar.'**
  String get anNoSpendToAnalyse;

  /// No description provided for @anSavingPotential.
  ///
  /// In pt, this message translates to:
  /// **'Potencial de poupança'**
  String get anSavingPotential;

  /// No description provided for @anPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'por mês'**
  String get anPerMonth;

  /// No description provided for @anUpToYear.
  ///
  /// In pt, this message translates to:
  /// **'Isso são até {amount} por ano, só com as sugestões abaixo.'**
  String anUpToYear(String amount);

  /// No description provided for @anNoObviousMargins.
  ///
  /// In pt, this message translates to:
  /// **'Neste período não encontrámos margens óbvias. Experimenta outro intervalo ou o simulador.'**
  String get anNoObviousMargins;

  /// No description provided for @anWhatIfCut.
  ///
  /// In pt, this message translates to:
  /// **'E se cortasse nas opcionais?'**
  String get anWhatIfCut;

  /// No description provided for @anOptionalThisPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Despesas opcionais neste período: {amount}'**
  String anOptionalThisPeriod(String amount);

  /// No description provided for @anCut.
  ///
  /// In pt, this message translates to:
  /// **'Cortar'**
  String get anCut;

  /// No description provided for @anSaveMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Poupas por mês'**
  String get anSaveMonthly;

  /// No description provided for @anSaveYearly.
  ///
  /// In pt, this message translates to:
  /// **'Poupas por ano'**
  String get anSaveYearly;

  /// No description provided for @anSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões'**
  String get anSuggestions;

  /// No description provided for @anSuggestionsSub.
  ///
  /// In pt, this message translates to:
  /// **'Ordenadas pelo que mais poupa'**
  String get anSuggestionsSub;

  /// No description provided for @anRecurringPayments.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos recorrentes'**
  String get anRecurringPayments;

  /// No description provided for @anRecOptional.
  ///
  /// In pt, this message translates to:
  /// **'Opcionais: {monthly}/mês ({yearly}/ano)'**
  String anRecOptional(String monthly, String yearly);

  /// No description provided for @anRecMandatory.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatórios: {monthly}/mês'**
  String anRecMandatory(String monthly);

  /// No description provided for @anMonthsLast.
  ///
  /// In pt, this message translates to:
  /// **'{count} meses · último {date}'**
  String anMonthsLast(int count, String date);

  /// No description provided for @anAmountPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'{amount}/mês'**
  String anAmountPerMonth(String amount);

  /// No description provided for @anAmountPerYear.
  ///
  /// In pt, this message translates to:
  /// **'{amount}/ano'**
  String anAmountPerYear(String amount);

  /// No description provided for @anCancelAdvice.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar o que já não usas é a forma mais fácil de poupar.'**
  String get anCancelAdvice;

  /// No description provided for @anFrequentSmall.
  ///
  /// In pt, this message translates to:
  /// **'Pequenas compras frequentes'**
  String get anFrequentSmall;

  /// No description provided for @anSmallSub.
  ///
  /// In pt, this message translates to:
  /// **'Compras de baixo valor que se repetem muito'**
  String get anSmallSub;

  /// No description provided for @anPurchasesAvg.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} compras} =1{1 compra} other{{count} compras}} · média {avg}'**
  String anPurchasesAvg(int count, String avg);

  /// No description provided for @anMandatoryTag.
  ///
  /// In pt, this message translates to:
  /// **'obrigatória'**
  String get anMandatoryTag;

  /// No description provided for @anOptionalTag.
  ///
  /// In pt, this message translates to:
  /// **'opcional'**
  String get anOptionalTag;

  /// No description provided for @anTypeAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get anTypeAll;

  /// No description provided for @anCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get anCategory;

  /// No description provided for @anCategoriesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} categorias'**
  String anCategoriesCount(int count);

  /// No description provided for @anAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get anAccount;

  /// No description provided for @anAccountsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} contas'**
  String anAccountsCount(int count);

  /// No description provided for @anFilters.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get anFilters;

  /// No description provided for @anClearAll.
  ///
  /// In pt, this message translates to:
  /// **'Limpar tudo'**
  String get anClearAll;

  /// No description provided for @anClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get anClear;

  /// No description provided for @anExpenseType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de despesa'**
  String get anExpenseType;

  /// No description provided for @anSearch.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar'**
  String get anSearch;

  /// No description provided for @anSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome, nota, categoria…'**
  String get anSearchHint;

  /// No description provided for @anTxAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor do movimento'**
  String get anTxAmount;

  /// No description provided for @anMinAmount.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo ({sym})'**
  String anMinAmount(String sym);

  /// No description provided for @anMaxAmount.
  ///
  /// In pt, this message translates to:
  /// **'Máximo ({sym})'**
  String anMaxAmount(String sym);

  /// No description provided for @anNoCategoriesYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há categorias.'**
  String get anNoCategoriesYet;

  /// No description provided for @anApplyFilters.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar filtros'**
  String get anApplyFilters;

  /// No description provided for @anStable.
  ///
  /// In pt, this message translates to:
  /// **'estável'**
  String get anStable;

  /// No description provided for @anNew.
  ///
  /// In pt, this message translates to:
  /// **'novo'**
  String get anNew;

  /// No description provided for @anUpToPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'até {amount}/mês'**
  String anUpToPerMonth(String amount);

  /// No description provided for @anOverLimitTitle.
  ///
  /// In pt, this message translates to:
  /// **'{name} acima do limite'**
  String anOverLimitTitle(String name);

  /// No description provided for @anOverLimitDetail.
  ///
  /// In pt, this message translates to:
  /// **'Gastaste {spent} para um limite de {target}.'**
  String anOverLimitDetail(String spent, String target);

  /// No description provided for @anIncreaseTitle.
  ///
  /// In pt, this message translates to:
  /// **'{name} subiu {percent}'**
  String anIncreaseTitle(String name, String percent);

  /// No description provided for @anIncreaseDetail.
  ///
  /// In pt, this message translates to:
  /// **'Mais {delta} do que no período anterior ({prev} → {cur}).'**
  String anIncreaseDetail(String delta, String prev, String cur);

  /// No description provided for @anTopOptionalTitle.
  ///
  /// In pt, this message translates to:
  /// **'{name}: {percent} das despesas'**
  String anTopOptionalTitle(String name, String percent);

  /// No description provided for @anTopOptionalDetail.
  ///
  /// In pt, this message translates to:
  /// **'É uma despesa opcional. Cortar 10% poupava {amount} por mês.'**
  String anTopOptionalDetail(String amount);

  /// No description provided for @anSmallDetail.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} compras} =1{1 compra} other{{count} compras}} em {places, plural, =0{{places} sítios} =1{1 sítio} other{{places} sítios}} somam {total} ({examples}). Reduzir um terço poupava {saving} por mês.'**
  String anSmallDetail(
    int count,
    int places,
    String total,
    String examples,
    String saving,
  );

  /// No description provided for @anRecurringTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} pagamentos recorrentes opcionais} =1{1 pagamento recorrente opcional} other{{count} pagamentos recorrentes opcionais}}'**
  String anRecurringTitle(int count);

  /// No description provided for @anRecurringDetail.
  ///
  /// In pt, this message translates to:
  /// **'Somam {monthly} por mês ({yearly} por ano). Vê se ainda precisas de todos.'**
  String anRecurringDetail(String monthly, String yearly);

  /// No description provided for @anUnclassifiedSpend.
  ///
  /// In pt, this message translates to:
  /// **'Despesas sem categoria'**
  String get anUnclassifiedSpend;

  /// No description provided for @anUnclassifiedDetail.
  ///
  /// In pt, this message translates to:
  /// **'{amount} por classificar. Quanto mais classificado, mais certeiras são as sugestões.'**
  String anUnclassifiedDetail(String amount);

  /// No description provided for @bpCopySalaryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Copiar salário para todos os meses'**
  String get bpCopySalaryTooltip;

  /// No description provided for @bpNetSalary.
  ///
  /// In pt, this message translates to:
  /// **'Salário líquido'**
  String get bpNetSalary;

  /// No description provided for @bpSet.
  ///
  /// In pt, this message translates to:
  /// **'Definir'**
  String get bpSet;

  /// No description provided for @bpSpecificThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Valor específico deste mês'**
  String get bpSpecificThisMonth;

  /// No description provided for @bpAllocatedSummary.
  ///
  /// In pt, this message translates to:
  /// **'Alocado {amount} ({percent})'**
  String bpAllocatedSummary(String amount, String percent);

  /// No description provided for @bpUnallocatedLeft.
  ///
  /// In pt, this message translates to:
  /// **'Por alocar {amount}'**
  String bpUnallocatedLeft(String amount);

  /// No description provided for @bpOverAllocated.
  ///
  /// In pt, this message translates to:
  /// **'Excedido em {amount}'**
  String bpOverAllocated(String amount);

  /// No description provided for @bpIncomeThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos recebidos este mês: {amount}'**
  String bpIncomeThisMonth(String amount);

  /// No description provided for @bpDefineSalaryHint.
  ///
  /// In pt, this message translates to:
  /// **'Define o teu salário líquido para distribuir por categorias.'**
  String get bpDefineSalaryHint;

  /// No description provided for @bpNoCategoriesBudget.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens categorias. Cria a primeira abaixo (ex.: Habitação) e define o orçamento de cada uma.'**
  String get bpNoCategoriesBudget;

  /// No description provided for @bpCategories.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get bpCategories;

  /// No description provided for @bpNewCategory.
  ///
  /// In pt, this message translates to:
  /// **'Nova categoria'**
  String get bpNewCategory;

  /// No description provided for @bpStatusOk.
  ///
  /// In pt, this message translates to:
  /// **'✓ Dentro do máximo · restam {left}'**
  String bpStatusOk(String left);

  /// No description provided for @bpStatusOver.
  ///
  /// In pt, this message translates to:
  /// **'⚠ Excedido em {over}'**
  String bpStatusOver(String over);

  /// No description provided for @bpStatusMinOk.
  ///
  /// In pt, this message translates to:
  /// **'✓ Mínimo atingido'**
  String get bpStatusMinOk;

  /// No description provided for @bpStatusMinBelow.
  ///
  /// In pt, this message translates to:
  /// **'Abaixo do mínimo · faltam {missing}'**
  String bpStatusMinBelow(String missing);

  /// No description provided for @bpBudgetLimit.
  ///
  /// In pt, this message translates to:
  /// **'Máximo'**
  String get bpBudgetLimit;

  /// No description provided for @bpBudgetGoal.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get bpBudgetGoal;

  /// No description provided for @bpSpentOfTarget.
  ///
  /// In pt, this message translates to:
  /// **'{spent} de {target} · {type}'**
  String bpSpentOfTarget(String spent, String target, String type);

  /// No description provided for @bpSpentNoBudget.
  ///
  /// In pt, this message translates to:
  /// **'Gasto: {spent} · sem orçamento'**
  String bpSpentNoBudget(String spent);

  /// No description provided for @bpSpentSetBudget.
  ///
  /// In pt, this message translates to:
  /// **'Gasto: {spent} · definir orçamento'**
  String bpSpentSetBudget(String spent);

  /// No description provided for @bpMandatoryInMonth.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatória em {month}'**
  String bpMandatoryInMonth(String month);

  /// No description provided for @bpInheritedFromParent.
  ///
  /// In pt, this message translates to:
  /// **'Herdada da categoria-mãe'**
  String get bpInheritedFromParent;

  /// No description provided for @bpOnlyThisMonthHint.
  ///
  /// In pt, this message translates to:
  /// **'Só este mês; para vários meses usa “Períodos”'**
  String get bpOnlyThisMonthHint;

  /// No description provided for @bpCategoryBudgetOptional.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento da categoria (opcional)'**
  String get bpCategoryBudgetOptional;

  /// No description provided for @bpSumOfSubcategories.
  ///
  /// In pt, this message translates to:
  /// **'Soma das subcategorias'**
  String get bpSumOfSubcategories;

  /// No description provided for @bpBudgetDescPercent.
  ///
  /// In pt, this message translates to:
  /// **'{type}: {percent}% do salário ({amount})'**
  String bpBudgetDescPercent(String type, String percent, String amount);

  /// No description provided for @bpBudgetDescValue.
  ///
  /// In pt, this message translates to:
  /// **'{type}: {amount}'**
  String bpBudgetDescValue(String type, String amount);

  /// No description provided for @bpSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'Subcategoria'**
  String get bpSubcategory;

  /// No description provided for @bpPeriods.
  ///
  /// In pt, this message translates to:
  /// **'Períodos'**
  String get bpPeriods;

  /// No description provided for @bpEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get bpEdit;

  /// No description provided for @bpBudgetEditorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento · {name}'**
  String bpBudgetEditorTitle(String name);

  /// No description provided for @bpHasBudget.
  ///
  /// In pt, this message translates to:
  /// **'Ter orçamento'**
  String get bpHasBudget;

  /// No description provided for @bpLimitHint.
  ///
  /// In pt, this message translates to:
  /// **'Máximo: queres gastar no máximo este valor (ex.: compras). Passar disto aparece como excedido.'**
  String get bpLimitHint;

  /// No description provided for @bpGoalHint.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo: queres atingir pelo menos este valor (ex.: investimentos). Ficar abaixo aparece como em falta.'**
  String get bpGoalHint;

  /// No description provided for @bpValueWithCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Valor ({currency})'**
  String bpValueWithCurrency(String currency);

  /// No description provided for @bpPercentOfSalary.
  ///
  /// In pt, this message translates to:
  /// **'% do salário'**
  String get bpPercentOfSalary;

  /// No description provided for @bpMonthlyAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor mensal'**
  String get bpMonthlyAmount;

  /// No description provided for @bpPercentage.
  ///
  /// In pt, this message translates to:
  /// **'Percentagem'**
  String get bpPercentage;

  /// No description provided for @bpSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get bpSave;

  /// No description provided for @bpNetSalaryMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Salário líquido mensal'**
  String get bpNetSalaryMonthly;

  /// No description provided for @bpOnlyThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Só para este mês'**
  String get bpOnlyThisMonth;

  /// No description provided for @bpSalaryDefaultHint.
  ///
  /// In pt, this message translates to:
  /// **'Desligado: passa a ser o valor por omissão de todos os meses'**
  String get bpSalaryDefaultHint;

  /// No description provided for @bpUseBaseSalary.
  ///
  /// In pt, this message translates to:
  /// **'Usar valor base'**
  String get bpUseBaseSalary;

  /// No description provided for @bpCopyPreviousPlan.
  ///
  /// In pt, this message translates to:
  /// **'Copiar o plano do mês anterior'**
  String get bpCopyPreviousPlan;

  /// No description provided for @bpCopiedPlanItems.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Copiadas {count} despesas de {month}.} =1{Copiada 1 despesa de {month}.} other{Copiadas {count} despesas de {month}.}}'**
  String bpCopiedPlanItems(int count, String month);

  /// No description provided for @bpMandatoryPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatórias planeadas'**
  String get bpMandatoryPlanned;

  /// No description provided for @bpOptionalPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Opcionais planeadas'**
  String get bpOptionalPlanned;

  /// No description provided for @bpExceedsSalaryBy.
  ///
  /// In pt, this message translates to:
  /// **'Excede o salário em'**
  String get bpExceedsSalaryBy;

  /// No description provided for @bpUnplanned.
  ///
  /// In pt, this message translates to:
  /// **'Por planear'**
  String get bpUnplanned;

  /// No description provided for @bpSetMonthSalaryHint.
  ///
  /// In pt, this message translates to:
  /// **'Define o salário deste mês para ver o que sobra.'**
  String get bpSetMonthSalaryHint;

  /// No description provided for @bpNoPlanCopyHint.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem despesas planeadas. Usa o ícone de copiar para trazer o plano do mês anterior.'**
  String get bpNoPlanCopyHint;

  /// No description provided for @bpNoPlanHint.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem despesas planeadas. Acrescenta as obrigatórias (renda, luz…) e as opcionais (lazer, subscrições…).'**
  String get bpNoPlanHint;

  /// No description provided for @bpMandatoryItems.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatórias'**
  String get bpMandatoryItems;

  /// No description provided for @bpOptionalItems.
  ///
  /// In pt, this message translates to:
  /// **'Opcionais'**
  String get bpOptionalItems;

  /// No description provided for @bpPlannedExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa planeada'**
  String get bpPlannedExpense;

  /// No description provided for @bpCategoryAlreadyPlannedEdit.
  ///
  /// In pt, this message translates to:
  /// **'Esta categoria já está planeada neste mês. Edita a linha existente.'**
  String get bpCategoryAlreadyPlannedEdit;

  /// No description provided for @bpCategoryAlreadyPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Esta categoria já está planeada neste mês.'**
  String get bpCategoryAlreadyPlanned;

  /// No description provided for @bpSpentOver.
  ///
  /// In pt, this message translates to:
  /// **'Gasto {spent} · passou {over}'**
  String bpSpentOver(String spent, String over);

  /// No description provided for @bpSpentLeft.
  ///
  /// In pt, this message translates to:
  /// **'Gasto {spent} · faltam {left}'**
  String bpSpentLeft(String spent, String left);

  /// No description provided for @bpPlannedAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor planeado ({currency})'**
  String bpPlannedAmount(String currency);

  /// No description provided for @bpMandatoryType.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatória'**
  String get bpMandatoryType;

  /// No description provided for @bpOptionalType.
  ///
  /// In pt, this message translates to:
  /// **'Opcional'**
  String get bpOptionalType;

  /// No description provided for @bpGoal.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get bpGoal;

  /// No description provided for @bpNoGoalsHint.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens objetivos.\nCria um (ex.: férias) e as transferências para a sua subcategoria contam para ele.'**
  String get bpNoGoalsHint;

  /// No description provided for @bpGoalReachedAmount.
  ///
  /// In pt, this message translates to:
  /// **'Atingido · {amount}'**
  String bpGoalReachedAmount(String amount);

  /// No description provided for @bpGoalProgress.
  ///
  /// In pt, this message translates to:
  /// **'{saved} de {target} · faltam {remaining}'**
  String bpGoalProgress(String saved, String target, String remaining);

  /// No description provided for @bpNewGoal.
  ///
  /// In pt, this message translates to:
  /// **'Novo objetivo'**
  String get bpNewGoal;

  /// No description provided for @bpEditGoal.
  ///
  /// In pt, this message translates to:
  /// **'Editar objetivo'**
  String get bpEditGoal;

  /// No description provided for @bpName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get bpName;

  /// No description provided for @bpGoalNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Férias de verão'**
  String get bpGoalNameHint;

  /// No description provided for @bpGoalAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor do objetivo ({currency})'**
  String bpGoalAmount(String currency);

  /// No description provided for @bpPreviousAmountKept.
  ///
  /// In pt, this message translates to:
  /// **'Se o alterares, o valor anterior fica no histórico.'**
  String get bpPreviousAmountKept;

  /// No description provided for @bpDeadlineOptional.
  ///
  /// In pt, this message translates to:
  /// **'Prazo (opcional)'**
  String get bpDeadlineOptional;

  /// No description provided for @bpNoDeadline.
  ///
  /// In pt, this message translates to:
  /// **'Sem prazo'**
  String get bpNoDeadline;

  /// No description provided for @bpRemoveDeadline.
  ///
  /// In pt, this message translates to:
  /// **'Remover prazo'**
  String get bpRemoveDeadline;

  /// No description provided for @bpDescriptionOptional.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get bpDescriptionOptional;

  /// No description provided for @bpCategoryWhere.
  ///
  /// In pt, this message translates to:
  /// **'Categoria onde fica'**
  String get bpCategoryWhere;

  /// No description provided for @bpChooseCategory.
  ///
  /// In pt, this message translates to:
  /// **'Escolher categoria'**
  String get bpChooseCategory;

  /// No description provided for @bpGoalCategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'O objetivo vira uma subcategoria desta categoria. Os movimentos nessa subcategoria contam como poupança.'**
  String get bpGoalCategoryHint;

  /// No description provided for @bpEnterName.
  ///
  /// In pt, this message translates to:
  /// **'Indica um nome.'**
  String get bpEnterName;

  /// No description provided for @bpEnterGoalAmount.
  ///
  /// In pt, this message translates to:
  /// **'Indica o valor do objetivo.'**
  String get bpEnterGoalAmount;

  /// No description provided for @bpChooseGoalCategory.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe a categoria onde fica o objetivo.'**
  String get bpChooseGoalCategory;

  /// No description provided for @bpGoalDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo apagado.'**
  String get bpGoalDeleted;

  /// No description provided for @bpDeleteGoalQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Apagar o objetivo “{name}”? Os movimentos ficam, mas deixam de estar associados a ele.'**
  String bpDeleteGoalQuestion(String name);

  /// No description provided for @bpAlreadyHave.
  ///
  /// In pt, this message translates to:
  /// **'Já tens'**
  String get bpAlreadyHave;

  /// No description provided for @bpExceeded.
  ///
  /// In pt, this message translates to:
  /// **'Excedido'**
  String get bpExceeded;

  /// No description provided for @bpRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Faltam'**
  String get bpRemaining;

  /// No description provided for @bpGoalPercentDeadline.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% · {deadline}'**
  String bpGoalPercentDeadline(String percent, String deadline);

  /// No description provided for @bpNoDeadlineLower.
  ///
  /// In pt, this message translates to:
  /// **'sem prazo'**
  String get bpNoDeadlineLower;

  /// No description provided for @bpDeadlineDate.
  ///
  /// In pt, this message translates to:
  /// **'prazo {date}'**
  String bpDeadlineDate(String date);

  /// No description provided for @bpLinkTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Associar movimento'**
  String get bpLinkTransaction;

  /// No description provided for @bpChangeAmount.
  ///
  /// In pt, this message translates to:
  /// **'Alterar valor'**
  String get bpChangeAmount;

  /// No description provided for @bpAmountHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico do valor'**
  String get bpAmountHistory;

  /// No description provided for @bpNoGoalEntriesHint.
  ///
  /// In pt, this message translates to:
  /// **'Ainda nada. Transferências na subcategoria do objetivo entram sozinhas; pagamentos feitos com outra categoria associas com “Associar movimento”.'**
  String get bpNoGoalEntriesHint;

  /// No description provided for @bpEntrySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{date} · {kind}'**
  String bpEntrySubtitle(String date, String kind);

  /// No description provided for @bpLinkedManual.
  ///
  /// In pt, this message translates to:
  /// **'associado'**
  String get bpLinkedManual;

  /// No description provided for @bpLinkedByCategory.
  ///
  /// In pt, this message translates to:
  /// **'pela categoria'**
  String get bpLinkedByCategory;

  /// No description provided for @bpUnlink.
  ///
  /// In pt, this message translates to:
  /// **'Desassociar'**
  String get bpUnlink;

  /// No description provided for @bpStatusReached.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo atingido.'**
  String get bpStatusReached;

  /// No description provided for @bpStatusOnTrack.
  ///
  /// In pt, this message translates to:
  /// **'No ritmo atual chegas a tempo: fazes {monthly}/mês e precisas de {needed}/mês.'**
  String bpStatusOnTrack(String monthly, String needed);

  /// No description provided for @bpStatusBehind.
  ///
  /// In pt, this message translates to:
  /// **'Para chegar a tempo precisas de {needed}/mês; estás a fazer {monthly}/mês.'**
  String bpStatusBehind(String needed, String monthly);

  /// No description provided for @bpStatusEta.
  ///
  /// In pt, this message translates to:
  /// **'No ritmo atual ({monthly}/mês) chegas a {date}.'**
  String bpStatusEta(String monthly, String date);

  /// No description provided for @bpStatusNoRecent.
  ///
  /// In pt, this message translates to:
  /// **'Sem movimentos recentes. Faltam {amount}.'**
  String bpStatusNoRecent(String amount);

  /// No description provided for @bpChangeGoalAmountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alterar valor do objetivo'**
  String get bpChangeGoalAmountTitle;

  /// No description provided for @bpNewAmount.
  ///
  /// In pt, this message translates to:
  /// **'Novo valor ({currency})'**
  String bpNewAmount(String currency);

  /// No description provided for @bpChangeAmountHint.
  ///
  /// In pt, this message translates to:
  /// **'O valor anterior fica no histórico. Os movimentos já associados mantêm-se.'**
  String get bpChangeAmountHint;

  /// No description provided for @bpSearchTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Procurar movimento'**
  String get bpSearchTransaction;

  /// No description provided for @bpNoTransactionsToLink.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum movimento para associar.'**
  String get bpNoTransactionsToLink;

  /// No description provided for @bpTxnLinkSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{date} · {amount} · por associar {left}'**
  String bpTxnLinkSubtitle(String date, String amount, String left);

  /// No description provided for @bpAmountForGoal.
  ///
  /// In pt, this message translates to:
  /// **'Valor para “{goal}” ({currency})'**
  String bpAmountForGoal(String goal, String currency);

  /// No description provided for @bpUnlinkedHint.
  ///
  /// In pt, this message translates to:
  /// **'Por associar: {left}. Podes dividir o movimento por vários objetivos.'**
  String bpUnlinkedHint(String left);

  /// No description provided for @bpLink.
  ///
  /// In pt, this message translates to:
  /// **'Associar'**
  String get bpLink;

  /// No description provided for @bpMonday.
  ///
  /// In pt, this message translates to:
  /// **'segunda-feira'**
  String get bpMonday;

  /// No description provided for @bpTuesday.
  ///
  /// In pt, this message translates to:
  /// **'terça-feira'**
  String get bpTuesday;

  /// No description provided for @bpWednesday.
  ///
  /// In pt, this message translates to:
  /// **'quarta-feira'**
  String get bpWednesday;

  /// No description provided for @bpThursday.
  ///
  /// In pt, this message translates to:
  /// **'quinta-feira'**
  String get bpThursday;

  /// No description provided for @bpFriday.
  ///
  /// In pt, this message translates to:
  /// **'sexta-feira'**
  String get bpFriday;

  /// No description provided for @bpSaturday.
  ///
  /// In pt, this message translates to:
  /// **'sábado'**
  String get bpSaturday;

  /// No description provided for @bpSunday.
  ///
  /// In pt, this message translates to:
  /// **'domingo'**
  String get bpSunday;

  /// No description provided for @bpJanuary.
  ///
  /// In pt, this message translates to:
  /// **'janeiro'**
  String get bpJanuary;

  /// No description provided for @bpFebruary.
  ///
  /// In pt, this message translates to:
  /// **'fevereiro'**
  String get bpFebruary;

  /// No description provided for @bpMarch.
  ///
  /// In pt, this message translates to:
  /// **'março'**
  String get bpMarch;

  /// No description provided for @bpApril.
  ///
  /// In pt, this message translates to:
  /// **'abril'**
  String get bpApril;

  /// No description provided for @bpMay.
  ///
  /// In pt, this message translates to:
  /// **'maio'**
  String get bpMay;

  /// No description provided for @bpJune.
  ///
  /// In pt, this message translates to:
  /// **'junho'**
  String get bpJune;

  /// No description provided for @bpJuly.
  ///
  /// In pt, this message translates to:
  /// **'julho'**
  String get bpJuly;

  /// No description provided for @bpAugust.
  ///
  /// In pt, this message translates to:
  /// **'agosto'**
  String get bpAugust;

  /// No description provided for @bpSeptember.
  ///
  /// In pt, this message translates to:
  /// **'setembro'**
  String get bpSeptember;

  /// No description provided for @bpOctober.
  ///
  /// In pt, this message translates to:
  /// **'outubro'**
  String get bpOctober;

  /// No description provided for @bpNovember.
  ///
  /// In pt, this message translates to:
  /// **'novembro'**
  String get bpNovember;

  /// No description provided for @bpDecember.
  ///
  /// In pt, this message translates to:
  /// **'dezembro'**
  String get bpDecember;

  /// No description provided for @bpFreqMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get bpFreqMonthly;

  /// No description provided for @bpFreqWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get bpFreqWeekly;

  /// No description provided for @bpFreqYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get bpFreqYearly;

  /// No description provided for @bpWhenMonthly.
  ///
  /// In pt, this message translates to:
  /// **'dia {day}'**
  String bpWhenMonthly(int day);

  /// No description provided for @bpWhenYearly.
  ///
  /// In pt, this message translates to:
  /// **'{day} de {month}'**
  String bpWhenYearly(int day, String month);

  /// No description provided for @bpNoRecurringHint.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há movimentos recorrentes.\n\nRegista aqui o salário, a renda ou uma subscrição: o movimento é criado sozinho na data certa.'**
  String get bpNoRecurringHint;

  /// No description provided for @bpRecurringTitle.
  ///
  /// In pt, this message translates to:
  /// **'Movimentos recorrentes'**
  String get bpRecurringTitle;

  /// No description provided for @bpNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get bpNew;

  /// No description provided for @bpPaused.
  ///
  /// In pt, this message translates to:
  /// **'em pausa'**
  String get bpPaused;

  /// No description provided for @bpEnded.
  ///
  /// In pt, this message translates to:
  /// **'terminada'**
  String get bpEnded;

  /// No description provided for @bpNextDate.
  ///
  /// In pt, this message translates to:
  /// **'próxima {date}'**
  String bpNextDate(String date);

  /// No description provided for @bpEditRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Editar recorrente'**
  String get bpEditRecurring;

  /// No description provided for @bpNewRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Novo recorrente'**
  String get bpNewRecurring;

  /// No description provided for @bpEnterDescription.
  ///
  /// In pt, this message translates to:
  /// **'Escreve uma descrição.'**
  String get bpEnterDescription;

  /// No description provided for @bpEnterAmount.
  ///
  /// In pt, this message translates to:
  /// **'Indica um valor.'**
  String get bpEnterAmount;

  /// No description provided for @bpEndBeforeStart.
  ///
  /// In pt, this message translates to:
  /// **'A data de fim é anterior à de início.'**
  String get bpEndBeforeStart;

  /// No description provided for @bpDeleteRecurringQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Apagar \"{description}\"? Os movimentos já registados ficam.'**
  String bpDeleteRecurringQuestion(String description);

  /// No description provided for @bpExpenseType.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get bpExpenseType;

  /// No description provided for @bpIncomeType.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get bpIncomeType;

  /// No description provided for @bpDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get bpDescription;

  /// No description provided for @bpDescriptionHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Salário, Renda, Netflix'**
  String get bpDescriptionHint;

  /// No description provided for @bpCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get bpCategory;

  /// No description provided for @bpAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get bpAccount;

  /// No description provided for @bpNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Sem conta'**
  String get bpNoAccount;

  /// No description provided for @bpFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get bpFrequency;

  /// No description provided for @bpDayOfWeek.
  ///
  /// In pt, this message translates to:
  /// **'Dia da semana'**
  String get bpDayOfWeek;

  /// No description provided for @bpDayOfMonth.
  ///
  /// In pt, this message translates to:
  /// **'Dia do mês'**
  String get bpDayOfMonth;

  /// No description provided for @bpShortMonthHint.
  ///
  /// In pt, this message translates to:
  /// **'Em meses mais curtos, passa para o último dia do mês.'**
  String get bpShortMonthHint;

  /// No description provided for @bpStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get bpStart;

  /// No description provided for @bpPastStartHint.
  ///
  /// In pt, this message translates to:
  /// **'Se a data de início já passou, os movimentos desde então são criados ao abrir a app.'**
  String get bpPastStartHint;

  /// No description provided for @bpEndOptional.
  ///
  /// In pt, this message translates to:
  /// **'Fim (opcional)'**
  String get bpEndOptional;

  /// No description provided for @bpNoEndDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem data de fim'**
  String get bpNoEndDate;

  /// No description provided for @bpRemoveEndDate.
  ///
  /// In pt, this message translates to:
  /// **'Remover data de fim'**
  String get bpRemoveEndDate;

  /// No description provided for @bpActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get bpActive;

  /// No description provided for @bpActiveHint.
  ///
  /// In pt, this message translates to:
  /// **'Desativa para pausar, sem apagar'**
  String get bpActiveHint;

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'Finanças'**
  String get appName;

  /// No description provided for @appearanceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearanceTitle;

  /// No description provided for @languageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get languageSystem;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @onboardingStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In pt, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// No description provided for @monthPrevious.
  ///
  /// In pt, this message translates to:
  /// **'Mês anterior'**
  String get monthPrevious;

  /// No description provided for @monthNext.
  ///
  /// In pt, this message translates to:
  /// **'Mês seguinte'**
  String get monthNext;

  /// No description provided for @pickDayOfMonth.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe um dia do mês'**
  String get pickDayOfMonth;

  /// No description provided for @transaction.
  ///
  /// In pt, this message translates to:
  /// **'Movimento'**
  String get transaction;

  /// No description provided for @transactions.
  ///
  /// In pt, this message translates to:
  /// **'Movimentos'**
  String get transactions;

  /// No description provided for @startHere.
  ///
  /// In pt, this message translates to:
  /// **'Começa por aqui'**
  String get startHere;

  /// No description provided for @monthAppearsHint.
  ///
  /// In pt, this message translates to:
  /// **'O mês aparece assim que tiveres movimentos'**
  String get monthAppearsHint;

  /// No description provided for @importStatement.
  ///
  /// In pt, this message translates to:
  /// **'Importar um extrato'**
  String get importStatement;

  /// No description provided for @addTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar um movimento'**
  String get addTransaction;

  /// No description provided for @spent.
  ///
  /// In pt, this message translates to:
  /// **'Gasto'**
  String get spent;

  /// No description provided for @canStillSpend.
  ///
  /// In pt, this message translates to:
  /// **'Ainda podes gastar {amount}'**
  String canStillSpend(String amount);

  /// No description provided for @dailyAverage.
  ///
  /// In pt, this message translates to:
  /// **'Média de {amount} por dia'**
  String dailyAverage(String amount);

  /// No description provided for @income.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get income;

  /// No description provided for @saved.
  ///
  /// In pt, this message translates to:
  /// **'Poupado'**
  String get saved;

  /// No description provided for @sentToInvest.
  ///
  /// In pt, this message translates to:
  /// **'Enviado para investir'**
  String get sentToInvest;

  /// No description provided for @whereSpendMost.
  ///
  /// In pt, this message translates to:
  /// **'Onde gastas mais'**
  String get whereSpendMost;

  /// No description provided for @seeAnalysis.
  ///
  /// In pt, this message translates to:
  /// **'Ver análise'**
  String get seeAnalysis;

  /// No description provided for @classifyHint.
  ///
  /// In pt, this message translates to:
  /// **'Um cartão por nome; memoriza para as próximas vezes'**
  String get classifyHint;

  /// No description provided for @budget.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento'**
  String get budget;

  /// No description provided for @analysis.
  ///
  /// In pt, this message translates to:
  /// **'Análise'**
  String get analysis;

  /// No description provided for @backToThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Voltar a este mês'**
  String get backToThisMonth;

  /// No description provided for @goals.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos'**
  String get goals;

  /// No description provided for @seeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get seeAll;

  /// No description provided for @deliveriesToDistribute.
  ///
  /// In pt, this message translates to:
  /// **'Entregas para distribuir'**
  String get deliveriesToDistribute;

  /// No description provided for @distribute.
  ///
  /// In pt, this message translates to:
  /// **'Distribuir'**
  String get distribute;

  /// No description provided for @deliveriesHint.
  ///
  /// In pt, this message translates to:
  /// **'Entregas do banco que ainda não repartiste pelos ativos.'**
  String get deliveriesHint;

  /// No description provided for @planning.
  ///
  /// In pt, this message translates to:
  /// **'Planeamento'**
  String get planning;

  /// No description provided for @seePlan.
  ///
  /// In pt, this message translates to:
  /// **'Ver plano'**
  String get seePlan;

  /// No description provided for @planned.
  ///
  /// In pt, this message translates to:
  /// **'Planeado'**
  String get planned;

  /// No description provided for @actualSpent.
  ///
  /// In pt, this message translates to:
  /// **'Gasto real'**
  String get actualSpent;

  /// No description provided for @leftAfterPlan.
  ///
  /// In pt, this message translates to:
  /// **'Sobra do salário, depois do plano: {amount}'**
  String leftAfterPlan(String amount);

  /// No description provided for @reached.
  ///
  /// In pt, this message translates to:
  /// **'Atingido'**
  String get reached;

  /// No description provided for @missingAmount.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount}'**
  String missingAmount(String amount);

  /// No description provided for @categorize.
  ///
  /// In pt, this message translates to:
  /// **'Categorizar'**
  String get categorize;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get delete;

  /// No description provided for @deleteTransactionsQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Apagar {count} movimentos?'**
  String deleteTransactionsQuestion(int count);

  /// No description provided for @selectedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} selecionados'**
  String selectedCount(int count);

  /// No description provided for @search.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar…'**
  String get search;

  /// No description provided for @noCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem categoria'**
  String get noCategory;

  /// No description provided for @allAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Todas as contas'**
  String get allAccounts;

  /// No description provided for @accountFallback.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get accountFallback;

  /// No description provided for @allMonths.
  ///
  /// In pt, this message translates to:
  /// **'Todos os meses'**
  String get allMonths;

  /// No description provided for @noTransactionsHint.
  ///
  /// In pt, this message translates to:
  /// **'Sem movimentos.\nImporta um extrato (ícone no topo) ou adiciona manualmente.'**
  String get noTransactionsHint;

  /// No description provided for @reversalDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Anula uma despesa já apagada ({amount})'**
  String reversalDeleted(String amount);

  /// No description provided for @reversalOf.
  ///
  /// In pt, this message translates to:
  /// **'Anula {name} ({amount})'**
  String reversalOf(String name, String amount);

  /// No description provided for @reversedLeft.
  ///
  /// In pt, this message translates to:
  /// **'Anulado {done} · fica {left}'**
  String reversedLeft(String done, String left);

  /// No description provided for @goalFallback.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get goalFallback;

  /// No description provided for @goalsSplit.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos: {parts}'**
  String goalsSplit(String parts);

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @monthStartTitle.
  ///
  /// In pt, this message translates to:
  /// **'Início do mês'**
  String get monthStartTitle;

  /// No description provided for @monthStartSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dia fixo ou o dia do salário'**
  String get monthStartSubtitle;

  /// No description provided for @monthModeCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Calendário'**
  String get monthModeCalendar;

  /// No description provided for @monthModeFixed.
  ///
  /// In pt, this message translates to:
  /// **'Dia fixo'**
  String get monthModeFixed;

  /// No description provided for @monthModeSalary.
  ///
  /// In pt, this message translates to:
  /// **'Salário'**
  String get monthModeSalary;

  /// No description provided for @monthStartDayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia em que o mês começa'**
  String get monthStartDayLabel;

  /// No description provided for @monthNamedByEnd.
  ///
  /// In pt, this message translates to:
  /// **'O mês tem o nome do mês em que termina: 25 ago – 24 set é setembro.'**
  String get monthNamedByEnd;

  /// No description provided for @monthCalendarHint.
  ///
  /// In pt, this message translates to:
  /// **'O mês vai do dia 1 ao último dia, como no calendário.'**
  String get monthCalendarHint;

  /// No description provided for @salaryCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria do salário'**
  String get salaryCategoryLabel;

  /// No description provided for @salaryCategoryChoose.
  ///
  /// In pt, this message translates to:
  /// **'Escolher categoria'**
  String get salaryCategoryChoose;

  /// No description provided for @salaryCategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'O mês começa no dia em que entra um movimento positivo nesta categoria.'**
  String get salaryCategoryHint;

  /// No description provided for @salaryDatesFound.
  ///
  /// In pt, this message translates to:
  /// **'Salários encontrados: {count}'**
  String salaryDatesFound(int count);

  /// No description provided for @salaryNoneFound.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem salários nesta categoria. Até lá, o mês é o do calendário.'**
  String get salaryNoneFound;

  /// No description provided for @thisMonthIs.
  ///
  /// In pt, this message translates to:
  /// **'Este mês: {range}'**
  String thisMonthIs(String range);

  /// No description provided for @dayOfMonthItem.
  ///
  /// In pt, this message translates to:
  /// **'Dia {day}'**
  String dayOfMonthItem(int day);

  /// No description provided for @frmReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Recibo'**
  String get frmReceipt;

  /// No description provided for @frmViewReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Ver recibo'**
  String get frmViewReceipt;

  /// No description provided for @frmTakePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto'**
  String get frmTakePhoto;

  /// No description provided for @frmChooseFromGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get frmChooseFromGallery;

  /// No description provided for @frmChooseFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher ficheiro (PDF ou imagem)'**
  String get frmChooseFile;

  /// No description provided for @frmRemoveReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Remover recibo'**
  String get frmRemoveReceipt;

  /// No description provided for @frmReceiptAttachError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível anexar o recibo: {error}'**
  String frmReceiptAttachError(String error);

  /// No description provided for @frmReceiptFileNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Ficheiro do recibo não encontrado.'**
  String get frmReceiptFileNotFound;

  /// No description provided for @frmEnterValidAmount.
  ///
  /// In pt, this message translates to:
  /// **'Indica um montante válido.'**
  String get frmEnterValidAmount;

  /// No description provided for @frmAllocatedToGoals.
  ///
  /// In pt, this message translates to:
  /// **'Já tens {amount} associado a objetivos. Reduz as associações primeiro.'**
  String frmAllocatedToGoals(String amount);

  /// No description provided for @frmTransferTo.
  ///
  /// In pt, this message translates to:
  /// **'Transferência para {name}'**
  String frmTransferTo(String name);

  /// No description provided for @frmTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get frmTransfer;

  /// No description provided for @frmExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get frmExpense;

  /// No description provided for @frmIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get frmIncome;

  /// No description provided for @frmReversedGone.
  ///
  /// In pt, this message translates to:
  /// **'A despesa anulada já não existe.'**
  String get frmReversedGone;

  /// No description provided for @frmEnterReversedAmount.
  ///
  /// In pt, this message translates to:
  /// **'Indica quanto da despesa é anulado.'**
  String get frmEnterReversedAmount;

  /// No description provided for @frmReversalTooBig.
  ///
  /// In pt, this message translates to:
  /// **'A anulação não pode ser maior que a receita.'**
  String get frmReversalTooBig;

  /// No description provided for @frmOnlyLeftToReverse.
  ///
  /// In pt, this message translates to:
  /// **'Só faltam {amount} para anular nesta despesa.'**
  String frmOnlyLeftToReverse(String amount);

  /// No description provided for @frmReversalHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ainda se pode anular {amount} desta despesa. A parte anulada não conta como gasto nem como receita na Análise.'**
  String frmReversalHelp(String amount);

  /// No description provided for @frmSearchExpense.
  ///
  /// In pt, this message translates to:
  /// **'Procurar despesa'**
  String get frmSearchExpense;

  /// No description provided for @frmNoReversal.
  ///
  /// In pt, this message translates to:
  /// **'Não anula nenhuma despesa'**
  String get frmNoReversal;

  /// No description provided for @frmToReverseSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{date} · {amount} · por anular {left}'**
  String frmToReverseSubtitle(String date, String amount, String left);

  /// No description provided for @frmNoExpenseToReverse.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma despesa para anular.'**
  String get frmNoExpenseToReverse;

  /// No description provided for @frmInvestPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Plataforma de investimento'**
  String get frmInvestPlatform;

  /// No description provided for @frmNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get frmNone;

  /// No description provided for @frmExpenseGone.
  ///
  /// In pt, this message translates to:
  /// **'Despesa já não existe'**
  String get frmExpenseGone;

  /// No description provided for @frmSaveToSplit.
  ///
  /// In pt, this message translates to:
  /// **'Guarda o movimento para o dividir por objetivos.'**
  String get frmSaveToSplit;

  /// No description provided for @frmChangeAmount.
  ///
  /// In pt, this message translates to:
  /// **'Alterar valor'**
  String get frmChangeAmount;

  /// No description provided for @frmUnlink.
  ///
  /// In pt, this message translates to:
  /// **'Desassociar'**
  String get frmUnlink;

  /// No description provided for @frmToAllocate.
  ///
  /// In pt, this message translates to:
  /// **'Por associar: {amount}'**
  String frmToAllocate(String amount);

  /// No description provided for @frmSplitByGoals.
  ///
  /// In pt, this message translates to:
  /// **'Dividir por objetivos'**
  String get frmSplitByGoals;

  /// No description provided for @frmSplitByGoal.
  ///
  /// In pt, this message translates to:
  /// **'Dividir por objetivo'**
  String get frmSplitByGoal;

  /// No description provided for @frmAllocate.
  ///
  /// In pt, this message translates to:
  /// **'Associar'**
  String get frmAllocate;

  /// No description provided for @frmSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get frmSave;

  /// No description provided for @frmAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get frmAccount;

  /// No description provided for @frmFromAccount.
  ///
  /// In pt, this message translates to:
  /// **'Da conta'**
  String get frmFromAccount;

  /// No description provided for @frmDestinationAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta de destino'**
  String get frmDestinationAccount;

  /// No description provided for @frmSelectAccount.
  ///
  /// In pt, this message translates to:
  /// **'Seleciona uma conta'**
  String get frmSelectAccount;

  /// No description provided for @frmSelectDestinationAccount.
  ///
  /// In pt, this message translates to:
  /// **'Seleciona a conta de destino'**
  String get frmSelectDestinationAccount;

  /// No description provided for @frmToAccount.
  ///
  /// In pt, this message translates to:
  /// **'Para a conta'**
  String get frmToAccount;

  /// No description provided for @frmTakePhotoOrChoose.
  ///
  /// In pt, this message translates to:
  /// **'Tira uma foto ou escolhe um ficheiro'**
  String get frmTakePhotoOrChoose;

  /// No description provided for @frmEditTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Editar movimento'**
  String get frmEditTransaction;

  /// No description provided for @frmNewTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Novo movimento'**
  String get frmNewTransaction;

  /// No description provided for @frmImportStatementTip.
  ///
  /// In pt, this message translates to:
  /// **'Importar extrato'**
  String get frmImportStatementTip;

  /// No description provided for @frmDeleteThisTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Apagar este movimento?'**
  String get frmDeleteThisTransaction;

  /// No description provided for @frmCalculator.
  ///
  /// In pt, this message translates to:
  /// **'Calculadora'**
  String get frmCalculator;

  /// No description provided for @frmCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get frmCategory;

  /// No description provided for @frmChooseCategory.
  ///
  /// In pt, this message translates to:
  /// **'Escolher categoria'**
  String get frmChooseCategory;

  /// No description provided for @frmReversesExpense.
  ///
  /// In pt, this message translates to:
  /// **'Anula uma despesa (reembolso, devolução)'**
  String get frmReversesExpense;

  /// No description provided for @frmReversedAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor anulado ({currency})'**
  String frmReversedAmount(String currency);

  /// No description provided for @frmDescriptionOptional.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get frmDescriptionOptional;

  /// No description provided for @frmToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get frmToday;

  /// No description provided for @frmYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get frmYesterday;

  /// No description provided for @frmOtherDate.
  ///
  /// In pt, this message translates to:
  /// **'Outra data'**
  String get frmOtherDate;

  /// No description provided for @frmToInvestOptional.
  ///
  /// In pt, this message translates to:
  /// **'Para investir (opcional)'**
  String get frmToInvestOptional;

  /// No description provided for @frmOutgoing.
  ///
  /// In pt, this message translates to:
  /// **'Saída'**
  String get frmOutgoing;

  /// No description provided for @frmIncoming.
  ///
  /// In pt, this message translates to:
  /// **'Entrada'**
  String get frmIncoming;

  /// No description provided for @frmNotCountedNote.
  ///
  /// In pt, this message translates to:
  /// **'Não conta como despesa nem receita na Análise.'**
  String get frmNotCountedNote;

  /// No description provided for @frmMoreOptions.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções (conta, recibo)'**
  String get frmMoreOptions;

  /// No description provided for @frmAmountCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Valor ({currency})'**
  String frmAmountCurrency(String currency);

  /// No description provided for @frmOnlyLeftToAllocate.
  ///
  /// In pt, this message translates to:
  /// **'Só faltam {amount} para associar.'**
  String frmOnlyLeftToAllocate(String amount);

  /// No description provided for @frmOptional.
  ///
  /// In pt, this message translates to:
  /// **' (opcional)'**
  String get frmOptional;

  /// No description provided for @frmCalcHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: 12,50+3*2'**
  String get frmCalcHint;

  /// No description provided for @frmUse.
  ///
  /// In pt, this message translates to:
  /// **'Usar'**
  String get frmUse;

  /// No description provided for @frmWholeFile.
  ///
  /// In pt, this message translates to:
  /// **'Todo o ficheiro'**
  String get frmWholeFile;

  /// No description provided for @frmPeriodToImport.
  ///
  /// In pt, this message translates to:
  /// **'Período a importar'**
  String get frmPeriodToImport;

  /// No description provided for @frmFileDataRange.
  ///
  /// In pt, this message translates to:
  /// **'O ficheiro tem dados de {from} a {to}. Escolhe só o intervalo que queres importar.'**
  String frmFileDataRange(String from, String to);

  /// No description provided for @frmFrom.
  ///
  /// In pt, this message translates to:
  /// **'De'**
  String get frmFrom;

  /// No description provided for @frmUntil.
  ///
  /// In pt, this message translates to:
  /// **'Até'**
  String get frmUntil;

  /// No description provided for @frmInRangeOfTotal.
  ///
  /// In pt, this message translates to:
  /// **'{inRange} de {total} no período'**
  String frmInRangeOfTotal(int inRange, int total);

  /// No description provided for @frmTotalInFile.
  ///
  /// In pt, this message translates to:
  /// **'{total} no ficheiro'**
  String frmTotalInFile(int total);

  /// No description provided for @frmSelectCategory.
  ///
  /// In pt, this message translates to:
  /// **'Seleciona uma categoria'**
  String get frmSelectCategory;

  /// No description provided for @frmNewCategory.
  ///
  /// In pt, this message translates to:
  /// **'➕  Nova categoria…'**
  String get frmNewCategory;

  /// No description provided for @frmNoCategoryItem.
  ///
  /// In pt, this message translates to:
  /// **'✖️  Sem categoria'**
  String get frmNoCategoryItem;

  /// No description provided for @frmHideEndedFuture.
  ///
  /// In pt, this message translates to:
  /// **'🙈  Esconder terminadas e futuras'**
  String get frmHideEndedFuture;

  /// No description provided for @frmShowEndedFuture.
  ///
  /// In pt, this message translates to:
  /// **'👁  Mostrar terminadas e futuras'**
  String get frmShowEndedFuture;

  /// No description provided for @frmEnded.
  ///
  /// In pt, this message translates to:
  /// **'  · terminada'**
  String get frmEnded;

  /// No description provided for @frmUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'  · futura'**
  String get frmUpcoming;

  /// No description provided for @frmSelectSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'Seleciona uma subcategoria'**
  String get frmSelectSubcategory;

  /// No description provided for @frmSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'Subcategoria'**
  String get frmSubcategory;

  /// No description provided for @frmNewSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'➕  Nova subcategoria…'**
  String get frmNewSubcategory;

  /// No description provided for @frmNoSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'— Sem subcategoria —'**
  String get frmNoSubcategory;

  /// No description provided for @frmChoose.
  ///
  /// In pt, this message translates to:
  /// **'Escolher'**
  String get frmChoose;

  /// No description provided for @frmChooseEmoji.
  ///
  /// In pt, this message translates to:
  /// **'Escolher emoji'**
  String get frmChooseEmoji;

  /// No description provided for @frmOrUseKeyboardEmoji.
  ///
  /// In pt, this message translates to:
  /// **'Ou usa outro emoji do teclado'**
  String get frmOrUseKeyboardEmoji;

  /// No description provided for @frmRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get frmRemove;

  /// No description provided for @frmChooseColor.
  ///
  /// In pt, this message translates to:
  /// **'Escolher cor'**
  String get frmChooseColor;

  /// No description provided for @frmHue.
  ///
  /// In pt, this message translates to:
  /// **'Matiz'**
  String get frmHue;

  /// No description provided for @frmSaturation.
  ///
  /// In pt, this message translates to:
  /// **'Saturação'**
  String get frmSaturation;

  /// No description provided for @frmBrightness.
  ///
  /// In pt, this message translates to:
  /// **'Brilho'**
  String get frmBrightness;

  /// No description provided for @frmHex.
  ///
  /// In pt, this message translates to:
  /// **'Hexadecimal'**
  String get frmHex;

  /// No description provided for @frmMandatoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatória · {name}'**
  String frmMandatoryTitle(String name);

  /// No description provided for @frmMandatoryExplain.
  ///
  /// In pt, this message translates to:
  /// **'Os meses abaixo contam como despesa obrigatória nesta categoria. Nos restantes meses é opcional.'**
  String get frmMandatoryExplain;

  /// No description provided for @frmNoPeriodDefined.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum período definido.'**
  String get frmNoPeriodDefined;

  /// No description provided for @frmFromMonth.
  ///
  /// In pt, this message translates to:
  /// **'A partir de {month}'**
  String frmFromMonth(String month);

  /// No description provided for @frmClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get frmClose;

  /// No description provided for @frmAddPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar período'**
  String get frmAddPeriod;

  /// No description provided for @frmAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get frmAdd;

  /// No description provided for @frmPickAnyDayOfMonth.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe qualquer dia do mês'**
  String get frmPickAnyDayOfMonth;

  /// No description provided for @frmNewPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Novo período'**
  String get frmNewPeriod;

  /// No description provided for @frmSinceMonth.
  ///
  /// In pt, this message translates to:
  /// **'Desde {month}'**
  String frmSinceMonth(String month);

  /// No description provided for @frmNoEndDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem data de fim'**
  String get frmNoEndDate;

  /// No description provided for @frmUntilMonth.
  ///
  /// In pt, this message translates to:
  /// **'Até {month}'**
  String frmUntilMonth(String month);

  /// No description provided for @frmMainCategories.
  ///
  /// In pt, this message translates to:
  /// **'Principais'**
  String get frmMainCategories;

  /// No description provided for @frmOnlyName.
  ///
  /// In pt, this message translates to:
  /// **'Só {name}'**
  String frmOnlyName(String name);

  /// No description provided for @frmNoSubcategories.
  ///
  /// In pt, this message translates to:
  /// **'Esta categoria não tem subcategorias.'**
  String get frmNoSubcategories;

  /// No description provided for @frmSearchCategory.
  ///
  /// In pt, this message translates to:
  /// **'Procurar categoria'**
  String get frmSearchCategory;

  /// No description provided for @frmNoCategoriesYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens categorias. Cria a primeira.'**
  String get frmNoCategoriesYet;

  /// No description provided for @frmNoCategoryFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma categoria encontrada.'**
  String get frmNoCategoryFound;

  /// No description provided for @frmNewCategoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova categoria'**
  String get frmNewCategoryTitle;

  /// No description provided for @frmChooseMonth.
  ///
  /// In pt, this message translates to:
  /// **'Escolher mês'**
  String get frmChooseMonth;

  /// No description provided for @frmEnterName.
  ///
  /// In pt, this message translates to:
  /// **'Indica um nome'**
  String get frmEnterName;

  /// No description provided for @frmMainCategoryExists.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma categoria principal com este nome'**
  String get frmMainCategoryExists;

  /// No description provided for @frmSubcategoryExists.
  ///
  /// In pt, this message translates to:
  /// **'Já existe esta subcategoria em {parent}'**
  String frmSubcategoryExists(String parent);

  /// No description provided for @frmThisCategory.
  ///
  /// In pt, this message translates to:
  /// **'esta categoria'**
  String get frmThisCategory;

  /// No description provided for @frmRepeatedName.
  ///
  /// In pt, this message translates to:
  /// **'Nome repetido'**
  String get frmRepeatedName;

  /// No description provided for @frmRemoveSubQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Remover “{name}”? {count, plural, =0{Os {count} movimentos ficam} =1{O movimento fica} other{Os {count} movimentos ficam}} sem categoria (só depois de guardares).'**
  String frmRemoveSubQuestion(String name, int count);

  /// No description provided for @frmEditCategory.
  ///
  /// In pt, this message translates to:
  /// **'Editar categoria'**
  String get frmEditCategory;

  /// No description provided for @frmEditSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'Editar subcategoria'**
  String get frmEditSubcategory;

  /// No description provided for @frmNewSubcategoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova subcategoria'**
  String get frmNewSubcategoryTitle;

  /// No description provided for @frmEditCategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'Altera os dados e as subcategorias'**
  String get frmEditCategoryHint;

  /// No description provided for @frmEditSubcategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'Altera os dados desta subcategoria'**
  String get frmEditSubcategoryHint;

  /// No description provided for @frmCreateSubsIn.
  ///
  /// In pt, this message translates to:
  /// **'Cria subcategorias dentro de {name}'**
  String frmCreateSubsIn(String name);

  /// No description provided for @frmCreateCategoryHint.
  ///
  /// In pt, this message translates to:
  /// **'Cria uma categoria e as suas subcategorias'**
  String get frmCreateCategoryHint;

  /// No description provided for @frmSubcategoryName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da subcategoria'**
  String get frmSubcategoryName;

  /// No description provided for @frmName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get frmName;

  /// No description provided for @frmParentCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria-mãe'**
  String get frmParentCategory;

  /// No description provided for @frmNoneMainCategory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma (categoria principal)'**
  String get frmNoneMainCategory;

  /// No description provided for @frmHasSubsLock.
  ///
  /// In pt, this message translates to:
  /// **'Tem subcategorias, por isso não pode ser uma subcategoria.'**
  String get frmHasSubsLock;

  /// No description provided for @frmSubcategoryOf.
  ///
  /// In pt, this message translates to:
  /// **'Subcategoria de '**
  String get frmSubcategoryOf;

  /// No description provided for @frmCreatingSubcategoryOf.
  ///
  /// In pt, this message translates to:
  /// **'A criar subcategoria de '**
  String get frmCreatingSubcategoryOf;

  /// No description provided for @frmMoreSubsOf.
  ///
  /// In pt, this message translates to:
  /// **'Mais subcategorias de {name}'**
  String frmMoreSubsOf(String name);

  /// No description provided for @frmSubcategories.
  ///
  /// In pt, this message translates to:
  /// **'Subcategorias'**
  String get frmSubcategories;

  /// No description provided for @frmRemoveSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'Remover subcategoria'**
  String get frmRemoveSubcategory;

  /// No description provided for @frmAddSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar subcategoria'**
  String get frmAddSubcategory;

  /// No description provided for @frmOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções'**
  String get frmOptions;

  /// No description provided for @frmType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get frmType;

  /// No description provided for @frmOnlyInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Só existe num período'**
  String get frmOnlyInPeriod;

  /// No description provided for @frmOnlyInPeriodHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: “Férias 2027”. Fora do período deixa de aparecer nas escolhas.'**
  String get frmOnlyInPeriodHint;

  /// No description provided for @frmSince.
  ///
  /// In pt, this message translates to:
  /// **'Desde'**
  String get frmSince;

  /// No description provided for @frmSetEnd.
  ///
  /// In pt, this message translates to:
  /// **'Definir fim'**
  String get frmSetEnd;

  /// No description provided for @frmMandatoryIn.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatória em…'**
  String get frmMandatoryIn;

  /// No description provided for @frmOptionalAllMonths.
  ///
  /// In pt, this message translates to:
  /// **'Opcional em todos os meses'**
  String get frmOptionalAllMonths;

  /// No description provided for @frmPeriodsDefined.
  ///
  /// In pt, this message translates to:
  /// **'{count} período(s) definido(s)'**
  String frmPeriodsDefined(int count);

  /// No description provided for @frmKindOptional.
  ///
  /// In pt, this message translates to:
  /// **'Despesa opcional'**
  String get frmKindOptional;

  /// No description provided for @frmKindMandatory.
  ///
  /// In pt, this message translates to:
  /// **'Despesa obrigatória'**
  String get frmKindMandatory;

  /// No description provided for @frmKindIncome.
  ///
  /// In pt, this message translates to:
  /// **'Rendimento'**
  String get frmKindIncome;

  /// No description provided for @frmKindInvestment.
  ///
  /// In pt, this message translates to:
  /// **'Investimento'**
  String get frmKindInvestment;

  /// No description provided for @frmKindBoth.
  ///
  /// In pt, this message translates to:
  /// **'Despesas e receitas'**
  String get frmKindBoth;

  /// No description provided for @frmKindOptionalHelp.
  ///
  /// In pt, this message translates to:
  /// **'Gasto que podes cortar (lazer, restaurantes…).'**
  String get frmKindOptionalHelp;

  /// No description provided for @frmKindMandatoryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Gasto fixo do mês (renda, seguros…). Depois podes escolher só alguns meses.'**
  String get frmKindMandatoryHelp;

  /// No description provided for @frmKindIncomeHelp.
  ///
  /// In pt, this message translates to:
  /// **'Entradas de dinheiro (ex.: salário). Não conta como despesa.'**
  String get frmKindIncomeHelp;

  /// No description provided for @frmKindInvestmentHelp.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro que pões a render. Não conta como gasto; aparece como investido.'**
  String get frmKindInvestmentHelp;

  /// No description provided for @frmKindBothHelp.
  ///
  /// In pt, this message translates to:
  /// **'Aceita gastos e entradas (ex.: vendas, reembolsos). Os gastos contam como despesa e as entradas como receita.'**
  String get frmKindBothHelp;

  /// No description provided for @frmAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get frmAccounts;

  /// No description provided for @frmNewAccount.
  ///
  /// In pt, this message translates to:
  /// **'Nova conta'**
  String get frmNewAccount;

  /// No description provided for @frmEditAccount.
  ///
  /// In pt, this message translates to:
  /// **'Editar conta'**
  String get frmEditAccount;

  /// No description provided for @frmAccountNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Conta à ordem'**
  String get frmAccountNameHint;

  /// No description provided for @frmOpeningBalanceCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial ({currency})'**
  String frmOpeningBalanceCurrency(String currency);

  /// No description provided for @frmOpeningBalanceHelp.
  ///
  /// In pt, this message translates to:
  /// **'Quanto tinhas na conta antes dos movimentos registados aqui.'**
  String get frmOpeningBalanceHelp;

  /// No description provided for @frmNewAccountItem.
  ///
  /// In pt, this message translates to:
  /// **'Nova conta…'**
  String get frmNewAccountItem;

  /// No description provided for @frmNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Sem conta'**
  String get frmNoAccount;

  /// No description provided for @frmNoAccountsYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens contas.\nCria uma para saberes de onde vem cada movimento e para registar transferências entre contas.'**
  String get frmNoAccountsYet;

  /// No description provided for @frmAccountSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}} · saldo {balance}'**
  String frmAccountSubtitle(int count, String balance);

  /// No description provided for @frmDeleteAccountQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Apagar a conta “{name}”? {count, plural, =0{Os {count} movimentos ficam} =1{O movimento fica} other{Os {count} movimentos ficam}} sem conta.'**
  String frmDeleteAccountQuestion(String name, int count);

  /// No description provided for @frmAccountDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Conta apagada.'**
  String get frmAccountDeleted;

  /// No description provided for @frmEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get frmEdit;

  /// No description provided for @frmBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get frmBalance;

  /// No description provided for @frmOpeningBalanceLine.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial {amount} · {count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}}'**
  String frmOpeningBalanceLine(String amount, int count);

  /// No description provided for @frmThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get frmThisMonth;

  /// No description provided for @frmMonthBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do mês'**
  String get frmMonthBalance;

  /// No description provided for @frmGoalsFedByAccount.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos alimentados por esta conta'**
  String get frmGoalsFedByAccount;

  /// No description provided for @frmNoGoalFunded.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum objetivo recebe dinheiro desta conta ainda.'**
  String get frmNoGoalFunded;

  /// No description provided for @frmNoTransactionsInAccount.
  ///
  /// In pt, this message translates to:
  /// **'Sem movimentos nesta conta.'**
  String get frmNoTransactionsInAccount;

  /// No description provided for @frmObWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo'**
  String get frmObWelcome;

  /// No description provided for @frmObFirstAccount.
  ///
  /// In pt, this message translates to:
  /// **'Primeira conta'**
  String get frmObFirstAccount;

  /// No description provided for @frmObSalary.
  ///
  /// In pt, this message translates to:
  /// **'Salário'**
  String get frmObSalary;

  /// No description provided for @frmObDone.
  ///
  /// In pt, this message translates to:
  /// **'Pronto'**
  String get frmObDone;

  /// No description provided for @frmObEnterAmount1250.
  ///
  /// In pt, this message translates to:
  /// **'Escreve um valor, por exemplo 1250,00'**
  String get frmObEnterAmount1250;

  /// No description provided for @frmObEnterAmount1500.
  ///
  /// In pt, this message translates to:
  /// **'Escreve um valor, por exemplo 1500,00'**
  String get frmObEnterAmount1500;

  /// No description provided for @frmObWelcomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo às Finanças'**
  String get frmObWelcomeTitle;

  /// No description provided for @frmObWelcomeText.
  ///
  /// In pt, this message translates to:
  /// **'Regista o dinheiro que entra e sai e vê para onde ele vai. Os teus dados ficam guardados só neste telemóvel, sem contas nem partilha.'**
  String get frmObWelcomeText;

  /// No description provided for @frmObAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual é a tua conta principal?'**
  String get frmObAccountTitle;

  /// No description provided for @frmObAccountText.
  ///
  /// In pt, this message translates to:
  /// **'Podes adicionar mais contas depois. Se não quiseres agora, deixa em branco.'**
  String get frmObAccountText;

  /// No description provided for @frmObAccountName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da conta'**
  String get frmObAccountName;

  /// No description provided for @frmObSalaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quanto recebes por mês?'**
  String get frmObSalaryTitle;

  /// No description provided for @frmObSalaryText.
  ///
  /// In pt, this message translates to:
  /// **'Salário líquido. Serve para o planeamento e para ver quanto ainda podes gastar. Podes mudar ou deixar em branco.'**
  String get frmObSalaryText;

  /// No description provided for @frmObSalaryField.
  ///
  /// In pt, this message translates to:
  /// **'Salário líquido mensal ({currency})'**
  String frmObSalaryField(String currency);

  /// No description provided for @frmObReadyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Está pronto'**
  String get frmObReadyTitle;

  /// No description provided for @frmObReadyText.
  ///
  /// In pt, this message translates to:
  /// **'Adiciona movimentos à mão ou importa um extrato. Podes mudar tudo depois nos ecrãs próprios.'**
  String get frmObReadyText;

  /// No description provided for @frmBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get frmBack;

  /// No description provided for @frmFinish.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get frmFinish;

  /// No description provided for @frmNext.
  ///
  /// In pt, this message translates to:
  /// **'Seguinte'**
  String get frmNext;

  /// No description provided for @frmAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get frmAll;

  /// No description provided for @frmExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get frmExpenses;

  /// No description provided for @frmTransfers.
  ///
  /// In pt, this message translates to:
  /// **'Transferências'**
  String get frmTransfers;

  /// No description provided for @frmTransactionsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}}'**
  String frmTransactionsCount(int count);

  /// No description provided for @frmInvestmentOf.
  ///
  /// In pt, this message translates to:
  /// **'Investimento · {name}'**
  String frmInvestmentOf(String name);

  /// No description provided for @frmOfAmount.
  ///
  /// In pt, this message translates to:
  /// **'de {amount}'**
  String frmOfAmount(String amount);

  /// No description provided for @frmNoIncomeDefined.
  ///
  /// In pt, this message translates to:
  /// **'sem rendimento definido'**
  String get frmNoIncomeDefined;

  /// No description provided for @frmSetSalaryToSpend.
  ///
  /// In pt, this message translates to:
  /// **'Define o salário no Orçamento para ver quanto ainda podes gastar.'**
  String get frmSetSalaryToSpend;

  /// No description provided for @frmOverPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Passaste {amount} do previsto'**
  String frmOverPlanned(String amount);

  /// No description provided for @frmIncomeExpected.
  ///
  /// In pt, this message translates to:
  /// **'Receitas (previstas)'**
  String get frmIncomeExpected;

  /// No description provided for @frmPercentOfIncome.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% do rendimento'**
  String frmPercentOfIncome(int percent);

  /// No description provided for @frmToClassify.
  ///
  /// In pt, this message translates to:
  /// **'{count} por classificar'**
  String frmToClassify(int count);

  /// No description provided for @frmDeliveriesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} entregas} =1{1 entrega} other{{count} entregas}} · {total}'**
  String frmDeliveriesCount(int count, String total);

  /// No description provided for @frmSetSalaryLeft.
  ///
  /// In pt, this message translates to:
  /// **'Define o salário no Orçamento para ver o que sobra.'**
  String get frmSetSalaryLeft;

  /// No description provided for @frmPlanExceeds.
  ///
  /// In pt, this message translates to:
  /// **'O plano excede o salário em {amount}'**
  String frmPlanExceeds(String amount);

  /// No description provided for @frmSavedOfTarget.
  ///
  /// In pt, this message translates to:
  /// **'{saved} de {target}{deadline}'**
  String frmSavedOfTarget(String saved, String target, String deadline);

  /// No description provided for @frmUntilDate.
  ///
  /// In pt, this message translates to:
  /// **' · até {date}'**
  String frmUntilDate(String date);

  /// No description provided for @impImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar extrato'**
  String get impImportTitle;

  /// No description provided for @impFormatsInfo.
  ///
  /// In pt, this message translates to:
  /// **'Formatos suportados: PDF (com texto), CSV e Excel (.xlsx). O ficheiro é lido apenas no telemóvel e nunca sai daqui.'**
  String get impFormatsInfo;

  /// No description provided for @impChooseFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher ficheiro'**
  String get impChooseFile;

  /// No description provided for @impChooseOtherFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher outro ficheiro'**
  String get impChooseOtherFile;

  /// No description provided for @impFileName.
  ///
  /// In pt, this message translates to:
  /// **'Ficheiro: {name}'**
  String impFileName(String name);

  /// No description provided for @impPdfNoRows.
  ///
  /// In pt, this message translates to:
  /// **'Não encontrei movimentos neste PDF. Pode ser um PDF digitalizado (imagem) ou um formato diferente. Tenta exportar CSV/Excel no homebanking.'**
  String get impPdfNoRows;

  /// No description provided for @impCsvNoRows.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui ler movimentos. Ajusta as colunas abaixo.'**
  String get impCsvNoRows;

  /// No description provided for @impReadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao ler o ficheiro: {error}'**
  String impReadError(String error);

  /// No description provided for @impStatementAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta deste extrato'**
  String get impStatementAccount;

  /// No description provided for @impPickAccountOptional.
  ///
  /// In pt, this message translates to:
  /// **'Seleciona uma conta (opcional)'**
  String get impPickAccountOptional;

  /// No description provided for @impTxnCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}}'**
  String impTxnCount(int count);

  /// No description provided for @impIncomeExpense.
  ///
  /// In pt, this message translates to:
  /// **'Entradas {income}   ·   Saídas {expense}'**
  String impIncomeExpense(String income, String expense);

  /// No description provided for @impInvertSigns.
  ///
  /// In pt, this message translates to:
  /// **'Inverter sinais'**
  String get impInvertSigns;

  /// No description provided for @impInvertSignsHint.
  ///
  /// In pt, this message translates to:
  /// **'Usa se as despesas aparecem como positivas'**
  String get impInvertSignsHint;

  /// No description provided for @impImportButton.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Importar {count} movimentos} =1{Importar 1 movimento} other{Importar {count} movimentos}}'**
  String impImportButton(int count);

  /// No description provided for @impImportDone.
  ///
  /// In pt, this message translates to:
  /// **'{added, plural, =0{{added} importados} =1{1 importado} other{{added} importados}}, {duplicates, plural, =0{{duplicates} duplicados ignorados} =1{1 duplicado ignorado} other{{duplicates} duplicados ignorados}}. {unclassified, plural, =0{{unclassified} grupos por classificar.} =1{1 grupo por classificar.} other{{unclassified} grupos por classificar.}}'**
  String impImportDone(int added, int duplicates, int unclassified);

  /// No description provided for @impClassifiedOf.
  ///
  /// In pt, this message translates to:
  /// **'Classificação: {classified} de {total, plural, =0{{total} grupos} =1{1 grupo} other{{total} grupos}}'**
  String impClassifiedOf(int classified, int total);

  /// No description provided for @impGroupsExplain.
  ///
  /// In pt, this message translates to:
  /// **'Movimentos com o mesmo nome estão juntos. Escolhe a categoria e a subcategoria de cada grupo (ou deixa por classificar). As regras já memorizadas vêm preenchidas.'**
  String get impGroupsExplain;

  /// No description provided for @impTransfersCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} transferências entre contas} =1{1 transferência entre contas} other{{count} transferências entre contas}}'**
  String impTransfersCount(int count);

  /// No description provided for @impTransfersHint.
  ///
  /// In pt, this message translates to:
  /// **'Não precisam de categoria e ficam fora das despesas e receitas.'**
  String get impTransfersHint;

  /// No description provided for @impOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Original: {description}'**
  String impOriginal(String description);

  /// No description provided for @impActiveOfTotal.
  ///
  /// In pt, this message translates to:
  /// **'{active} de {total, plural, =0{{total} movimentos} =1{1 movimento} other{{total} movimentos}}'**
  String impActiveOfTotal(int active, int total);

  /// No description provided for @impRememberedRule.
  ///
  /// In pt, this message translates to:
  /// **' · regra memorizada'**
  String get impRememberedRule;

  /// No description provided for @impNameOrGroup.
  ///
  /// In pt, this message translates to:
  /// **'Nome ou grupo (opcional)'**
  String get impNameOrGroup;

  /// No description provided for @impNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Ginásio, Restaurante Arminda…'**
  String get impNameHint;

  /// No description provided for @impJoinsGroup.
  ///
  /// In pt, this message translates to:
  /// **'Junta-se ao grupo “{name}” ({count, plural, =0{{count} títulos} =1{1 título} other{{count} títulos}})'**
  String impJoinsGroup(String name, int count);

  /// No description provided for @impRememberNameCategory.
  ///
  /// In pt, this message translates to:
  /// **'Memorizar nome e categoria para o futuro'**
  String get impRememberNameCategory;

  /// No description provided for @impViewTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Ver movimentos'**
  String get impViewTransactions;

  /// No description provided for @impAccountsInStatement.
  ///
  /// In pt, this message translates to:
  /// **'Contas neste extrato'**
  String get impAccountsInStatement;

  /// No description provided for @impAccountsDetected.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} contas detetadas} =1{1 conta detetada} other{{count} contas detetadas}}. Escolhe a que corresponde a cada uma na app.'**
  String impAccountsDetected(int count);

  /// No description provided for @impAccountTxns.
  ///
  /// In pt, this message translates to:
  /// **'{name}  ·  {count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}}'**
  String impAccountTxns(String name, int count);

  /// No description provided for @impCreateAccount.
  ///
  /// In pt, this message translates to:
  /// **'➕  Criar conta “{name}”'**
  String impCreateAccount(String name);

  /// No description provided for @impNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Sem conta'**
  String get impNoAccount;

  /// No description provided for @impDetectTransfers.
  ///
  /// In pt, this message translates to:
  /// **'Detetar transferências entre estas contas'**
  String get impDetectTransfers;

  /// No description provided for @impDetectTransfersHint.
  ///
  /// In pt, this message translates to:
  /// **'Saída numa conta e entrada noutra, do mesmo valor, não contam como despesa nem receita.'**
  String get impDetectTransfersHint;

  /// No description provided for @impSkippedTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} linhas parecem movimentos mas não foram reconhecidas} =1{1 linha parece movimentos mas não foi reconhecida} other{{count} linhas parecem movimentos mas não foram reconhecidas}}'**
  String impSkippedTitle(int count);

  /// No description provided for @impSkippedSub.
  ///
  /// In pt, this message translates to:
  /// **'Lidos: {count}. Toca para ver as linhas ignoradas.'**
  String impSkippedSub(int count);

  /// No description provided for @impAndMore.
  ///
  /// In pt, this message translates to:
  /// **'… e mais {count}'**
  String impAndMore(int count);

  /// No description provided for @impSkippedHelp.
  ///
  /// In pt, this message translates to:
  /// **'Se for um extrato do teu banco, exporta em CSV/Excel no homebanking ou envia-me um exemplo (com os dados tapados) para eu ajustar o leitor.'**
  String get impSkippedHelp;

  /// No description provided for @impYearForDates.
  ///
  /// In pt, this message translates to:
  /// **'Ano das datas sem ano'**
  String get impYearForDates;

  /// No description provided for @impYearHint.
  ///
  /// In pt, this message translates to:
  /// **'Só afeta datas escritas como dd-mm'**
  String get impYearHint;

  /// No description provided for @impFileColumns.
  ///
  /// In pt, this message translates to:
  /// **'Colunas do ficheiro'**
  String get impFileColumns;

  /// No description provided for @impHeaderRow.
  ///
  /// In pt, this message translates to:
  /// **'Linha de cabeçalho'**
  String get impHeaderRow;

  /// No description provided for @impDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get impDate;

  /// No description provided for @impDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get impDescription;

  /// No description provided for @impAmountSigned.
  ///
  /// In pt, this message translates to:
  /// **'Montante (com sinal)'**
  String get impAmountSigned;

  /// No description provided for @impDebitOut.
  ///
  /// In pt, this message translates to:
  /// **'Débito (saídas)'**
  String get impDebitOut;

  /// No description provided for @impCreditIn.
  ///
  /// In pt, this message translates to:
  /// **'Crédito (entradas)'**
  String get impCreditIn;

  /// No description provided for @impBalanceOptional.
  ///
  /// In pt, this message translates to:
  /// **'Saldo (opcional)'**
  String get impBalanceOptional;

  /// No description provided for @impDoNotUse.
  ///
  /// In pt, this message translates to:
  /// **'— não usar —'**
  String get impDoNotUse;

  /// No description provided for @impColumnN.
  ///
  /// In pt, this message translates to:
  /// **'Coluna {n}'**
  String impColumnN(int n);

  /// No description provided for @impClassifyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Classificar'**
  String get impClassifyTitle;

  /// No description provided for @impClassifySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Revê e categoriza as tuas transações importadas'**
  String get impClassifySubtitle;

  /// No description provided for @impSort.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar'**
  String get impSort;

  /// No description provided for @impSortCount.
  ///
  /// In pt, this message translates to:
  /// **'Mais movimentos'**
  String get impSortCount;

  /// No description provided for @impSortTotal.
  ///
  /// In pt, this message translates to:
  /// **'Maior valor'**
  String get impSortTotal;

  /// No description provided for @impSortRecent.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes'**
  String get impSortRecent;

  /// No description provided for @impSortName.
  ///
  /// In pt, this message translates to:
  /// **'Nome (A-Z)'**
  String get impSortName;

  /// No description provided for @impGroups.
  ///
  /// In pt, this message translates to:
  /// **'Grupos'**
  String get impGroups;

  /// No description provided for @impRules.
  ///
  /// In pt, this message translates to:
  /// **'Regras memorizadas'**
  String get impRules;

  /// No description provided for @impSearchGroups.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar grupos ou estabelecimentos…'**
  String get impSearchGroups;

  /// No description provided for @impToClassifyChip.
  ///
  /// In pt, this message translates to:
  /// **'Por classificar ({count})'**
  String impToClassifyChip(int count);

  /// No description provided for @impAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get impAll;

  /// No description provided for @impApplyRules.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar regras'**
  String get impApplyRules;

  /// No description provided for @impClassifiedByRules.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos classificados pelas regras.} =1{1 movimento classificado pelas regras.} other{{count} movimentos classificados pelas regras.}}'**
  String impClassifiedByRules(int count);

  /// No description provided for @impAllClassified.
  ///
  /// In pt, this message translates to:
  /// **'Tudo classificado! 🎉'**
  String get impAllClassified;

  /// No description provided for @impNoTransactionsYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há movimentos.'**
  String get impNoTransactionsYet;

  /// No description provided for @impClassifiedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos classificados.} =1{1 movimento classificado.} other{{count} movimentos classificados.}}'**
  String impClassifiedCount(int count);

  /// No description provided for @impSelectAll.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar tudo'**
  String get impSelectAll;

  /// No description provided for @impApplyTo.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar a {count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}}'**
  String impApplyTo(int count);

  /// No description provided for @impTxnCountDate.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos} =1{1 movimento} other{{count} movimentos}} · {date}'**
  String impTxnCountDate(int count, String date);

  /// No description provided for @impGroupChip.
  ///
  /// In pt, this message translates to:
  /// **'Grupo · {count, plural, =0{{count} títulos} =1{1 título} other{{count} títulos}}'**
  String impGroupChip(int count);

  /// No description provided for @impRemembered.
  ///
  /// In pt, this message translates to:
  /// **'Memorizado'**
  String get impRemembered;

  /// No description provided for @impSelectedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} selecionados} =1{1 selecionado} other{{count} selecionados}}'**
  String impSelectedCount(int count);

  /// No description provided for @impChooseCategory.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe a categoria'**
  String get impChooseCategory;

  /// No description provided for @impMoveTo.
  ///
  /// In pt, this message translates to:
  /// **'Mover para {category}'**
  String impMoveTo(String category);

  /// No description provided for @impRememberForFuture.
  ///
  /// In pt, this message translates to:
  /// **'Memorizar para futuros'**
  String get impRememberForFuture;

  /// No description provided for @impWhatIsThis.
  ///
  /// In pt, this message translates to:
  /// **'O que é isto?'**
  String get impWhatIsThis;

  /// No description provided for @impRememberHelp.
  ///
  /// In pt, this message translates to:
  /// **'Guarda uma regra: da próxima vez que aparecer um movimento com este título, a app aplica logo o nome e a categoria que escolheste.'**
  String get impRememberHelp;

  /// No description provided for @impOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get impOk;

  /// No description provided for @impNameAndNotes.
  ///
  /// In pt, this message translates to:
  /// **'Nome e notas'**
  String get impNameAndNotes;

  /// No description provided for @impForgetRule.
  ///
  /// In pt, this message translates to:
  /// **'Esquecer regra'**
  String get impForgetRule;

  /// No description provided for @impForgetRuleQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Esquecer a regra para “{key}”? Os movimentos já classificados mantêm-se.'**
  String impForgetRuleQuestion(String key);

  /// No description provided for @impForget.
  ///
  /// In pt, this message translates to:
  /// **'Esquecer'**
  String get impForget;

  /// No description provided for @impJoinGroup.
  ///
  /// In pt, this message translates to:
  /// **'Juntar a grupo'**
  String get impJoinGroup;

  /// No description provided for @impManageGroup.
  ///
  /// In pt, this message translates to:
  /// **'Gerir grupo'**
  String get impManageGroup;

  /// No description provided for @impJoinAGroup.
  ///
  /// In pt, this message translates to:
  /// **'Juntar a um grupo'**
  String get impJoinAGroup;

  /// No description provided for @impFriendlyName.
  ///
  /// In pt, this message translates to:
  /// **'Nome amigável (opcional)'**
  String get impFriendlyName;

  /// No description provided for @impExampleGym.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Ginásio'**
  String get impExampleGym;

  /// No description provided for @impRuleDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição da regra (opcional)'**
  String get impRuleDescription;

  /// No description provided for @impNoteAllTx.
  ///
  /// In pt, this message translates to:
  /// **'Nota em todos os movimentos (opcional)'**
  String get impNoteAllTx;

  /// No description provided for @impNameSavedHint.
  ///
  /// In pt, this message translates to:
  /// **'O nome e a descrição ficam guardados na regra, para as próximas importações.'**
  String get impNameSavedHint;

  /// No description provided for @impSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get impSave;

  /// No description provided for @impNoRules.
  ///
  /// In pt, this message translates to:
  /// **'Sem regras. Ao mover movimentos com “Memorizar”, as regras aparecem aqui.'**
  String get impNoRules;

  /// No description provided for @impEquals.
  ///
  /// In pt, this message translates to:
  /// **'Igual a'**
  String get impEquals;

  /// No description provided for @impContains.
  ///
  /// In pt, this message translates to:
  /// **'Contém'**
  String get impContains;

  /// No description provided for @impRule.
  ///
  /// In pt, this message translates to:
  /// **'Regra'**
  String get impRule;

  /// No description provided for @impNewRule.
  ///
  /// In pt, this message translates to:
  /// **'Nova regra'**
  String get impNewRule;

  /// No description provided for @impEditRule.
  ///
  /// In pt, this message translates to:
  /// **'Editar regra'**
  String get impEditRule;

  /// No description provided for @impTextToRecognize.
  ///
  /// In pt, this message translates to:
  /// **'Texto a reconhecer (MAIÚSCULAS)'**
  String get impTextToRecognize;

  /// No description provided for @impExactName.
  ///
  /// In pt, this message translates to:
  /// **'Nome exatamente igual'**
  String get impExactName;

  /// No description provided for @impExactNameOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligado: basta conter o texto'**
  String get impExactNameOff;

  /// No description provided for @impDescriptionOptional.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get impDescriptionOptional;

  /// No description provided for @impNewGroup.
  ///
  /// In pt, this message translates to:
  /// **'Novo grupo'**
  String get impNewGroup;

  /// No description provided for @impName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get impName;

  /// No description provided for @impExampleRestaurant.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Restaurante Arminda'**
  String get impExampleRestaurant;

  /// No description provided for @impCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get impCreate;

  /// No description provided for @impGroupsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens grupos.\n\nUm grupo junta títulos diferentes que são a mesma coisa, por exemplo “TRANS RESTAURANTE ARMINDA” e “MB WAY RESTAURANTE ARMINDA” → “Restaurante Arminda”, com uma categoria só.'**
  String get impGroupsEmpty;

  /// No description provided for @impDeleteGroup.
  ///
  /// In pt, this message translates to:
  /// **'Apagar grupo'**
  String get impDeleteGroup;

  /// No description provided for @impGroupDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Grupo apagado.'**
  String get impGroupDeleted;

  /// No description provided for @impDeleteGroupQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Apagar o grupo “{name}”? Os títulos ficam com o nome e a categoria que tinham no grupo, mas deixam de estar juntos.'**
  String impDeleteGroupQuestion(String name);

  /// No description provided for @impJoinTitles.
  ///
  /// In pt, this message translates to:
  /// **'Juntar títulos'**
  String get impJoinTitles;

  /// No description provided for @impGroupName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do grupo'**
  String get impGroupName;

  /// No description provided for @impGroupSaved.
  ///
  /// In pt, this message translates to:
  /// **'Grupo guardado.'**
  String get impGroupSaved;

  /// No description provided for @impGroupExists.
  ///
  /// In pt, this message translates to:
  /// **'Já existe um grupo chamado “{name}”.'**
  String impGroupExists(String name);

  /// No description provided for @impTitlesInGroup.
  ///
  /// In pt, this message translates to:
  /// **'Títulos neste grupo ({count})'**
  String impTitlesInGroup(int count);

  /// No description provided for @impGroupAnyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qualquer movimento com um destes títulos recebe o nome e a categoria do grupo, agora e nas próximas importações.'**
  String get impGroupAnyTitle;

  /// No description provided for @impGroupEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Ainda vazio. Usa “Juntar títulos”.'**
  String get impGroupEmptyHint;

  /// No description provided for @impRemoveFromGroup.
  ///
  /// In pt, this message translates to:
  /// **'Tirar do grupo'**
  String get impRemoveFromGroup;

  /// No description provided for @impSearchTitles.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar títulos'**
  String get impSearchTitles;

  /// No description provided for @impNoTitlesFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum título encontrado.'**
  String get impNoTitlesFound;

  /// No description provided for @impAlreadyInGroup.
  ///
  /// In pt, this message translates to:
  /// **' · já está em “{name}”'**
  String impAlreadyInGroup(String name);

  /// No description provided for @impOrAnyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ou: qualquer título que contenha…'**
  String get impOrAnyTitle;

  /// No description provided for @impJoin.
  ///
  /// In pt, this message translates to:
  /// **'Juntar'**
  String get impJoin;

  /// No description provided for @impTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título: {title}'**
  String impTitleLabel(String title);

  /// No description provided for @impTitlesList.
  ///
  /// In pt, this message translates to:
  /// **'{count} títulos: {list}'**
  String impTitlesList(int count, String list);

  /// No description provided for @impExistingGroup.
  ///
  /// In pt, this message translates to:
  /// **'Grupo existente'**
  String get impExistingGroup;

  /// No description provided for @impOr.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get impOr;

  /// No description provided for @impExistsJoins.
  ///
  /// In pt, this message translates to:
  /// **'Já existe: vai juntar-se a “{name}”'**
  String impExistsJoins(String name);

  /// No description provided for @impTitleCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} títulos} =1{1 título} other{{count} títulos}}'**
  String impTitleCount(int count);

  /// No description provided for @invAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get invAdd;

  /// No description provided for @invRecordOperation.
  ///
  /// In pt, this message translates to:
  /// **'Registar operação'**
  String get invRecordOperation;

  /// No description provided for @invRecordOperationHint.
  ///
  /// In pt, this message translates to:
  /// **'Compra, venda, dividendo ou o que já tinhas'**
  String get invRecordOperationHint;

  /// No description provided for @invImportFromFile.
  ///
  /// In pt, this message translates to:
  /// **'Importar de um ficheiro'**
  String get invImportFromFile;

  /// No description provided for @invImportFileHint.
  ///
  /// In pt, this message translates to:
  /// **'PDF, CSV ou Excel da corretora'**
  String get invImportFileHint;

  /// No description provided for @invNewHolding.
  ///
  /// In pt, this message translates to:
  /// **'Novo ativo'**
  String get invNewHolding;

  /// No description provided for @invNewHoldingHint.
  ///
  /// In pt, this message translates to:
  /// **'ETF, ação, cripto, fundo…'**
  String get invNewHoldingHint;

  /// No description provided for @invNewAccount.
  ///
  /// In pt, this message translates to:
  /// **'Nova plataforma'**
  String get invNewAccount;

  /// No description provided for @invNewAccountHint.
  ///
  /// In pt, this message translates to:
  /// **'XTB, Trade Republic, exchange…'**
  String get invNewAccountHint;

  /// No description provided for @invTitle.
  ///
  /// In pt, this message translates to:
  /// **'Investimentos'**
  String get invTitle;

  /// No description provided for @invImportTrades.
  ///
  /// In pt, this message translates to:
  /// **'Importar compras e vendas'**
  String get invImportTrades;

  /// No description provided for @invRefreshPrices.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar preços'**
  String get invRefreshPrices;

  /// No description provided for @invImportCardHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe um ficheiro PDF, CSV ou Excel da tua corretora'**
  String get invImportCardHint;

  /// No description provided for @invMyPortfolio.
  ///
  /// In pt, this message translates to:
  /// **'A minha carteira'**
  String get invMyPortfolio;

  /// No description provided for @invTotalValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor total'**
  String get invTotalValue;

  /// No description provided for @invInvested.
  ///
  /// In pt, this message translates to:
  /// **'Investido'**
  String get invInvested;

  /// No description provided for @invCurrentValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor atual'**
  String get invCurrentValue;

  /// No description provided for @invGainLoss.
  ///
  /// In pt, this message translates to:
  /// **'Ganho / perda'**
  String get invGainLoss;

  /// No description provided for @invUnallocated.
  ///
  /// In pt, this message translates to:
  /// **'Por alocar'**
  String get invUnallocated;

  /// No description provided for @invUnallocatedStandby.
  ///
  /// In pt, this message translates to:
  /// **'Por alocar (standby)'**
  String get invUnallocatedStandby;

  /// No description provided for @invRealizedGain.
  ///
  /// In pt, this message translates to:
  /// **'Ganho realizado'**
  String get invRealizedGain;

  /// No description provided for @invDividends.
  ///
  /// In pt, this message translates to:
  /// **'Dividendos'**
  String get invDividends;

  /// No description provided for @invPricesUpdated.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} preços atualizados.} =1{1 preço atualizado.} other{{count} preços atualizados.}}'**
  String invPricesUpdated(int count);

  /// No description provided for @invPricesFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou: {details}'**
  String invPricesFailed(String details);

  /// No description provided for @invNoAutoPrices.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ativo com preço automático.'**
  String get invNoAutoPrices;

  /// No description provided for @invPricesUpdatedAgo.
  ///
  /// In pt, this message translates to:
  /// **'Preços atualizados {ago}'**
  String invPricesUpdatedAgo(String ago);

  /// No description provided for @invNoPricesYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem preços. Carrega em atualizar.'**
  String get invNoPricesYet;

  /// No description provided for @invPricesManual.
  ///
  /// In pt, this message translates to:
  /// **'Preços definidos à mão em cada ativo.'**
  String get invPricesManual;

  /// No description provided for @invUnpricedNote.
  ///
  /// In pt, this message translates to:
  /// **'Ativos sem preço contam pelo custo, para não distorcer o total.'**
  String get invUnpricedNote;

  /// No description provided for @invWhereMoneyIs.
  ///
  /// In pt, this message translates to:
  /// **'Onde está o dinheiro'**
  String get invWhereMoneyIs;

  /// No description provided for @invByAsset.
  ///
  /// In pt, this message translates to:
  /// **'Por ativo'**
  String get invByAsset;

  /// No description provided for @invByPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Por plataforma'**
  String get invByPlatform;

  /// No description provided for @invByType.
  ///
  /// In pt, this message translates to:
  /// **'Por tipo'**
  String get invByType;

  /// No description provided for @invTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get invTotal;

  /// No description provided for @invCashToAllocate.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro por alocar'**
  String get invCashToAllocate;

  /// No description provided for @invCashSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Enviado para as plataformas e ainda não investido (standby)'**
  String get invCashSubtitle;

  /// No description provided for @invNegativeCashHint.
  ///
  /// In pt, this message translates to:
  /// **'Negativo: falta uma entrega ou um acerto de dinheiro'**
  String get invNegativeCashHint;

  /// No description provided for @invAllocate.
  ///
  /// In pt, this message translates to:
  /// **'Alocar'**
  String get invAllocate;

  /// No description provided for @invAdjust.
  ///
  /// In pt, this message translates to:
  /// **'Acertar'**
  String get invAdjust;

  /// No description provided for @invPlatforms.
  ///
  /// In pt, this message translates to:
  /// **'Plataformas'**
  String get invPlatforms;

  /// No description provided for @invAssetsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} ativos} =1{1 ativo} other{{count} ativos}}'**
  String invAssetsCount(int count);

  /// No description provided for @invAccountLine.
  ///
  /// In pt, this message translates to:
  /// **'Por alocar {cash} · {count, plural, =0{{count} ativos} =1{1 ativo} other{{count} ativos}}'**
  String invAccountLine(String cash, int count);

  /// No description provided for @invIntroTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanha o que tens investido'**
  String get invIntroTitle;

  /// No description provided for @invIntroSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Onde está o teu dinheiro, quanto vale e quanto está por alocar'**
  String get invIntroSubtitle;

  /// No description provided for @invStep1Title.
  ///
  /// In pt, this message translates to:
  /// **'1. Cria uma plataforma'**
  String get invStep1Title;

  /// No description provided for @invStep1Desc.
  ///
  /// In pt, this message translates to:
  /// **'XTB, Trade Republic, uma exchange de cripto…'**
  String get invStep1Desc;

  /// No description provided for @invStep2Title.
  ///
  /// In pt, this message translates to:
  /// **'2. Associa as transferências do banco'**
  String get invStep2Title;

  /// No description provided for @invStep2Desc.
  ///
  /// In pt, this message translates to:
  /// **'Marcas quais foram dinheiro enviado para a plataforma. Deixam de contar como despesa.'**
  String get invStep2Desc;

  /// No description provided for @invStep3Title.
  ///
  /// In pt, this message translates to:
  /// **'3. Diz o que já tinhas'**
  String get invStep3Title;

  /// No description provided for @invStep3Desc.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade e preço médio de compra do que investiste antes de usar a app.'**
  String get invStep3Desc;

  /// No description provided for @invStep4Title.
  ///
  /// In pt, this message translates to:
  /// **'4. Aloca o dinheiro'**
  String get invStep4Title;

  /// No description provided for @invStep4Desc.
  ///
  /// In pt, this message translates to:
  /// **'Regista compras. O que sobra fica por alocar (standby).'**
  String get invStep4Desc;

  /// No description provided for @invStep5Title.
  ///
  /// In pt, this message translates to:
  /// **'5. Atualiza os preços'**
  String get invStep5Title;

  /// No description provided for @invStep5Desc.
  ///
  /// In pt, this message translates to:
  /// **'Com APIs gratuitas (Yahoo Finance e CoinGecko), só quando tu pedires.'**
  String get invStep5Desc;

  /// No description provided for @invCreateFirstPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Criar a primeira plataforma'**
  String get invCreateFirstPlatform;

  /// No description provided for @invImportFromFileButton.
  ///
  /// In pt, this message translates to:
  /// **'Importar compras e vendas de um ficheiro'**
  String get invImportFromFileButton;

  /// No description provided for @invTopAssetWeight.
  ///
  /// In pt, this message translates to:
  /// **'{label} pesa {share} da carteira.'**
  String invTopAssetWeight(String label, String share);

  /// No description provided for @invKindEtf.
  ///
  /// In pt, this message translates to:
  /// **'ETF'**
  String get invKindEtf;

  /// No description provided for @invKindStock.
  ///
  /// In pt, this message translates to:
  /// **'Ação'**
  String get invKindStock;

  /// No description provided for @invKindCrypto.
  ///
  /// In pt, this message translates to:
  /// **'Cripto'**
  String get invKindCrypto;

  /// No description provided for @invKindFund.
  ///
  /// In pt, this message translates to:
  /// **'Fundo'**
  String get invKindFund;

  /// No description provided for @invKindBond.
  ///
  /// In pt, this message translates to:
  /// **'Obrigação'**
  String get invKindBond;

  /// No description provided for @invKindOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get invKindOther;

  /// No description provided for @invProviderManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get invProviderManual;

  /// No description provided for @invProviderYahoo.
  ///
  /// In pt, this message translates to:
  /// **'Yahoo Finance'**
  String get invProviderYahoo;

  /// No description provided for @invProviderCoingecko.
  ///
  /// In pt, this message translates to:
  /// **'CoinGecko'**
  String get invProviderCoingecko;

  /// No description provided for @invOpInitial.
  ///
  /// In pt, this message translates to:
  /// **'Posição inicial'**
  String get invOpInitial;

  /// No description provided for @invOpBuy.
  ///
  /// In pt, this message translates to:
  /// **'Compra'**
  String get invOpBuy;

  /// No description provided for @invOpSell.
  ///
  /// In pt, this message translates to:
  /// **'Venda'**
  String get invOpSell;

  /// No description provided for @invOpDividend.
  ///
  /// In pt, this message translates to:
  /// **'Dividendo'**
  String get invOpDividend;

  /// No description provided for @invOpCash.
  ///
  /// In pt, this message translates to:
  /// **'Acerto de dinheiro'**
  String get invOpCash;

  /// No description provided for @invAddToAccount.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar a {name}'**
  String invAddToAccount(String name);

  /// No description provided for @invDeleteAccountConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Apagar a plataforma “{name}” com os seus ativos e operações? Os movimentos do banco ficam (deixam de estar associados).'**
  String invDeleteAccountConfirm(String name);

  /// No description provided for @invSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get invSummary;

  /// No description provided for @invCashAccountSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O que está na plataforma e ainda não foi investido'**
  String get invCashAccountSubtitle;

  /// No description provided for @invBankDepositsNet.
  ///
  /// In pt, this message translates to:
  /// **'Entregas do banco (líquidas)'**
  String get invBankDepositsNet;

  /// No description provided for @invCashAdjustments.
  ///
  /// In pt, this message translates to:
  /// **'Acertos de dinheiro'**
  String get invCashAdjustments;

  /// No description provided for @invSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get invSales;

  /// No description provided for @invPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get invPurchases;

  /// No description provided for @invNegativeAccountCash.
  ///
  /// In pt, this message translates to:
  /// **'O valor está negativo: gastaste mais do que o dinheiro registado. Associa a transferência do banco ou acerta o dinheiro que já lá estava.'**
  String get invNegativeAccountCash;

  /// No description provided for @invAllocateMoney.
  ///
  /// In pt, this message translates to:
  /// **'Alocar dinheiro'**
  String get invAllocateMoney;

  /// No description provided for @invBankTransfers.
  ///
  /// In pt, this message translates to:
  /// **'Transferências do banco'**
  String get invBankTransfers;

  /// No description provided for @invMarkTransfersFor.
  ///
  /// In pt, this message translates to:
  /// **'Marca quais foram dinheiro enviado para {name}'**
  String invMarkTransfersFor(String name);

  /// No description provided for @invLinkedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} associadas · não contam como despesa} =1{1 associada · não conta como despesa} other{{count} associadas · não contam como despesa}}'**
  String invLinkedCount(int count);

  /// No description provided for @invLinkBankTransfers.
  ///
  /// In pt, this message translates to:
  /// **'Associar transferências do banco'**
  String get invLinkBankTransfers;

  /// No description provided for @invSuggestedMatches.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos parecem ser desta plataforma} =1{1 movimento parece ser desta plataforma} other{{count} movimentos parecem ser desta plataforma}}'**
  String invSuggestedMatches(int count);

  /// No description provided for @invSuggestedBody.
  ///
  /// In pt, this message translates to:
  /// **'Têm “{name}” no nome. Toca para rever e associar.'**
  String invSuggestedBody(String name);

  /// No description provided for @invUnlink.
  ///
  /// In pt, this message translates to:
  /// **'Desassociar'**
  String get invUnlink;

  /// No description provided for @invDeliveryLower.
  ///
  /// In pt, this message translates to:
  /// **'entrega'**
  String get invDeliveryLower;

  /// No description provided for @invWithdrawalLower.
  ///
  /// In pt, this message translates to:
  /// **'levantamento'**
  String get invWithdrawalLower;

  /// No description provided for @invAndMore.
  ///
  /// In pt, this message translates to:
  /// **'… e mais {count}'**
  String invAndMore(int count);

  /// No description provided for @invRememberedTitles.
  ///
  /// In pt, this message translates to:
  /// **'Títulos lembrados para as próximas importações'**
  String get invRememberedTitles;

  /// No description provided for @invAssets.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get invAssets;

  /// No description provided for @invNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get invNew;

  /// No description provided for @invNoAssetsYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem ativos. Cria um (ex.: o ETF ou a ação que compraste) e regista a posição que já tinhas ou uma compra.'**
  String get invNoAssetsYet;

  /// No description provided for @invHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get invHistory;

  /// No description provided for @invTapToEdit.
  ///
  /// In pt, this message translates to:
  /// **'Toca para editar'**
  String get invTapToEdit;

  /// No description provided for @invEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get invEdit;

  /// No description provided for @invHoldingDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Ativo apagado.'**
  String get invHoldingDeleted;

  /// No description provided for @invHoldingDeletedShort.
  ///
  /// In pt, this message translates to:
  /// **'Ativo apagado'**
  String get invHoldingDeletedShort;

  /// No description provided for @invAccountDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Plataforma apagada.'**
  String get invAccountDeleted;

  /// No description provided for @invTransferDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Transferência apagada.'**
  String get invTransferDeleted;

  /// No description provided for @invTransfersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transferências para investir'**
  String get invTransfersTitle;

  /// No description provided for @invTapToAssignWithAmount.
  ///
  /// In pt, this message translates to:
  /// **'Toca numa para dizer em que compras foi usada. Por investir: {amount}'**
  String invTapToAssignWithAmount(String amount);

  /// No description provided for @invTapToAssign.
  ///
  /// In pt, this message translates to:
  /// **'Toca numa para dizer em que compras foi usada'**
  String get invTapToAssign;

  /// No description provided for @invSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas ({count})'**
  String invSeeAll(int count);

  /// No description provided for @invNoTransfersYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não associaste transferências do banco a uma plataforma.'**
  String get invNoTransfersYet;

  /// No description provided for @invNothingAssigned.
  ///
  /// In pt, this message translates to:
  /// **'Nada associado ainda · toca para escolher as compras'**
  String get invNothingAssigned;

  /// No description provided for @invAllocationSummary.
  ///
  /// In pt, this message translates to:
  /// **'Investido {allocated} · {holdText}'**
  String invAllocationSummary(String allocated, String holdText);

  /// No description provided for @invOnHoldLower.
  ///
  /// In pt, this message translates to:
  /// **'em espera {amount}'**
  String invOnHoldLower(String amount);

  /// No description provided for @invOverAllocatedLower.
  ///
  /// In pt, this message translates to:
  /// **'mais {amount} do que a transferência'**
  String invOverAllocatedLower(String amount);

  /// No description provided for @invInvestedAmount.
  ///
  /// In pt, this message translates to:
  /// **'Investido {amount}'**
  String invInvestedAmount(String amount);

  /// No description provided for @invOnHold.
  ///
  /// In pt, this message translates to:
  /// **'Em espera {amount}'**
  String invOnHold(String amount);

  /// No description provided for @invMoreThanAmount.
  ///
  /// In pt, this message translates to:
  /// **'Mais {amount}'**
  String invMoreThanAmount(String amount);

  /// No description provided for @invUseTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Usar esta transferência'**
  String get invUseTransfer;

  /// No description provided for @invPlatformDefault.
  ///
  /// In pt, this message translates to:
  /// **'Plataforma'**
  String get invPlatformDefault;

  /// No description provided for @invThePlatform.
  ///
  /// In pt, this message translates to:
  /// **'a plataforma'**
  String get invThePlatform;

  /// No description provided for @invTransferTo.
  ///
  /// In pt, this message translates to:
  /// **'{amount} para {name}'**
  String invTransferTo(String amount, String name);

  /// No description provided for @invOverAllocatedNote.
  ///
  /// In pt, this message translates to:
  /// **'As compras escolhidas somam mais do que a transferência. Deve ter entrado dinheiro de antes; podes continuar.'**
  String get invOverAllocatedNote;

  /// No description provided for @invHoldRemainder.
  ///
  /// In pt, this message translates to:
  /// **'{amount} desta transferência ficou em espera, por investir.'**
  String invHoldRemainder(String amount);

  /// No description provided for @invSuggest.
  ///
  /// In pt, this message translates to:
  /// **'Sugerir'**
  String get invSuggest;

  /// No description provided for @invClearAll.
  ///
  /// In pt, this message translates to:
  /// **'Limpar (tudo em espera)'**
  String get invClearAll;

  /// No description provided for @invSaveAllOnHold.
  ///
  /// In pt, this message translates to:
  /// **'Guardar (tudo em espera)'**
  String get invSaveAllOnHold;

  /// No description provided for @invSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get invSave;

  /// No description provided for @invBuysOnPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Compras nesta plataforma'**
  String get invBuysOnPlatform;

  /// No description provided for @invMarkBuysHint.
  ///
  /// In pt, this message translates to:
  /// **'Marca as que foram pagas com esta transferência.'**
  String get invMarkBuysHint;

  /// No description provided for @invNoBuysYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há compras registadas nesta plataforma.'**
  String get invNoBuysYet;

  /// No description provided for @invUsedElsewhere.
  ///
  /// In pt, this message translates to:
  /// **'usada noutra transferência'**
  String get invUsedElsewhere;

  /// No description provided for @invUnits.
  ///
  /// In pt, this message translates to:
  /// **'{qty} un.'**
  String invUnits(String qty);

  /// No description provided for @invSetPrice.
  ///
  /// In pt, this message translates to:
  /// **'Definir preço'**
  String get invSetPrice;

  /// No description provided for @invSetPriceManual.
  ///
  /// In pt, this message translates to:
  /// **'Definir à mão'**
  String get invSetPriceManual;

  /// No description provided for @invPricePerUnit.
  ///
  /// In pt, this message translates to:
  /// **'Preço por unidade ({currency})'**
  String invPricePerUnit(String currency);

  /// No description provided for @invFxRate.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio: 1 {base} = ? {currency}'**
  String invFxRate(String base, String currency);

  /// No description provided for @invCurrentPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço atual'**
  String get invCurrentPrice;

  /// No description provided for @invNoPrice.
  ///
  /// In pt, this message translates to:
  /// **'Sem preço'**
  String get invNoPrice;

  /// No description provided for @invCurrencyChip.
  ///
  /// In pt, this message translates to:
  /// **'Moeda: {currency} · {mode}'**
  String invCurrencyChip(String currency, String mode);

  /// No description provided for @invCurrencyChosen.
  ///
  /// In pt, this message translates to:
  /// **'escolhida'**
  String get invCurrencyChosen;

  /// No description provided for @invCurrencyAuto.
  ///
  /// In pt, this message translates to:
  /// **'automática'**
  String get invCurrencyAuto;

  /// No description provided for @invUpdatedAgo.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado {ago} · {date}'**
  String invUpdatedAgo(String ago, String date);

  /// No description provided for @invRefreshPrice.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar preço'**
  String get invRefreshPrice;

  /// No description provided for @invPriceUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Preço atualizado.'**
  String get invPriceUpdated;

  /// No description provided for @invRefreshFailedReason.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui atualizar: {reason}'**
  String invRefreshFailedReason(String reason);

  /// No description provided for @invErrorWord.
  ///
  /// In pt, this message translates to:
  /// **'erro'**
  String get invErrorWord;

  /// No description provided for @invDeleteHoldingConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Apagar o ativo “{name}” e as suas operações?'**
  String invDeleteHoldingConfirm(String name);

  /// No description provided for @invMyPosition.
  ///
  /// In pt, this message translates to:
  /// **'A minha posição'**
  String get invMyPosition;

  /// No description provided for @invNoPositionYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem posição. Regista a quantidade e o preço médio do que já tinhas, ou uma compra.'**
  String get invNoPositionYet;

  /// No description provided for @invQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get invQuantity;

  /// No description provided for @invAvgCost.
  ///
  /// In pt, this message translates to:
  /// **'Preço médio de compra'**
  String get invAvgCost;

  /// No description provided for @invGainIn.
  ///
  /// In pt, this message translates to:
  /// **'Ganho em {currency}'**
  String invGainIn(String currency);

  /// No description provided for @invPriceOnly.
  ///
  /// In pt, this message translates to:
  /// **'só o preço'**
  String get invPriceOnly;

  /// No description provided for @invSetPriceToSeePl.
  ///
  /// In pt, this message translates to:
  /// **'Define o preço atual para ver o ganho ou perda.'**
  String get invSetPriceToSeePl;

  /// No description provided for @invBuy.
  ///
  /// In pt, this message translates to:
  /// **'Comprar'**
  String get invBuy;

  /// No description provided for @invSell.
  ///
  /// In pt, this message translates to:
  /// **'Vender'**
  String get invSell;

  /// No description provided for @invOperations.
  ///
  /// In pt, this message translates to:
  /// **'Operações'**
  String get invOperations;

  /// No description provided for @invFeeLabel.
  ///
  /// In pt, this message translates to:
  /// **'comissão {amount}'**
  String invFeeLabel(String amount);

  /// No description provided for @invPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Plano de investimento'**
  String get invPlanTitle;

  /// No description provided for @invPlanCardDesc.
  ///
  /// In pt, this message translates to:
  /// **'Quando entra uma transferência numa plataforma, a Carteira mostra quanto vai para cada ativo. A app não regista compras.'**
  String get invPlanCardDesc;

  /// No description provided for @invNoPlan.
  ///
  /// In pt, this message translates to:
  /// **'Sem plano'**
  String get invNoPlan;

  /// No description provided for @invMissingPercent.
  ///
  /// In pt, this message translates to:
  /// **'faltam {pct}% por distribuir'**
  String invMissingPercent(String pct);

  /// No description provided for @invPlanOf.
  ///
  /// In pt, this message translates to:
  /// **'Plano de {name}'**
  String invPlanOf(String name);

  /// No description provided for @invPlanEditorHint.
  ///
  /// In pt, this message translates to:
  /// **'Percentagem de cada entrega para cada ativo. Podes deixar parte por distribuir.'**
  String get invPlanEditorHint;

  /// No description provided for @invPlanNoAssets.
  ///
  /// In pt, this message translates to:
  /// **'Esta plataforma ainda não tem ativos. Adiciona ativos na Carteira.'**
  String get invPlanNoAssets;

  /// No description provided for @invPlanOver.
  ///
  /// In pt, this message translates to:
  /// **'Passa {pct}% dos 100%.'**
  String invPlanOver(String pct);

  /// No description provided for @invPlanTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total: {pct}%'**
  String invPlanTotal(String pct);

  /// No description provided for @invSumOver100.
  ///
  /// In pt, this message translates to:
  /// **'A soma não pode passar 100%.'**
  String get invSumOver100;

  /// No description provided for @invInvalidValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido.'**
  String get invInvalidValue;

  /// No description provided for @invSavePlan.
  ///
  /// In pt, this message translates to:
  /// **'Guardar plano'**
  String get invSavePlan;

  /// No description provided for @invRemovePlan.
  ///
  /// In pt, this message translates to:
  /// **'Remover plano'**
  String get invRemovePlan;

  /// No description provided for @invPendingDeliveries.
  ///
  /// In pt, this message translates to:
  /// **'Entregas para distribuir ({count})'**
  String invPendingDeliveries(int count);

  /// No description provided for @invUndistributed.
  ///
  /// In pt, this message translates to:
  /// **'Por distribuir: {amount}'**
  String invUndistributed(String amount);

  /// No description provided for @invSeen.
  ///
  /// In pt, this message translates to:
  /// **'Visto'**
  String get invSeen;

  /// No description provided for @invAvgShort.
  ///
  /// In pt, this message translates to:
  /// **'médio'**
  String get invAvgShort;

  /// No description provided for @invNoPriceShort.
  ///
  /// In pt, this message translates to:
  /// **'sem preço'**
  String get invNoPriceShort;

  /// No description provided for @invClosedPosition.
  ///
  /// In pt, this message translates to:
  /// **'Posição fechada'**
  String get invClosedPosition;

  /// No description provided for @invfAccountNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova plataforma'**
  String get invfAccountNewTitle;

  /// No description provided for @invfAccountEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar plataforma'**
  String get invfAccountEditTitle;

  /// No description provided for @invfName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get invfName;

  /// No description provided for @invfAccountNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: XTB, Trade Republic'**
  String get invfAccountNameHint;

  /// No description provided for @invfNoteOptional.
  ///
  /// In pt, this message translates to:
  /// **'Nota (opcional)'**
  String get invfNoteOptional;

  /// No description provided for @invfNote.
  ///
  /// In pt, this message translates to:
  /// **'Nota'**
  String get invfNote;

  /// No description provided for @invfSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get invfSave;

  /// No description provided for @invfSaveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Guardar alterações'**
  String get invfSaveChanges;

  /// No description provided for @invfEnterName.
  ///
  /// In pt, this message translates to:
  /// **'Indica um nome'**
  String get invfEnterName;

  /// No description provided for @invfAccountNameTaken.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma plataforma com este nome'**
  String get invfAccountNameTaken;

  /// No description provided for @invfSearchIn.
  ///
  /// In pt, this message translates to:
  /// **'Procurar em {provider}'**
  String invfSearchIn(String provider);

  /// No description provided for @invfCryptoSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: bitcoin'**
  String get invfCryptoSearchHint;

  /// No description provided for @invfSymbolSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: VWCE, Apple, S&P 500'**
  String get invfSymbolSearchHint;

  /// No description provided for @invfSearchFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível pesquisar.'**
  String get invfSearchFailed;

  /// No description provided for @invfNothingFound.
  ///
  /// In pt, this message translates to:
  /// **'Nada encontrado.'**
  String get invfNothingFound;

  /// No description provided for @invfClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get invfClose;

  /// No description provided for @invfHoldingNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo ativo'**
  String get invfHoldingNewTitle;

  /// No description provided for @invfHoldingEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar ativo'**
  String get invfHoldingEditTitle;

  /// No description provided for @invfHoldingNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Vanguard FTSE All-World'**
  String get invfHoldingNameHint;

  /// No description provided for @invfPlatform.
  ///
  /// In pt, this message translates to:
  /// **'Plataforma'**
  String get invfPlatform;

  /// No description provided for @invfType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get invfType;

  /// No description provided for @invfAssetCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda do ativo'**
  String get invfAssetCurrency;

  /// No description provided for @invfAutoCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Automática (a do preço)'**
  String get invfAutoCurrency;

  /// No description provided for @invfBaseCurrencyOption.
  ///
  /// In pt, this message translates to:
  /// **'{ccy} · moeda de base'**
  String invfBaseCurrencyOption(String ccy);

  /// No description provided for @invfCurrencyAutoHint.
  ///
  /// In pt, this message translates to:
  /// **'Usa a moeda em que o ativo cota ({ccy}). Podes escolher outra à mão.'**
  String invfCurrencyAutoHint(String ccy);

  /// No description provided for @invfDetectedOnPrice.
  ///
  /// In pt, this message translates to:
  /// **'detetada ao obter o preço'**
  String get invfDetectedOnPrice;

  /// No description provided for @invfUsdHint.
  ///
  /// In pt, this message translates to:
  /// **'Para ações ou ETFs em dólares, escolhe USD: os preços de compra ficam na moeda do ativo, com o câmbio de cada compra.'**
  String get invfUsdHint;

  /// No description provided for @invfForeignCcyHint.
  ///
  /// In pt, this message translates to:
  /// **'Compras e preço médio ficam em {ccy}; o valor e o ganho da carteira são convertidos para a moeda de base ao câmbio de mercado (atualizado em \"Atualizar preços\").'**
  String invfForeignCcyHint(String ccy);

  /// No description provided for @invfPriceWithCcy.
  ///
  /// In pt, this message translates to:
  /// **'Preço ({ccy})'**
  String invfPriceWithCcy(String ccy);

  /// No description provided for @invfAvgPriceWithCcy.
  ///
  /// In pt, this message translates to:
  /// **'Preço médio ({ccy})'**
  String invfAvgPriceWithCcy(String ccy);

  /// No description provided for @invfYahooHint.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito, sem chave. ETFs, ações e câmbios (ex.: VWCE.DE, AAPL, BTC-EUR). Converte para euros.'**
  String get invfYahooHint;

  /// No description provided for @invfCoingeckoHint.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito, sem chave. Criptomoedas, pelo id (ex.: bitcoin, ethereum).'**
  String get invfCoingeckoHint;

  /// No description provided for @invfManualHint.
  ///
  /// In pt, this message translates to:
  /// **'Tu defines o preço quando quiseres. Nada é enviado para a internet.'**
  String get invfManualHint;

  /// No description provided for @invfCoingeckoId.
  ///
  /// In pt, this message translates to:
  /// **'Id no CoinGecko'**
  String get invfCoingeckoId;

  /// No description provided for @invfNewPlatformItem.
  ///
  /// In pt, this message translates to:
  /// **'➕  Nova plataforma…'**
  String get invfNewPlatformItem;

  /// No description provided for @invfSymbol.
  ///
  /// In pt, this message translates to:
  /// **'Símbolo'**
  String get invfSymbol;

  /// No description provided for @invfPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço'**
  String get invfPrice;

  /// No description provided for @invfSearchTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Procurar'**
  String get invfSearchTooltip;

  /// No description provided for @invfCurrentPriceOptional.
  ///
  /// In pt, this message translates to:
  /// **'Preço atual ({ccy}, opcional)'**
  String invfCurrentPriceOptional(String ccy);

  /// No description provided for @invfFxLabel.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio: 1 {base} = ? {ccy}'**
  String invfFxLabel(String base, String ccy);

  /// No description provided for @invfFxRateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio (1 {base} = ? {ccy})'**
  String invfFxRateLabel(String base, String ccy);

  /// No description provided for @invfAvgFxLabel.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio médio (1 {base} = ? {ccy})'**
  String invfAvgFxLabel(String base, String ccy);

  /// No description provided for @invfLiveFxTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio de mercado atual (internet)'**
  String get invfLiveFxTooltip;

  /// No description provided for @invfFxFetchFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui obter o câmbio: {message}'**
  String invfFxFetchFailed(String message);

  /// No description provided for @invfPriceFetchFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui obter o preço: {message}'**
  String invfPriceFetchFailed(String message);

  /// No description provided for @invfSymbolRequired.
  ///
  /// In pt, this message translates to:
  /// **'Indica o símbolo (ou usa a pesquisa)'**
  String get invfSymbolRequired;

  /// No description provided for @invfFxOrSyncRequired.
  ///
  /// In pt, this message translates to:
  /// **'Indica o câmbio, ou usa o botão de sincronizar para o câmbio de mercado.'**
  String get invfFxOrSyncRequired;

  /// No description provided for @invfCurrencyPickerHint.
  ///
  /// In pt, this message translates to:
  /// **'O valor é convertido para {base} ao câmbio de mercado, atualizado em \"Atualizar preços\". As operações já registadas mantêm os valores que lá estão.'**
  String invfCurrencyPickerHint(String base);

  /// No description provided for @invfOpNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova operação'**
  String get invfOpNewTitle;

  /// No description provided for @invfOpEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar · {type}'**
  String invfOpEditTitle(String type);

  /// No description provided for @invfOpInitial.
  ///
  /// In pt, this message translates to:
  /// **'Posição inicial'**
  String get invfOpInitial;

  /// No description provided for @invfOpBuy.
  ///
  /// In pt, this message translates to:
  /// **'Compra'**
  String get invfOpBuy;

  /// No description provided for @invfOpSell.
  ///
  /// In pt, this message translates to:
  /// **'Venda'**
  String get invfOpSell;

  /// No description provided for @invfOpDividend.
  ///
  /// In pt, this message translates to:
  /// **'Dividendo'**
  String get invfOpDividend;

  /// No description provided for @invfOpCash.
  ///
  /// In pt, this message translates to:
  /// **'Acerto de dinheiro'**
  String get invfOpCash;

  /// No description provided for @invfOpAlreadyHeld.
  ///
  /// In pt, this message translates to:
  /// **'Já tinha'**
  String get invfOpAlreadyHeld;

  /// No description provided for @invfOpCashChip.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get invfOpCashChip;

  /// No description provided for @invfPlatformLower.
  ///
  /// In pt, this message translates to:
  /// **'plataforma'**
  String get invfPlatformLower;

  /// No description provided for @invfTotalToPay.
  ///
  /// In pt, this message translates to:
  /// **'Total a pagar: {amount}'**
  String invfTotalToPay(String amount);

  /// No description provided for @invfTotalToPayFee.
  ///
  /// In pt, this message translates to:
  /// **'Total a pagar: {amount} (com {fee} de comissão)'**
  String invfTotalToPayFee(String amount, String fee);

  /// No description provided for @invfNoAllocationHint.
  ///
  /// In pt, this message translates to:
  /// **'Sem alocação: não desconta do dinheiro por alocar. Podes registar a transferência do banco quando quiseres.'**
  String get invfNoAllocationHint;

  /// No description provided for @invfNotEnoughUnallocated.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tens {amount} por alocar nesta plataforma (tens {cash}). Regista a transferência do banco depois, ou desliga \"Descontar do dinheiro por alocar\" em Mais opções.'**
  String invfNotEnoughUnallocated(String amount, String cash);

  /// No description provided for @invfUnallocatedChange.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro por alocar: {before} → {after}.'**
  String invfUnallocatedChange(String before, String after);

  /// No description provided for @invfUnallocatedChangeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro por alocar: {before} → {after}'**
  String invfUnallocatedChangeTitle(String before, String after);

  /// No description provided for @invfBalanceChange.
  ///
  /// In pt, this message translates to:
  /// **'{before} → {after}.'**
  String invfBalanceChange(String before, String after);

  /// No description provided for @invfYouReceive.
  ///
  /// In pt, this message translates to:
  /// **'Recebes {amount}'**
  String invfYouReceive(String amount);

  /// No description provided for @invfRealizedGain.
  ///
  /// In pt, this message translates to:
  /// **'Ganho realizado: {gain} (preço médio {avg}).'**
  String invfRealizedGain(String gain, String avg);

  /// No description provided for @invfPositionCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo da posição: {amount}'**
  String invfPositionCost(String amount);

  /// No description provided for @invfInitialHint.
  ///
  /// In pt, this message translates to:
  /// **'Posição que já tinhas antes de usar a app. Define o preço médio de compra e não mexe no dinheiro por alocar.'**
  String get invfInitialHint;

  /// No description provided for @invfDividendIn.
  ///
  /// In pt, this message translates to:
  /// **'Entram {amount} no dinheiro por alocar'**
  String invfDividendIn(String amount);

  /// No description provided for @invfCashHint.
  ///
  /// In pt, this message translates to:
  /// **'Usa isto para dinheiro que já estava na plataforma antes de começares a usar a app.'**
  String get invfCashHint;

  /// No description provided for @invfValueWithCcy.
  ///
  /// In pt, this message translates to:
  /// **'Valor ({base})'**
  String invfValueWithCcy(String base);

  /// No description provided for @invfReceivedWithCcy.
  ///
  /// In pt, this message translates to:
  /// **'Valor recebido ({base})'**
  String invfReceivedWithCcy(String base);

  /// No description provided for @invfFeeWithCcy.
  ///
  /// In pt, this message translates to:
  /// **'Comissão ({base})'**
  String invfFeeWithCcy(String base);

  /// No description provided for @invfQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get invfQuantity;

  /// No description provided for @invfUnitsEquals.
  ///
  /// In pt, this message translates to:
  /// **'= {qty} unidades'**
  String invfUnitsEquals(String qty);

  /// No description provided for @invfCashIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrada'**
  String get invfCashIn;

  /// No description provided for @invfCashOut.
  ///
  /// In pt, this message translates to:
  /// **'Saída'**
  String get invfCashOut;

  /// No description provided for @invfDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get invfDate;

  /// No description provided for @invfHolding.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get invfHolding;

  /// No description provided for @invfNewAssetItem.
  ///
  /// In pt, this message translates to:
  /// **'➕  Novo ativo…'**
  String get invfNewAssetItem;

  /// No description provided for @invfChoosePlatformHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolher plataforma'**
  String get invfChoosePlatformHint;

  /// No description provided for @invfChoosePlatformShort.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe a plataforma'**
  String get invfChoosePlatformShort;

  /// No description provided for @invfChoosePlatform.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe a plataforma.'**
  String get invfChoosePlatform;

  /// No description provided for @invfChooseAsset.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o ativo (ou cria um).'**
  String get invfChooseAsset;

  /// No description provided for @invfEnterValidAmounts.
  ///
  /// In pt, this message translates to:
  /// **'Indica valores válidos.'**
  String get invfEnterValidAmounts;

  /// No description provided for @invfFxRequired.
  ///
  /// In pt, this message translates to:
  /// **'Indica o câmbio (1 {base} = ? {ccy}).'**
  String invfFxRequired(String base, String ccy);

  /// No description provided for @invfEnterQtyPrice.
  ///
  /// In pt, this message translates to:
  /// **'Indica a quantidade e o preço.'**
  String get invfEnterQtyPrice;

  /// No description provided for @invfOnlyHaveUnits.
  ///
  /// In pt, this message translates to:
  /// **'Só tens {qty} unidades para vender.'**
  String invfOnlyHaveUnits(String qty);

  /// No description provided for @invfMoreOptionsTrade.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções (comissão, nota…)'**
  String get invfMoreOptionsTrade;

  /// No description provided for @invfDeductUnallocated.
  ///
  /// In pt, this message translates to:
  /// **'Descontar do dinheiro por alocar'**
  String get invfDeductUnallocated;

  /// No description provided for @invfDeductHint.
  ///
  /// In pt, this message translates to:
  /// **'Desliga se ainda não registaste a transferência do banco para a plataforma, ou se esta operação já está contada noutro lado.'**
  String get invfDeductHint;

  /// No description provided for @invfUseTotalInstead.
  ///
  /// In pt, this message translates to:
  /// **'Indicar o valor total em vez da quantidade'**
  String get invfUseTotalInstead;

  /// No description provided for @invfAssetCurrencyChange.
  ///
  /// In pt, this message translates to:
  /// **'Moeda do ativo: {ccy} · alterar'**
  String invfAssetCurrencyChange(String ccy);

  /// No description provided for @invfHasInitialTitle.
  ///
  /// In pt, this message translates to:
  /// **'Este ativo já tem uma posição inicial'**
  String get invfHasInitialTitle;

  /// No description provided for @invfHasInitialBody.
  ///
  /// In pt, this message translates to:
  /// **'Está carregada aqui. Ao guardar, substitui a anterior.'**
  String get invfHasInitialBody;

  /// No description provided for @invfDeleteOp.
  ///
  /// In pt, this message translates to:
  /// **'Apagar operação'**
  String get invfDeleteOp;

  /// No description provided for @invfLinkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Associar a {name}'**
  String invfLinkTitle(String name);

  /// No description provided for @invfLinkButton.
  ///
  /// In pt, this message translates to:
  /// **'Associar'**
  String get invfLinkButton;

  /// No description provided for @invfLinkCount.
  ///
  /// In pt, this message translates to:
  /// **'Associar {count} ({amount} para a plataforma)'**
  String invfLinkCount(int count, String amount);

  /// No description provided for @invfLinkHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe os movimentos do banco que foram dinheiro enviado para (ou recebido de) esta plataforma. Deixam de contar como despesa.'**
  String get invfLinkHint;

  /// No description provided for @invfSearchTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar movimentos'**
  String get invfSearchTransactions;

  /// No description provided for @invfNoTransactionsToLink.
  ///
  /// In pt, this message translates to:
  /// **'Não há movimentos por associar.'**
  String get invfNoTransactionsToLink;

  /// No description provided for @invfLooksLikeThis.
  ///
  /// In pt, this message translates to:
  /// **' · parece desta plataforma'**
  String get invfLooksLikeThis;

  /// No description provided for @invfRememberTitles.
  ///
  /// In pt, this message translates to:
  /// **'Lembrar estes títulos'**
  String get invfRememberTitles;

  /// No description provided for @invfRememberHint.
  ///
  /// In pt, this message translates to:
  /// **'Nas próximas importações, movimentos com o mesmo título são associados sozinhos.'**
  String get invfRememberHint;

  /// No description provided for @invfImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar compras e vendas'**
  String get invfImportTitle;

  /// No description provided for @invfImportIntro.
  ///
  /// In pt, this message translates to:
  /// **'Formatos: PDF (com texto), CSV e Excel (.xlsx). O ficheiro é lido no telemóvel e nunca sai daqui. Reconhece compras, vendas e dividendos; o resto (depósitos, impostos…) é ignorado.'**
  String get invfImportIntro;

  /// No description provided for @invfChooseFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher ficheiro'**
  String get invfChooseFile;

  /// No description provided for @invfChooseOtherFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher outro ficheiro'**
  String get invfChooseOtherFile;

  /// No description provided for @invfFileName.
  ///
  /// In pt, this message translates to:
  /// **'Ficheiro: {name}'**
  String invfFileName(String name);

  /// No description provided for @invfReadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao ler o ficheiro: {error}'**
  String invfReadError(String error);

  /// No description provided for @invfExcelNoData.
  ///
  /// In pt, this message translates to:
  /// **'O ficheiro Excel não tem dados.'**
  String get invfExcelNoData;

  /// No description provided for @invfPdfNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Não encontrei compras ou vendas neste PDF. Pode ser digitalizado (imagem) ou ter um formato diferente. Se a corretora permitir, exporta em CSV ou Excel.'**
  String get invfPdfNotFound;

  /// No description provided for @invfNotFoundTrades.
  ///
  /// In pt, this message translates to:
  /// **'Não encontrei compras ou vendas. Indica abaixo que coluna é cada coisa.'**
  String get invfNotFoundTrades;

  /// No description provided for @invfNotFoundWithColumns.
  ///
  /// In pt, this message translates to:
  /// **'Não encontrei compras ou vendas com estas colunas.'**
  String get invfNotFoundWithColumns;

  /// No description provided for @invfCurrencyAndRate.
  ///
  /// In pt, this message translates to:
  /// **'Moeda e câmbio'**
  String get invfCurrencyAndRate;

  /// No description provided for @invfCurrencyIntro.
  ///
  /// In pt, this message translates to:
  /// **'Linhas sem moeda indicada usam a moeda abaixo. Para moedas diferentes de {base} indica o câmbio médio; podes afinar cada operação depois.'**
  String invfCurrencyIntro(String base);

  /// No description provided for @invfTransactionCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda das operações'**
  String get invfTransactionCurrency;

  /// No description provided for @invfAllInBase.
  ///
  /// In pt, this message translates to:
  /// **'Todas as operações estão em {base}.'**
  String invfAllInBase(String base);

  /// No description provided for @invfAssetsFound.
  ///
  /// In pt, this message translates to:
  /// **'Ativos encontrados'**
  String get invfAssetsFound;

  /// No description provided for @invfAssetsHint.
  ///
  /// In pt, this message translates to:
  /// **'Liga cada um a um ativo teu, cria um novo ou ignora.'**
  String get invfAssetsHint;

  /// No description provided for @invfTradeCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'{name}  ·  {count, plural, =0{{count} operações} =1{{count} operação} other{{count} operações}}'**
  String invfTradeCountLabel(String name, int count);

  /// No description provided for @invfCreateNewAsset.
  ///
  /// In pt, this message translates to:
  /// **'➕  Criar ativo novo'**
  String get invfCreateNewAsset;

  /// No description provided for @invfIgnore.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar'**
  String get invfIgnore;

  /// No description provided for @invfOperations.
  ///
  /// In pt, this message translates to:
  /// **'Operações'**
  String get invfOperations;

  /// No description provided for @invfBuysCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} compras} =1{{count} compra} other{{count} compras}}'**
  String invfBuysCount(int count);

  /// No description provided for @invfSellsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} vendas} =1{{count} venda} other{{count} vendas}}'**
  String invfSellsCount(int count);

  /// No description provided for @invfDividendsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} dividendos} =1{{count} dividendo} other{{count} dividendos}}'**
  String invfDividendsCount(int count);

  /// No description provided for @invfDuplicatesIgnored.
  ///
  /// In pt, this message translates to:
  /// **'{count} já existentes (ignoradas)'**
  String invfDuplicatesIgnored(int count);

  /// No description provided for @invfMissingRate.
  ///
  /// In pt, this message translates to:
  /// **'Falta o câmbio'**
  String get invfMissingRate;

  /// No description provided for @invfMissingRateBody.
  ///
  /// In pt, this message translates to:
  /// **'Indica o câmbio de {currencies} para importar essas operações.'**
  String invfMissingRateBody(String currencies);

  /// No description provided for @invfAllCurrencies.
  ///
  /// In pt, this message translates to:
  /// **'todas as moedas'**
  String get invfAllCurrencies;

  /// No description provided for @invfMissingQtyTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} operações sem quantidade} =1{1 operação sem quantidade} other{{count} operações sem quantidade}}'**
  String invfMissingQtyTitle(int count);

  /// No description provided for @invfMissingQtyBody.
  ///
  /// In pt, this message translates to:
  /// **'O ficheiro só tem o valor pago. Escolhe a coluna que traz a quantidade e o preço (ex.: o comentário) em \"Colunas do ficheiro\".'**
  String get invfMissingQtyBody;

  /// No description provided for @invfShowingFirst.
  ///
  /// In pt, this message translates to:
  /// **'A mostrar as primeiras 300 de {total}.'**
  String invfShowingFirst(int total);

  /// No description provided for @invfAlreadyExists.
  ///
  /// In pt, this message translates to:
  /// **' · já existe'**
  String get invfAlreadyExists;

  /// No description provided for @invfTradeQtyPart.
  ///
  /// In pt, this message translates to:
  /// **' · {qty} un. × {price} {ccy}'**
  String invfTradeQtyPart(String qty, String price, String ccy);

  /// No description provided for @invfImportCount.
  ///
  /// In pt, this message translates to:
  /// **'Importar {count, plural, =0{0 operações} =1{1 operação} other{{count} operações}}'**
  String invfImportCount(int count);

  /// No description provided for @invfFileColumns.
  ///
  /// In pt, this message translates to:
  /// **'Colunas do ficheiro'**
  String get invfFileColumns;

  /// No description provided for @invfAutoRecognized.
  ///
  /// In pt, this message translates to:
  /// **'Reconhecidas automaticamente. Toca para ajustar.'**
  String get invfAutoRecognized;

  /// No description provided for @invfIndicateColumns.
  ///
  /// In pt, this message translates to:
  /// **'Indica que coluna é cada coisa.'**
  String get invfIndicateColumns;

  /// No description provided for @invfExcelSheet.
  ///
  /// In pt, this message translates to:
  /// **'Folha do Excel'**
  String get invfExcelSheet;

  /// No description provided for @invfSheetRows.
  ///
  /// In pt, this message translates to:
  /// **'{name}  ·  {count, plural, =0{{count} linhas} =1{1 linha} other{{count} linhas}}'**
  String invfSheetRows(String name, int count);

  /// No description provided for @invfHeaderRow.
  ///
  /// In pt, this message translates to:
  /// **'Linha dos títulos das colunas'**
  String get invfHeaderRow;

  /// No description provided for @invfNoHeaders.
  ///
  /// In pt, this message translates to:
  /// **'Sem títulos'**
  String get invfNoHeaders;

  /// No description provided for @invfHeaderRowItem.
  ///
  /// In pt, this message translates to:
  /// **'Linha {n}: {text}'**
  String invfHeaderRowItem(int n, String text);

  /// No description provided for @invfNotExists.
  ///
  /// In pt, this message translates to:
  /// **'— não existe —'**
  String get invfNotExists;

  /// No description provided for @invfColumnNumber.
  ///
  /// In pt, this message translates to:
  /// **'Coluna {n}'**
  String invfColumnNumber(int n);

  /// No description provided for @invfColumnNumberLower.
  ///
  /// In pt, this message translates to:
  /// **'coluna {n}'**
  String invfColumnNumberLower(int n);

  /// No description provided for @invfFileValidation.
  ///
  /// In pt, this message translates to:
  /// **'Validação do ficheiro'**
  String get invfFileValidation;

  /// No description provided for @invfRequiredNote.
  ///
  /// In pt, this message translates to:
  /// **'Preciso, no mínimo, da data, da quantidade e do preço (ou do valor total).'**
  String get invfRequiredNote;

  /// No description provided for @invfQuantityOrComment.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade (ou o comentário que a traz)'**
  String get invfQuantityOrComment;

  /// No description provided for @invfPriceOrTotal.
  ///
  /// In pt, this message translates to:
  /// **'Preço ou Valor total'**
  String get invfPriceOrTotal;

  /// No description provided for @invfMissingColumn.
  ///
  /// In pt, this message translates to:
  /// **'Falta escolher a coluna: {name}'**
  String invfMissingColumn(String name);

  /// No description provided for @invfValidationSummary.
  ///
  /// In pt, this message translates to:
  /// **'{dataRows, plural, =0{0 linhas com dados} =1{1 linha com dados} other{{dataRows} linhas com dados}} · {recognized, plural, =0{0 operações reconhecidas} =1{1 operação reconhecida} other{{recognized} operações reconhecidas}}'**
  String invfValidationSummary(int dataRows, int recognized);

  /// No description provided for @invfWithProblems.
  ///
  /// In pt, this message translates to:
  /// **' · {count} com problemas'**
  String invfWithProblems(int count);

  /// No description provided for @invfIgnoredByUser.
  ///
  /// In pt, this message translates to:
  /// **' · {count} ignoradas (não são compras/vendas)'**
  String invfIgnoredByUser(int count);

  /// No description provided for @invfColumnValid.
  ///
  /// In pt, this message translates to:
  /// **'{label}: {ok} de {total} válidas'**
  String invfColumnValid(String label, int ok, int total);

  /// No description provided for @invfColumnValidNamed.
  ///
  /// In pt, this message translates to:
  /// **'{label} ({column}): {ok} de {total} válidas'**
  String invfColumnValidNamed(String label, String column, int ok, int total);

  /// No description provided for @invfUnknownTypes.
  ///
  /// In pt, this message translates to:
  /// **'Tipos que não reconheci'**
  String get invfUnknownTypes;

  /// No description provided for @invfUnknownTypesHint.
  ///
  /// In pt, this message translates to:
  /// **'Diz-me o que são para os importar (ou ignora).'**
  String get invfUnknownTypesHint;

  /// No description provided for @invfUnknownTypeRows.
  ///
  /// In pt, this message translates to:
  /// **'“{type}” · {count, plural, =0{{count} linhas} =1{1 linha} other{{count} linhas}}'**
  String invfUnknownTypeRows(String type, int count);

  /// No description provided for @invfEmpty.
  ///
  /// In pt, this message translates to:
  /// **'(vazio)'**
  String get invfEmpty;

  /// No description provided for @invfChoose.
  ///
  /// In pt, this message translates to:
  /// **'Escolher'**
  String get invfChoose;

  /// No description provided for @invfSkippedRows.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} linhas não importadas} =1{1 linha não importada} other{{count} linhas não importadas}}'**
  String invfSkippedRows(int count);

  /// No description provided for @invfRowReason.
  ///
  /// In pt, this message translates to:
  /// **'Linha {row}: {reason}'**
  String invfRowReason(int row, String reason);

  /// No description provided for @invfAndMore.
  ///
  /// In pt, this message translates to:
  /// **'… e mais {count}'**
  String invfAndMore(int count);

  /// No description provided for @invfAllRowsOk.
  ///
  /// In pt, this message translates to:
  /// **'Todas as linhas foram lidas sem problemas.'**
  String get invfAllRowsOk;

  /// No description provided for @invfImportedOps.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} operações importadas} =1{1 operação importada} other{{count} operações importadas}}'**
  String invfImportedOps(int count);

  /// No description provided for @invfImportedHoldings.
  ///
  /// In pt, this message translates to:
  /// **' e {count, plural, =0{{count} ativos criados} =1{1 ativo criado} other{{count} ativos criados}}'**
  String invfImportedHoldings(int count);

  /// No description provided for @invfUpdatePrices.
  ///
  /// In pt, this message translates to:
  /// **'. Atualiza os preços na Carteira.'**
  String get invfUpdatePrices;

  /// No description provided for @invfNegativeCashWarning.
  ///
  /// In pt, this message translates to:
  /// **' O dinheiro por alocar ficou negativo: associa as transferências do banco a esta plataforma ou acerta o dinheiro.'**
  String get invfNegativeCashWarning;

  /// No description provided for @invfFieldDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get invfFieldDate;

  /// No description provided for @invfFieldType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo (compra / venda)'**
  String get invfFieldType;

  /// No description provided for @invfFieldName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do ativo'**
  String get invfFieldName;

  /// No description provided for @invfFieldCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria (ETF, ação…)'**
  String get invfFieldCategory;

  /// No description provided for @invfFieldComment.
  ///
  /// In pt, this message translates to:
  /// **'Comentário (ex.: OPEN BUY 0.5 @ 100)'**
  String get invfFieldComment;

  /// No description provided for @invfFieldSymbol.
  ///
  /// In pt, this message translates to:
  /// **'Símbolo'**
  String get invfFieldSymbol;

  /// No description provided for @invfFieldIsin.
  ///
  /// In pt, this message translates to:
  /// **'ISIN'**
  String get invfFieldIsin;

  /// No description provided for @invfFieldQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get invfFieldQuantity;

  /// No description provided for @invfFieldPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço por unidade'**
  String get invfFieldPrice;

  /// No description provided for @invfFieldTotal.
  ///
  /// In pt, this message translates to:
  /// **'Valor total'**
  String get invfFieldTotal;

  /// No description provided for @invfFieldFee.
  ///
  /// In pt, this message translates to:
  /// **'Comissão'**
  String get invfFieldFee;

  /// No description provided for @invfFieldCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda'**
  String get invfFieldCurrency;

  /// No description provided for @invfFieldRate.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio (unidades da moeda por 1 da moeda de base)'**
  String get invfFieldRate;

  /// No description provided for @invfKindEtf.
  ///
  /// In pt, this message translates to:
  /// **'ETF'**
  String get invfKindEtf;

  /// No description provided for @invfKindStock.
  ///
  /// In pt, this message translates to:
  /// **'Ação'**
  String get invfKindStock;

  /// No description provided for @invfKindCrypto.
  ///
  /// In pt, this message translates to:
  /// **'Cripto'**
  String get invfKindCrypto;

  /// No description provided for @invfKindFund.
  ///
  /// In pt, this message translates to:
  /// **'Fundo'**
  String get invfKindFund;

  /// No description provided for @invfKindBond.
  ///
  /// In pt, this message translates to:
  /// **'Obrigação'**
  String get invfKindBond;

  /// No description provided for @invfKindOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get invfKindOther;

  /// No description provided for @morMoreTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get morMoreTitle;

  /// No description provided for @morBudgetSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Salário e limites por categoria'**
  String get morBudgetSubtitle;

  /// No description provided for @morPlanningSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Salário e despesas planeadas por mês'**
  String get morPlanningSubtitle;

  /// No description provided for @morGoalsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Poupar para férias, um carro…'**
  String get morGoalsSubtitle;

  /// No description provided for @morAnalysisSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Onde gastas e onde podes poupar'**
  String get morAnalysisSubtitle;

  /// No description provided for @morClassifyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Classificar movimentos'**
  String get morClassifyTitle;

  /// No description provided for @morClassifySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Um cartão por nome'**
  String get morClassifySubtitle;

  /// No description provided for @morUpdatesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações'**
  String get morUpdatesTitle;

  /// No description provided for @morUpdatesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Procurar e instalar uma versão nova'**
  String get morUpdatesSubtitle;

  /// No description provided for @morAppearanceSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Modo escuro e cores'**
  String get morAppearanceSubtitle;

  /// No description provided for @morAccountsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get morAccountsTitle;

  /// No description provided for @morAccountsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} contas} =1{1 conta} other{{count} contas}}'**
  String morAccountsCount(int count);

  /// No description provided for @morRecurringTitle.
  ///
  /// In pt, this message translates to:
  /// **'Movimentos recorrentes'**
  String get morRecurringTitle;

  /// No description provided for @morRecurringCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} recorrentes} =1{1 recorrente} other{{count} recorrentes}} · salário, renda, subscrições'**
  String morRecurringCount(int count);

  /// No description provided for @morCategoriesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Categorias e subcategorias'**
  String get morCategoriesTitle;

  /// No description provided for @morCategoriesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} categorias} =1{1 categoria} other{{count} categorias}}'**
  String morCategoriesCount(int count);

  /// No description provided for @morGroupsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Grupos de títulos'**
  String get morGroupsTitle;

  /// No description provided for @morGroupsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} grupos} =1{1 grupo} other{{count} grupos}}'**
  String morGroupsCount(int count);

  /// No description provided for @morRulesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Regras memorizadas'**
  String get morRulesTitle;

  /// No description provided for @morRulesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} regras} =1{1 regra} other{{count} regras}}'**
  String morRulesCount(int count);

  /// No description provided for @morImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar extrato'**
  String get morImportTitle;

  /// No description provided for @morImportSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'PDF, CSV ou Excel'**
  String get morImportSubtitle;

  /// No description provided for @morImportsHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de importações'**
  String get morImportsHistoryTitle;

  /// No description provided for @morExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exportar movimentos (CSV)'**
  String get morExportTitle;

  /// No description provided for @morBackupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cópia de segurança'**
  String get morBackupTitle;

  /// No description provided for @morBackupSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Guardar ou restaurar no Google Drive ou num ficheiro'**
  String get morBackupSubtitle;

  /// No description provided for @morWipeTransactionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar todos os movimentos'**
  String get morWipeTransactionsTitle;

  /// No description provided for @morWipeTransactionsConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Apagar TODOS os movimentos, regras e salários? As categorias mantêm-se. Não é possível desfazer.'**
  String get morWipeTransactionsConfirm;

  /// No description provided for @morWipeAllTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar tudo, incluindo categorias'**
  String get morWipeAllTitle;

  /// No description provided for @morWipeAllConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Apagar TUDO: movimentos, categorias, orçamentos, regras, salários e investimentos? Não é possível desfazer.'**
  String get morWipeAllConfirm;

  /// No description provided for @morPrivacyNote.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados ficam guardados apenas neste telemóvel. A internet só é usada se carregares em “Atualizar preços” na Carteira (é enviado apenas o símbolo do ativo).'**
  String get morPrivacyNote;

  /// No description provided for @morImportsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importações'**
  String get morImportsTitle;

  /// No description provided for @morNoImports.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem importações.'**
  String get morNoImports;

  /// No description provided for @morUndoImport.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer importação'**
  String get morUndoImport;

  /// No description provided for @morImportItemSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{date} · {count} movimentos} =1{{date} · 1 movimento} other{{date} · {count} movimentos}}'**
  String morImportItemSubtitle(int count, String date);

  /// No description provided for @morRemoveImportQuestion.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Remover os {count} movimentos desta importação?} =1{Remover o movimento desta importação?} other{Remover os {count} movimentos desta importação?}}'**
  String morRemoveImportQuestion(int count);

  /// No description provided for @morCategoriesScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get morCategoriesScreenTitle;

  /// No description provided for @morNewCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get morNewCategory;

  /// No description provided for @morIncomeKind.
  ///
  /// In pt, this message translates to:
  /// **'Rendimento'**
  String get morIncomeKind;

  /// No description provided for @morInvestmentKind.
  ///
  /// In pt, this message translates to:
  /// **'Investimento'**
  String get morInvestmentKind;

  /// No description provided for @morBothKinds.
  ///
  /// In pt, this message translates to:
  /// **'Despesas e receitas'**
  String get morBothKinds;

  /// No description provided for @morFromStart.
  ///
  /// In pt, this message translates to:
  /// **'desde sempre'**
  String get morFromStart;

  /// No description provided for @morFromMonth.
  ///
  /// In pt, this message translates to:
  /// **'de {month}'**
  String morFromMonth(String month);

  /// No description provided for @morOpenEnded.
  ///
  /// In pt, this message translates to:
  /// **'em diante'**
  String get morOpenEnded;

  /// No description provided for @morToMonth.
  ///
  /// In pt, this message translates to:
  /// **'a {month}'**
  String morToMonth(String month);

  /// No description provided for @morEnded.
  ///
  /// In pt, this message translates to:
  /// **'terminada'**
  String get morEnded;

  /// No description provided for @morFuture.
  ///
  /// In pt, this message translates to:
  /// **'futura'**
  String get morFuture;

  /// No description provided for @morTxnCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} mov.} =1{1 mov.} other{{count} mov.}}'**
  String morTxnCount(int count);

  /// No description provided for @morMandatoryPeriods.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatória em {count} período(s)'**
  String morMandatoryPeriods(int count);

  /// No description provided for @morNewSubcategory.
  ///
  /// In pt, this message translates to:
  /// **'Nova subcategoria'**
  String get morNewSubcategory;

  /// No description provided for @morDuplicateNextYear.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar para o ano seguinte'**
  String get morDuplicateNextYear;

  /// No description provided for @morReactivate.
  ///
  /// In pt, this message translates to:
  /// **'Reativar'**
  String get morReactivate;

  /// No description provided for @morArchive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get morArchive;

  /// No description provided for @morCreatedCategory.
  ///
  /// In pt, this message translates to:
  /// **'Criada “{name}”.'**
  String morCreatedCategory(String name);

  /// No description provided for @morDeleteCategoryQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Apagar “{name}”? {count, plural, =0{Os {count} movimentos ficam} =1{O movimento fica} other{Os {count} movimentos ficam}} sem categoria{subs}.'**
  String morDeleteCategoryQuestion(String name, int count, String subs);

  /// No description provided for @morSubcategoriesDeleted.
  ///
  /// In pt, this message translates to:
  /// **' e as subcategorias são apagadas'**
  String get morSubcategoriesDeleted;

  /// No description provided for @morThemeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get morThemeTitle;

  /// No description provided for @morThemeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get morThemeSystem;

  /// No description provided for @morThemeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get morThemeLight;

  /// No description provided for @morThemeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get morThemeDark;

  /// No description provided for @morAmoledTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preto total (AMOLED)'**
  String get morAmoledTitle;

  /// No description provided for @morAmoledSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'No modo escuro, fundo totalmente preto'**
  String get morAmoledSubtitle;

  /// No description provided for @morBaseCurrencyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Moeda de base'**
  String get morBaseCurrencyTitle;

  /// No description provided for @morBaseCurrencyHint.
  ///
  /// In pt, this message translates to:
  /// **'É a moeda dos teus movimentos, orçamentos e carteira. Os ativos noutras moedas (USD, GBP…) são convertidos para esta.'**
  String get morBaseCurrencyHint;

  /// No description provided for @morBaseCurrencyChanged.
  ///
  /// In pt, this message translates to:
  /// **'Moeda de base: {code}. Os valores já registados não são convertidos; atualiza os preços da Carteira.'**
  String morBaseCurrencyChanged(String code);

  /// No description provided for @morMainColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor principal'**
  String get morMainColor;

  /// No description provided for @morMainColorHint.
  ///
  /// In pt, this message translates to:
  /// **'Define a cor da barra de navegação, botões e gráficos.'**
  String get morMainColorHint;

  /// No description provided for @morIncomeColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor das receitas'**
  String get morIncomeColor;

  /// No description provided for @morExpenseColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor das despesas'**
  String get morExpenseColor;

  /// No description provided for @morPreview.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização'**
  String get morPreview;

  /// No description provided for @morSamplePlace.
  ///
  /// In pt, this message translates to:
  /// **'Supermercado'**
  String get morSamplePlace;

  /// No description provided for @morSampleCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria › Subcategoria'**
  String get morSampleCategory;

  /// No description provided for @morSampleSalary.
  ///
  /// In pt, this message translates to:
  /// **'Salário'**
  String get morSampleSalary;

  /// No description provided for @morResetAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Repor aparência original'**
  String get morResetAppearance;

  /// No description provided for @morEmojiHint.
  ///
  /// In pt, this message translates to:
  /// **'Cada categoria e subcategoria tem um emoji próprio, que escolhes ao criar ou editar.'**
  String get morEmojiHint;

  /// No description provided for @morBackupDescription.
  ///
  /// In pt, this message translates to:
  /// **'Guarda todos os teus dados (movimentos, categorias, orçamentos, carteira…) num ficheiro. Não inclui as fotos dos recibos.'**
  String get morBackupDescription;

  /// No description provided for @morBackupDriveHint.
  ///
  /// In pt, this message translates to:
  /// **'Não precisas de ligar nenhuma conta na app: ao guardar, escolhe “Google Drive” (ou outra pasta) no ecrã do Android. Para restaurar, escolhe o ficheiro, do telemóvel ou do Drive.'**
  String get morBackupDriveHint;

  /// No description provided for @morLastBackup.
  ///
  /// In pt, this message translates to:
  /// **'Última cópia guardada: {date} ({ago})'**
  String morLastBackup(String date, String ago);

  /// No description provided for @morSaveBackup.
  ///
  /// In pt, this message translates to:
  /// **'Guardar cópia (Google Drive ou ficheiro)'**
  String get morSaveBackup;

  /// No description provided for @morRestoreFromFile.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar de um ficheiro'**
  String get morRestoreFromFile;

  /// No description provided for @morBackupSaved.
  ///
  /// In pt, this message translates to:
  /// **'Cópia guardada.'**
  String get morBackupSaved;

  /// No description provided for @morDataRestored.
  ///
  /// In pt, this message translates to:
  /// **'Dados restaurados.'**
  String get morDataRestored;

  /// No description provided for @morRestoreConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Isto substitui TODOS os dados deste telemóvel pelos da cópia “{name}”. Não dá para desfazer. Continuar?'**
  String morRestoreConfirm(String name);

  /// No description provided for @morRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get morRestore;

  /// No description provided for @morCouldNotFinish.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui concluir: {error}'**
  String morCouldNotFinish(String error);

  /// No description provided for @morInstalledVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão instalada'**
  String get morInstalledVersion;

  /// No description provided for @morUpdateDescription.
  ///
  /// In pt, this message translates to:
  /// **'Procura no GitHub se há uma versão nova e instala-a por cima desta, sem perderes dados. A internet só é usada quando carregas no botão.'**
  String get morUpdateDescription;

  /// No description provided for @morChecking.
  ///
  /// In pt, this message translates to:
  /// **'A procurar…'**
  String get morChecking;

  /// No description provided for @updPopupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Há uma versão nova'**
  String get updPopupTitle;

  /// No description provided for @updPopupBody.
  ///
  /// In pt, this message translates to:
  /// **'A versão {tag} já está disponível. Queres atualizar agora?'**
  String updPopupBody(String tag);

  /// No description provided for @updPopupLater.
  ///
  /// In pt, this message translates to:
  /// **'Mais tarde'**
  String get updPopupLater;

  /// No description provided for @updPopupNow.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get updPopupNow;

  /// No description provided for @morCheckUpdates.
  ///
  /// In pt, this message translates to:
  /// **'Procurar atualizações'**
  String get morCheckUpdates;

  /// No description provided for @morNewVersion.
  ///
  /// In pt, this message translates to:
  /// **'Há uma versão nova: {version}'**
  String morNewVersion(String version);

  /// No description provided for @morUpToDate.
  ///
  /// In pt, this message translates to:
  /// **'Já tens a versão mais recente'**
  String get morUpToDate;

  /// No description provided for @morDownloadInstall.
  ///
  /// In pt, this message translates to:
  /// **'Descarregar e instalar'**
  String get morDownloadInstall;

  /// No description provided for @morDownloadInstallSize.
  ///
  /// In pt, this message translates to:
  /// **'Descarregar e instalar ({mb} MB)'**
  String morDownloadInstallSize(String mb);

  /// No description provided for @morDownloadingPercent.
  ///
  /// In pt, this message translates to:
  /// **'A descarregar… {percent}%'**
  String morDownloadingPercent(String percent);

  /// No description provided for @morDownloading.
  ///
  /// In pt, this message translates to:
  /// **'A descarregar…'**
  String get morDownloading;

  /// No description provided for @morOpenReleasePage.
  ///
  /// In pt, this message translates to:
  /// **'Abrir a página da versão'**
  String get morOpenReleasePage;

  /// No description provided for @morWhatsNew.
  ///
  /// In pt, this message translates to:
  /// **'O que mudou'**
  String get morWhatsNew;

  /// No description provided for @morInstallerError.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui abrir o instalador ({message}). Se o Android pediu permissão para instalar apps desta origem, ativa-a e carrega outra vez em \"Descarregar e instalar\".'**
  String morInstallerError(String message);

  /// No description provided for @morUpdateAvailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualização disponível'**
  String get morUpdateAvailableTitle;

  /// No description provided for @morUpdateAvailableBody.
  ///
  /// In pt, this message translates to:
  /// **'Finanças {version} já está disponível. Abre Mais › Atualizações para instalar.'**
  String morUpdateAvailableBody(String version);

  /// No description provided for @morUpdateChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações'**
  String get morUpdateChannelName;

  /// No description provided for @morUpdateChannelDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aviso quando sai uma versão nova'**
  String get morUpdateChannelDescription;

  /// No description provided for @morRecurringNotifBody.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{{count} movimentos recorrentes registados} =1{1 movimento recorrente registado} other{{count} movimentos recorrentes registados}}'**
  String morRecurringNotifBody(int count);

  /// No description provided for @morAllocationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrega de investimento'**
  String get morAllocationTitle;

  /// No description provided for @morAllocationBody.
  ///
  /// In pt, this message translates to:
  /// **'{account}{deliveries}: {details}'**
  String morAllocationBody(String account, String deliveries, String details);

  /// No description provided for @morDeliveriesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{({count} entregas)} =1{(1 entrega)} other{({count} entregas)}}'**
  String morDeliveriesCount(int count);

  /// No description provided for @morUndistributed.
  ///
  /// In pt, this message translates to:
  /// **'{amount} por distribuir'**
  String morUndistributed(String amount);

  /// No description provided for @morAlertsChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get morAlertsChannelName;

  /// No description provided for @morAlertsChannelDescription.
  ///
  /// In pt, this message translates to:
  /// **'Movimentos recorrentes e entregas de investimento'**
  String get morAlertsChannelDescription;

  /// No description provided for @morAssetFallback.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get morAssetFallback;

  /// No description provided for @morNavMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get morNavMonth;

  /// No description provided for @morNavPortfolio.
  ///
  /// In pt, this message translates to:
  /// **'Carteira'**
  String get morNavPortfolio;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
