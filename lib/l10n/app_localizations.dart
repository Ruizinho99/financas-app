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
