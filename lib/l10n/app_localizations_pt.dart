// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Finanças';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Automático';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get monthPrevious => 'Mês anterior';

  @override
  String get monthNext => 'Mês seguinte';

  @override
  String get pickDayOfMonth => 'Escolhe um dia do mês';

  @override
  String get transaction => 'Movimento';

  @override
  String get transactions => 'Movimentos';

  @override
  String get startHere => 'Começa por aqui';

  @override
  String get monthAppearsHint => 'O mês aparece assim que tiveres movimentos';

  @override
  String get importStatement => 'Importar um extrato';

  @override
  String get addTransaction => 'Adicionar um movimento';

  @override
  String get spent => 'Gasto';

  @override
  String canStillSpend(String amount) {
    return 'Ainda podes gastar $amount';
  }

  @override
  String dailyAverage(String amount) {
    return 'Média de $amount por dia';
  }

  @override
  String get income => 'Receitas';

  @override
  String get saved => 'Poupado';

  @override
  String get sentToInvest => 'Enviado para investir';

  @override
  String get whereSpendMost => 'Onde gastas mais';

  @override
  String get seeAnalysis => 'Ver análise';

  @override
  String get classifyHint =>
      'Um cartão por nome; memoriza para as próximas vezes';

  @override
  String get budget => 'Orçamento';

  @override
  String get analysis => 'Análise';

  @override
  String get backToThisMonth => 'Voltar a este mês';

  @override
  String get goals => 'Objetivos';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get deliveriesToDistribute => 'Entregas para distribuir';

  @override
  String get distribute => 'Distribuir';

  @override
  String get deliveriesHint =>
      'Entregas do banco que ainda não repartiste pelos ativos.';

  @override
  String get planning => 'Planeamento';

  @override
  String get seePlan => 'Ver plano';

  @override
  String get planned => 'Planeado';

  @override
  String get actualSpent => 'Gasto real';

  @override
  String leftAfterPlan(String amount) {
    return 'Sobra do salário, depois do plano: $amount';
  }

  @override
  String get reached => 'Atingido';

  @override
  String missingAmount(String amount) {
    return 'Faltam $amount';
  }

  @override
  String get categorize => 'Categorizar';

  @override
  String get delete => 'Apagar';

  @override
  String deleteTransactionsQuestion(int count) {
    return 'Apagar $count movimentos?';
  }

  @override
  String selectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get search => 'Pesquisar…';

  @override
  String get noCategory => 'Sem categoria';

  @override
  String get allAccounts => 'Todas as contas';

  @override
  String get accountFallback => 'Conta';

  @override
  String get allMonths => 'Todos os meses';

  @override
  String get noTransactionsHint =>
      'Sem movimentos.\nImporta um extrato (ícone no topo) ou adiciona manualmente.';

  @override
  String reversalDeleted(String amount) {
    return 'Anula uma despesa já apagada ($amount)';
  }

  @override
  String reversalOf(String name, String amount) {
    return 'Anula $name ($amount)';
  }

  @override
  String reversedLeft(String done, String left) {
    return 'Anulado $done · fica $left';
  }

  @override
  String get goalFallback => 'Objetivo';

  @override
  String goalsSplit(String parts) {
    return 'Objetivos: $parts';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get monthStartTitle => 'Início do mês';

  @override
  String get monthStartSubtitle => 'Dia fixo ou o dia do salário';

  @override
  String get monthModeCalendar => 'Calendário';

  @override
  String get monthModeFixed => 'Dia fixo';

  @override
  String get monthModeSalary => 'Salário';

  @override
  String get monthStartDayLabel => 'Dia em que o mês começa';

  @override
  String get monthNamedByEnd =>
      'O mês tem o nome do mês em que termina: 25 ago – 24 set é setembro.';

  @override
  String get monthCalendarHint =>
      'O mês vai do dia 1 ao último dia, como no calendário.';

  @override
  String get salaryCategoryLabel => 'Categoria do salário';

  @override
  String get salaryCategoryChoose => 'Escolher categoria';

  @override
  String get salaryCategoryHint =>
      'O mês começa no dia em que entra um movimento positivo nesta categoria.';

  @override
  String salaryDatesFound(int count) {
    return 'Salários encontrados: $count';
  }

  @override
  String get salaryNoneFound =>
      'Ainda sem salários nesta categoria. Até lá, o mês é o do calendário.';

  @override
  String thisMonthIs(String range) {
    return 'Este mês: $range';
  }

  @override
  String dayOfMonthItem(int day) {
    return 'Dia $day';
  }
}
