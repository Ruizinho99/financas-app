// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get anCompareOn => 'A comparar com o período anterior';

  @override
  String get anCompareOff => 'Comparar com o período anterior';

  @override
  String get anModeMonth => 'Mês';

  @override
  String get anModeYear => 'Ano';

  @override
  String get anModeYtd => 'YTD';

  @override
  String get anModeCustom => 'Custom';

  @override
  String anYtdLabel(String year) {
    return 'YTD $year · 1 jan – hoje';
  }

  @override
  String get anPickRange => 'Escolhe o intervalo';

  @override
  String get anApply => 'Aplicar';

  @override
  String get anTabOverview => 'Visão geral';

  @override
  String get anTabSpend => 'Gastos';

  @override
  String get anTabSave => 'Poupar';

  @override
  String get anTabTrend => 'Evolução';

  @override
  String get anNoDataPeriod =>
      'Sem movimentos neste período (ou os filtros não encontram nada).';

  @override
  String get anExpenses => 'Despesas';

  @override
  String anSamePeriodPrev(String amount) {
    return 'Mesmos dias do período anterior: $amount';
  }

  @override
  String anPrevPeriodAmount(String amount) {
    return 'Período anterior: $amount';
  }

  @override
  String get anPrevPeriod => 'Período anterior';

  @override
  String anOngoingToday(int day) {
    return 'Período em curso: valores até hoje (dia $day).';
  }

  @override
  String get anIncomes => 'Rendimentos';

  @override
  String get anBalance => 'Saldo';

  @override
  String get anInvested => 'Investido';

  @override
  String anOfIncome(String percent) {
    return '$percent dos rendimentos';
  }

  @override
  String get anSavingsRate => 'Taxa de poupança';

  @override
  String anPpVsPrev(String sign, int pp) {
    return '$sign$pp pp vs anterior';
  }

  @override
  String get anIncomeExpected =>
      'Rendimento esperado: salário líquido definido no Orçamento.';

  @override
  String get anIncomeFromSalary =>
      'Sem rendimentos categorizados: a usar o salário líquido definido no Orçamento.';

  @override
  String get anRateOngoing =>
      'Período em curso: a taxa de poupança vai mudando até ao fim.';

  @override
  String get anRateExcellent =>
      'Estás a poupar mais de 20% do que ganhas. Excelente.';

  @override
  String anRateOk(String percent) {
    return 'Poupas $percent. Uma boa meta é 20%.';
  }

  @override
  String get anRateNegative =>
      'Estás a gastar mais do que ganhas neste período.';

  @override
  String get anPace => 'Ritmo de gastos';

  @override
  String get anAvgPerDay => 'Média por dia';

  @override
  String get anAvgValue => 'Valor médio';

  @override
  String anDayOf(int day, int total) {
    return 'Dia $day de $total';
  }

  @override
  String anOfMonth(String percent) {
    return '$percent do mês';
  }

  @override
  String anOfSpending(String percent) {
    return '$percent das despesas';
  }

  @override
  String anProjected(String amount) {
    return 'Ao ritmo atual, o mês fecha em $amount';
  }

  @override
  String anPrevMonthSpent(String amount) {
    return 'No mês anterior gastaste $amount.';
  }

  @override
  String anAboveBudget(String amount, String budget) {
    return 'Isso são $amount acima do orçamento de $budget.';
  }

  @override
  String anWithinBudget(String budget, String margin) {
    return 'Dentro do orçamento de $budget, com folga de $margin.';
  }

  @override
  String get anMandVsOpt => 'Obrigatórias vs opcionais';

  @override
  String get anMandVsOptSub =>
      'O que tens de pagar vs onde tens margem para poupar';

  @override
  String get anMandatory => 'Obrigatórias';

  @override
  String get anOptional => 'Opcionais';

  @override
  String get anNoCategory => 'Sem categoria';

  @override
  String get anTotal => 'Total';

  @override
  String get anNoSpendPeriod => 'Sem despesas neste período.';

  @override
  String anPctOfIncome(String mand, String opt, String left) {
    return 'Em % dos rendimentos: obrigatórias $mand, opcionais $opt, sobra $left.';
  }

  @override
  String get anBudgetSub => 'Limites e objetivos definidos';

  @override
  String get anBudgetSubFiltered =>
      'Limites e objetivos definidos (não depende dos filtros)';

  @override
  String get anGoalReached => 'Objetivo atingido 🎉';

  @override
  String anGoalLeft(String amount, String percent) {
    return 'Faltam $amount para o objetivo ($percent)';
  }

  @override
  String anOverLimit(String amount) {
    return 'Excedeste o limite em $amount';
  }

  @override
  String anNearLimit(String amount) {
    return 'Perto do limite: restam $amount';
  }

  @override
  String anLeftUsed(String amount, String percent) {
    return 'Restam $amount ($percent usado)';
  }

  @override
  String get anWhereSave => 'Onde posso poupar?';

  @override
  String anFoundUpTo(String amount) {
    return 'Encontrámos até $amount por mês de margem.';
  }

  @override
  String get anNoSpendPeriodFilter =>
      'Sem despesas neste período (ou os filtros não encontram nada).';

  @override
  String get anCategories => 'Categorias';

  @override
  String get anSubcategories => 'Subcategorias';

  @override
  String get anMerchants => 'Comerciantes';

  @override
  String get anAccounts => 'Contas';

  @override
  String get anWhereMoneyGoes => 'Para onde vai o dinheiro';

  @override
  String get anSubDetail => 'Detalhe por subcategoria';

  @override
  String get anWhereMostSpend => 'Onde mais gastas';

  @override
  String get anSpendByAccount => 'Gastos por conta';

  @override
  String get anTapRowHint => 'Toca numa linha para ver os movimentos';

  @override
  String get anOthers => 'Outros';

  @override
  String get anShowLess => 'Mostrar menos';

  @override
  String anSeeAllCount(int count) {
    return 'Ver todos ($count)';
  }

  @override
  String get anWdMon => 'Seg';

  @override
  String get anWdTue => 'Ter';

  @override
  String get anWdWed => 'Qua';

  @override
  String get anWdThu => 'Qui';

  @override
  String get anWdFri => 'Sex';

  @override
  String get anWdSat => 'Sáb';

  @override
  String get anWdSun => 'Dom';

  @override
  String get anDayMon => 'à segunda';

  @override
  String get anDayTue => 'à terça';

  @override
  String get anDayWed => 'à quarta';

  @override
  String get anDayThu => 'à quinta';

  @override
  String get anDayFri => 'à sexta';

  @override
  String get anDaySat => 'ao sábado';

  @override
  String get anDaySun => 'ao domingo';

  @override
  String anSpendMostOn(String day, String amount, int count) {
    return 'Gastas mais $day: $amount em $count movimentos';
  }

  @override
  String get anWhichDays => 'Em que dias gastas mais';

  @override
  String get anLargestSpends => 'Maiores despesas';

  @override
  String get anLargestSub => 'As que mais pesaram neste período';

  @override
  String get anMonthByMonth => 'Mês a mês';

  @override
  String anTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return '$_temp0';
  }

  @override
  String get anWhereFrom => 'De onde vem';

  @override
  String get anPerMonthCap => 'Por mês';

  @override
  String anGeneralCat(String name) {
    return '$name (geral)';
  }

  @override
  String get anAnalyseOnly => 'Analisar só esta';

  @override
  String anAndMore(int count) {
    return '… e mais $count';
  }

  @override
  String get anNoAccount => 'Sem conta';

  @override
  String get anNotEnoughTrend =>
      'Ainda não há dados suficientes para mostrar a evolução.';

  @override
  String anLastMonths(int count, String avg) {
    return 'Últimos $count meses · a linha tracejada é a média ($avg)';
  }

  @override
  String get anSpendByMonth => 'Despesas por mês';

  @override
  String anBestMonth(String month) {
    return 'Melhor mês: $month';
  }

  @override
  String anBestMonthBody(String amount, String diff) {
    return 'Gastaste $amount, $diff abaixo da média.';
  }

  @override
  String anWorstMonth(String month) {
    return 'Mês mais caro: $month';
  }

  @override
  String anWorstMonthBody(String amount, String diff) {
    return 'Gastaste $amount, $diff acima da média.';
  }

  @override
  String get anIncomeVsSpend => 'Rendimentos vs despesas';

  @override
  String get anIncomeVsSpendSub =>
      'Se a linha das despesas passa a dos rendimentos, estás a gastar mais do que ganhas';

  @override
  String get anMonth => 'Mês';

  @override
  String get anSavingsShort => 'Poup.';

  @override
  String get anTrendByCategory => 'Evolução por categoria';

  @override
  String get anPickCategoryHint => 'Escolhe uma categoria para a ver mês a mês';

  @override
  String get anChooseCategory => 'Escolher categoria';

  @override
  String get anNone => '— nenhuma —';

  @override
  String anAvgMonthsWithSpend(String amount) {
    return 'Média nos meses com gasto: $amount.';
  }

  @override
  String get anNoSpendToAnalyse => 'Sem despesas neste período para analisar.';

  @override
  String get anSavingPotential => 'Potencial de poupança';

  @override
  String get anPerMonth => 'por mês';

  @override
  String anUpToYear(String amount) {
    return 'Isso são até $amount por ano, só com as sugestões abaixo.';
  }

  @override
  String get anNoObviousMargins =>
      'Neste período não encontrámos margens óbvias. Experimenta outro intervalo ou o simulador.';

  @override
  String get anWhatIfCut => 'E se cortasse nas opcionais?';

  @override
  String anOptionalThisPeriod(String amount) {
    return 'Despesas opcionais neste período: $amount';
  }

  @override
  String get anCut => 'Cortar';

  @override
  String get anSaveMonthly => 'Poupas por mês';

  @override
  String get anSaveYearly => 'Poupas por ano';

  @override
  String get anSuggestions => 'Sugestões';

  @override
  String get anSuggestionsSub => 'Ordenadas pelo que mais poupa';

  @override
  String get anRecurringPayments => 'Pagamentos recorrentes';

  @override
  String anRecOptional(String monthly, String yearly) {
    return 'Opcionais: $monthly/mês ($yearly/ano)';
  }

  @override
  String anRecMandatory(String monthly) {
    return 'Obrigatórios: $monthly/mês';
  }

  @override
  String anMonthsLast(int count, String date) {
    return '$count meses · último $date';
  }

  @override
  String anAmountPerMonth(String amount) {
    return '$amount/mês';
  }

  @override
  String anAmountPerYear(String amount) {
    return '$amount/ano';
  }

  @override
  String get anCancelAdvice =>
      'Cancelar o que já não usas é a forma mais fácil de poupar.';

  @override
  String get anFrequentSmall => 'Pequenas compras frequentes';

  @override
  String get anSmallSub => 'Compras de baixo valor que se repetem muito';

  @override
  String anPurchasesAvg(int count, String avg) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compras',
      one: '1 compra',
      zero: '$count compras',
    );
    return '$_temp0 · média $avg';
  }

  @override
  String get anMandatoryTag => 'obrigatória';

  @override
  String get anOptionalTag => 'opcional';

  @override
  String get anTypeAll => 'Todas';

  @override
  String get anCategory => 'Categoria';

  @override
  String anCategoriesCount(int count) {
    return '$count categorias';
  }

  @override
  String get anAccount => 'Conta';

  @override
  String anAccountsCount(int count) {
    return '$count contas';
  }

  @override
  String get anFilters => 'Filtros';

  @override
  String get anClearAll => 'Limpar tudo';

  @override
  String get anClear => 'Limpar';

  @override
  String get anExpenseType => 'Tipo de despesa';

  @override
  String get anSearch => 'Pesquisar';

  @override
  String get anSearchHint => 'Nome, nota, categoria…';

  @override
  String get anTxAmount => 'Valor do movimento';

  @override
  String anMinAmount(String sym) {
    return 'Mínimo ($sym)';
  }

  @override
  String anMaxAmount(String sym) {
    return 'Máximo ($sym)';
  }

  @override
  String get anNoCategoriesYet => 'Ainda não há categorias.';

  @override
  String get anApplyFilters => 'Aplicar filtros';

  @override
  String get anStable => 'estável';

  @override
  String get anNew => 'novo';

  @override
  String anUpToPerMonth(String amount) {
    return 'até $amount/mês';
  }

  @override
  String anOverLimitTitle(String name) {
    return '$name acima do limite';
  }

  @override
  String anOverLimitDetail(String spent, String target) {
    return 'Gastaste $spent para um limite de $target.';
  }

  @override
  String anIncreaseTitle(String name, String percent) {
    return '$name subiu $percent';
  }

  @override
  String anIncreaseDetail(String delta, String prev, String cur) {
    return 'Mais $delta do que no período anterior ($prev → $cur).';
  }

  @override
  String anTopOptionalTitle(String name, String percent) {
    return '$name: $percent das despesas';
  }

  @override
  String anTopOptionalDetail(String amount) {
    return 'É uma despesa opcional. Cortar 10% poupava $amount por mês.';
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
      other: '$count compras',
      one: '1 compra',
      zero: '$count compras',
    );
    String _temp1 = intl.Intl.pluralLogic(
      places,
      locale: localeName,
      other: '$places sítios',
      one: '1 sítio',
      zero: '$places sítios',
    );
    return '$_temp0 em $_temp1 somam $total ($examples). Reduzir um terço poupava $saving por mês.';
  }

  @override
  String anRecurringTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagamentos recorrentes opcionais',
      one: '1 pagamento recorrente opcional',
      zero: '$count pagamentos recorrentes opcionais',
    );
    return '$_temp0';
  }

  @override
  String anRecurringDetail(String monthly, String yearly) {
    return 'Somam $monthly por mês ($yearly por ano). Vê se ainda precisas de todos.';
  }

  @override
  String get anUnclassifiedSpend => 'Despesas sem categoria';

  @override
  String anUnclassifiedDetail(String amount) {
    return '$amount por classificar. Quanto mais classificado, mais certeiras são as sugestões.';
  }

  @override
  String get bpCopySalaryTooltip => 'Copiar salário para todos os meses';

  @override
  String get bpNetSalary => 'Salário líquido';

  @override
  String get bpSet => 'Definir';

  @override
  String get bpSpecificThisMonth => 'Valor específico deste mês';

  @override
  String bpAllocatedSummary(String amount, String percent) {
    return 'Alocado $amount ($percent)';
  }

  @override
  String bpUnallocatedLeft(String amount) {
    return 'Por alocar $amount';
  }

  @override
  String bpOverAllocated(String amount) {
    return 'Excedido em $amount';
  }

  @override
  String bpIncomeThisMonth(String amount) {
    return 'Rendimentos recebidos este mês: $amount';
  }

  @override
  String get bpDefineSalaryHint =>
      'Define o teu salário líquido para distribuir por categorias.';

  @override
  String get bpNoCategoriesBudget =>
      'Ainda não tens categorias. Cria a primeira abaixo (ex.: Habitação) e define o orçamento de cada uma.';

  @override
  String get bpCategories => 'Categorias';

  @override
  String get bpNewCategory => 'Nova categoria';

  @override
  String get bpBudgetLimit => 'Limite';

  @override
  String get bpBudgetGoal => 'Objetivo';

  @override
  String bpSpentOfTarget(String spent, String target, String type) {
    return '$spent de $target · $type';
  }

  @override
  String bpSpentNoBudget(String spent) {
    return 'Gasto: $spent · sem orçamento';
  }

  @override
  String bpSpentSetBudget(String spent) {
    return 'Gasto: $spent · definir orçamento';
  }

  @override
  String bpMandatoryInMonth(String month) {
    return 'Obrigatória em $month';
  }

  @override
  String get bpInheritedFromParent => 'Herdada da categoria-mãe';

  @override
  String get bpOnlyThisMonthHint =>
      'Só este mês; para vários meses usa “Períodos”';

  @override
  String get bpCategoryBudgetOptional => 'Orçamento da categoria (opcional)';

  @override
  String get bpSumOfSubcategories => 'Soma das subcategorias';

  @override
  String bpBudgetDescPercent(String type, String percent, String amount) {
    return '$type: $percent% do salário ($amount)';
  }

  @override
  String bpBudgetDescValue(String type, String amount) {
    return '$type: $amount';
  }

  @override
  String get bpSubcategory => 'Subcategoria';

  @override
  String get bpPeriods => 'Períodos';

  @override
  String get bpEdit => 'Editar';

  @override
  String bpBudgetEditorTitle(String name) {
    return 'Orçamento · $name';
  }

  @override
  String get bpHasBudget => 'Ter orçamento';

  @override
  String get bpLimitHint => 'Limite: queres gastar no máximo este valor.';

  @override
  String get bpGoalHint =>
      'Objetivo: queres atingir pelo menos este valor (ex.: poupança).';

  @override
  String bpValueWithCurrency(String currency) {
    return 'Valor ($currency)';
  }

  @override
  String get bpPercentOfSalary => '% do salário';

  @override
  String get bpMonthlyAmount => 'Valor mensal';

  @override
  String get bpPercentage => 'Percentagem';

  @override
  String get bpSave => 'Guardar';

  @override
  String get bpNetSalaryMonthly => 'Salário líquido mensal';

  @override
  String get bpOnlyThisMonth => 'Só para este mês';

  @override
  String get bpSalaryDefaultHint =>
      'Desligado: passa a ser o valor por omissão de todos os meses';

  @override
  String get bpUseBaseSalary => 'Usar valor base';

  @override
  String get bpCopyPreviousPlan => 'Copiar o plano do mês anterior';

  @override
  String bpCopiedPlanItems(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copiadas $count despesas de $month.',
      one: 'Copiada 1 despesa de $month.',
      zero: 'Copiadas $count despesas de $month.',
    );
    return '$_temp0';
  }

  @override
  String get bpMandatoryPlanned => 'Obrigatórias planeadas';

  @override
  String get bpOptionalPlanned => 'Opcionais planeadas';

  @override
  String get bpExceedsSalaryBy => 'Excede o salário em';

  @override
  String get bpUnplanned => 'Por planear';

  @override
  String get bpSetMonthSalaryHint =>
      'Define o salário deste mês para ver o que sobra.';

  @override
  String get bpNoPlanCopyHint =>
      'Ainda sem despesas planeadas. Usa o ícone de copiar para trazer o plano do mês anterior.';

  @override
  String get bpNoPlanHint =>
      'Ainda sem despesas planeadas. Acrescenta as obrigatórias (renda, luz…) e as opcionais (lazer, subscrições…).';

  @override
  String get bpMandatoryItems => 'Obrigatórias';

  @override
  String get bpOptionalItems => 'Opcionais';

  @override
  String get bpPlannedExpense => 'Despesa planeada';

  @override
  String get bpCategoryAlreadyPlannedEdit =>
      'Esta categoria já está planeada neste mês. Edita a linha existente.';

  @override
  String get bpCategoryAlreadyPlanned =>
      'Esta categoria já está planeada neste mês.';

  @override
  String bpSpentOver(String spent, String over) {
    return 'Gasto $spent · passou $over';
  }

  @override
  String bpSpentLeft(String spent, String left) {
    return 'Gasto $spent · faltam $left';
  }

  @override
  String bpPlannedAmount(String currency) {
    return 'Valor planeado ($currency)';
  }

  @override
  String get bpMandatoryType => 'Obrigatória';

  @override
  String get bpOptionalType => 'Opcional';

  @override
  String get bpGoal => 'Objetivo';

  @override
  String get bpNoGoalsHint =>
      'Ainda não tens objetivos.\nCria um (ex.: férias) e as transferências para a sua subcategoria contam para ele.';

  @override
  String bpGoalReachedAmount(String amount) {
    return 'Atingido · $amount';
  }

  @override
  String bpGoalProgress(String saved, String target, String remaining) {
    return '$saved de $target · faltam $remaining';
  }

  @override
  String get bpNewGoal => 'Novo objetivo';

  @override
  String get bpEditGoal => 'Editar objetivo';

  @override
  String get bpName => 'Nome';

  @override
  String get bpGoalNameHint => 'Ex.: Férias de verão';

  @override
  String bpGoalAmount(String currency) {
    return 'Valor do objetivo ($currency)';
  }

  @override
  String get bpPreviousAmountKept =>
      'Se o alterares, o valor anterior fica no histórico.';

  @override
  String get bpDeadlineOptional => 'Prazo (opcional)';

  @override
  String get bpNoDeadline => 'Sem prazo';

  @override
  String get bpRemoveDeadline => 'Remover prazo';

  @override
  String get bpDescriptionOptional => 'Descrição (opcional)';

  @override
  String get bpCategoryWhere => 'Categoria onde fica';

  @override
  String get bpChooseCategory => 'Escolher categoria';

  @override
  String get bpGoalCategoryHint =>
      'O objetivo vira uma subcategoria desta categoria. Os movimentos nessa subcategoria contam como poupança.';

  @override
  String get bpEnterName => 'Indica um nome.';

  @override
  String get bpEnterGoalAmount => 'Indica o valor do objetivo.';

  @override
  String get bpChooseGoalCategory =>
      'Escolhe a categoria onde fica o objetivo.';

  @override
  String get bpGoalDeleted => 'Objetivo apagado.';

  @override
  String bpDeleteGoalQuestion(String name) {
    return 'Apagar o objetivo “$name”? Os movimentos ficam, mas deixam de estar associados a ele.';
  }

  @override
  String get bpAlreadyHave => 'Já tens';

  @override
  String get bpExceeded => 'Excedido';

  @override
  String get bpRemaining => 'Faltam';

  @override
  String bpGoalPercentDeadline(String percent, String deadline) {
    return '$percent% · $deadline';
  }

  @override
  String get bpNoDeadlineLower => 'sem prazo';

  @override
  String bpDeadlineDate(String date) {
    return 'prazo $date';
  }

  @override
  String get bpLinkTransaction => 'Associar movimento';

  @override
  String get bpChangeAmount => 'Alterar valor';

  @override
  String get bpAmountHistory => 'Histórico do valor';

  @override
  String get bpNoGoalEntriesHint =>
      'Ainda nada. Transferências na subcategoria do objetivo entram sozinhas; pagamentos feitos com outra categoria associas com “Associar movimento”.';

  @override
  String bpEntrySubtitle(String date, String kind) {
    return '$date · $kind';
  }

  @override
  String get bpLinkedManual => 'associado';

  @override
  String get bpLinkedByCategory => 'pela categoria';

  @override
  String get bpUnlink => 'Desassociar';

  @override
  String get bpStatusReached => 'Objetivo atingido.';

  @override
  String bpStatusOnTrack(String monthly, String needed) {
    return 'No ritmo atual chegas a tempo: fazes $monthly/mês e precisas de $needed/mês.';
  }

  @override
  String bpStatusBehind(String needed, String monthly) {
    return 'Para chegar a tempo precisas de $needed/mês; estás a fazer $monthly/mês.';
  }

  @override
  String bpStatusEta(String monthly, String date) {
    return 'No ritmo atual ($monthly/mês) chegas a $date.';
  }

  @override
  String bpStatusNoRecent(String amount) {
    return 'Sem movimentos recentes. Faltam $amount.';
  }

  @override
  String get bpChangeGoalAmountTitle => 'Alterar valor do objetivo';

  @override
  String bpNewAmount(String currency) {
    return 'Novo valor ($currency)';
  }

  @override
  String get bpChangeAmountHint =>
      'O valor anterior fica no histórico. Os movimentos já associados mantêm-se.';

  @override
  String get bpSearchTransaction => 'Procurar movimento';

  @override
  String get bpNoTransactionsToLink => 'Nenhum movimento para associar.';

  @override
  String bpTxnLinkSubtitle(String date, String amount, String left) {
    return '$date · $amount · por associar $left';
  }

  @override
  String bpAmountForGoal(String goal, String currency) {
    return 'Valor para “$goal” ($currency)';
  }

  @override
  String bpUnlinkedHint(String left) {
    return 'Por associar: $left. Podes dividir o movimento por vários objetivos.';
  }

  @override
  String get bpLink => 'Associar';

  @override
  String get bpMonday => 'segunda-feira';

  @override
  String get bpTuesday => 'terça-feira';

  @override
  String get bpWednesday => 'quarta-feira';

  @override
  String get bpThursday => 'quinta-feira';

  @override
  String get bpFriday => 'sexta-feira';

  @override
  String get bpSaturday => 'sábado';

  @override
  String get bpSunday => 'domingo';

  @override
  String get bpJanuary => 'janeiro';

  @override
  String get bpFebruary => 'fevereiro';

  @override
  String get bpMarch => 'março';

  @override
  String get bpApril => 'abril';

  @override
  String get bpMay => 'maio';

  @override
  String get bpJune => 'junho';

  @override
  String get bpJuly => 'julho';

  @override
  String get bpAugust => 'agosto';

  @override
  String get bpSeptember => 'setembro';

  @override
  String get bpOctober => 'outubro';

  @override
  String get bpNovember => 'novembro';

  @override
  String get bpDecember => 'dezembro';

  @override
  String get bpFreqMonthly => 'Mensal';

  @override
  String get bpFreqWeekly => 'Semanal';

  @override
  String get bpFreqYearly => 'Anual';

  @override
  String bpWhenMonthly(int day) {
    return 'dia $day';
  }

  @override
  String bpWhenYearly(int day, String month) {
    return '$day de $month';
  }

  @override
  String get bpNoRecurringHint =>
      'Ainda não há movimentos recorrentes.\n\nRegista aqui o salário, a renda ou uma subscrição: o movimento é criado sozinho na data certa.';

  @override
  String get bpRecurringTitle => 'Movimentos recorrentes';

  @override
  String get bpNew => 'Novo';

  @override
  String get bpPaused => 'em pausa';

  @override
  String get bpEnded => 'terminada';

  @override
  String bpNextDate(String date) {
    return 'próxima $date';
  }

  @override
  String get bpEditRecurring => 'Editar recorrente';

  @override
  String get bpNewRecurring => 'Novo recorrente';

  @override
  String get bpEnterDescription => 'Escreve uma descrição.';

  @override
  String get bpEnterAmount => 'Indica um valor.';

  @override
  String get bpEndBeforeStart => 'A data de fim é anterior à de início.';

  @override
  String bpDeleteRecurringQuestion(String description) {
    return 'Apagar \"$description\"? Os movimentos já registados ficam.';
  }

  @override
  String get bpExpenseType => 'Despesa';

  @override
  String get bpIncomeType => 'Receita';

  @override
  String get bpDescription => 'Descrição';

  @override
  String get bpDescriptionHint => 'Ex.: Salário, Renda, Netflix';

  @override
  String get bpCategory => 'Categoria';

  @override
  String get bpAccount => 'Conta';

  @override
  String get bpNoAccount => 'Sem conta';

  @override
  String get bpFrequency => 'Frequência';

  @override
  String get bpDayOfWeek => 'Dia da semana';

  @override
  String get bpDayOfMonth => 'Dia do mês';

  @override
  String get bpShortMonthHint =>
      'Em meses mais curtos, passa para o último dia do mês.';

  @override
  String get bpStart => 'Início';

  @override
  String get bpPastStartHint =>
      'Se a data de início já passou, os movimentos desde então são criados ao abrir a app.';

  @override
  String get bpEndOptional => 'Fim (opcional)';

  @override
  String get bpNoEndDate => 'Sem data de fim';

  @override
  String get bpRemoveEndDate => 'Remover data de fim';

  @override
  String get bpActive => 'Ativa';

  @override
  String get bpActiveHint => 'Desativa para pausar, sem apagar';

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

  @override
  String get frmReceipt => 'Recibo';

  @override
  String get frmViewReceipt => 'Ver recibo';

  @override
  String get frmTakePhoto => 'Tirar foto';

  @override
  String get frmChooseFromGallery => 'Escolher da galeria';

  @override
  String get frmChooseFile => 'Escolher ficheiro (PDF ou imagem)';

  @override
  String get frmRemoveReceipt => 'Remover recibo';

  @override
  String frmReceiptAttachError(String error) {
    return 'Não foi possível anexar o recibo: $error';
  }

  @override
  String get frmReceiptFileNotFound => 'Ficheiro do recibo não encontrado.';

  @override
  String get frmEnterValidAmount => 'Indica um montante válido.';

  @override
  String frmAllocatedToGoals(String amount) {
    return 'Já tens $amount associado a objetivos. Reduz as associações primeiro.';
  }

  @override
  String frmTransferTo(String name) {
    return 'Transferência para $name';
  }

  @override
  String get frmTransfer => 'Transferência';

  @override
  String get frmExpense => 'Despesa';

  @override
  String get frmIncome => 'Receita';

  @override
  String get frmReversedGone => 'A despesa anulada já não existe.';

  @override
  String get frmEnterReversedAmount => 'Indica quanto da despesa é anulado.';

  @override
  String get frmReversalTooBig =>
      'A anulação não pode ser maior que a receita.';

  @override
  String frmOnlyLeftToReverse(String amount) {
    return 'Só faltam $amount para anular nesta despesa.';
  }

  @override
  String frmReversalHelp(String amount) {
    return 'Ainda se pode anular $amount desta despesa. A parte anulada não conta como gasto nem como receita na Análise.';
  }

  @override
  String get frmSearchExpense => 'Procurar despesa';

  @override
  String get frmNoReversal => 'Não anula nenhuma despesa';

  @override
  String frmToReverseSubtitle(String date, String amount, String left) {
    return '$date · $amount · por anular $left';
  }

  @override
  String get frmNoExpenseToReverse => 'Nenhuma despesa para anular.';

  @override
  String get frmInvestPlatform => 'Plataforma de investimento';

  @override
  String get frmNone => 'Nenhuma';

  @override
  String get frmExpenseGone => 'Despesa já não existe';

  @override
  String get frmSaveToSplit =>
      'Guarda o movimento para o dividir por objetivos.';

  @override
  String get frmChangeAmount => 'Alterar valor';

  @override
  String get frmUnlink => 'Desassociar';

  @override
  String frmToAllocate(String amount) {
    return 'Por associar: $amount';
  }

  @override
  String get frmSplitByGoals => 'Dividir por objetivos';

  @override
  String get frmSplitByGoal => 'Dividir por objetivo';

  @override
  String get frmAllocate => 'Associar';

  @override
  String get frmSave => 'Guardar';

  @override
  String get frmAccount => 'Conta';

  @override
  String get frmFromAccount => 'Da conta';

  @override
  String get frmDestinationAccount => 'Conta de destino';

  @override
  String get frmSelectAccount => 'Seleciona uma conta';

  @override
  String get frmSelectDestinationAccount => 'Seleciona a conta de destino';

  @override
  String get frmToAccount => 'Para a conta';

  @override
  String get frmTakePhotoOrChoose => 'Tira uma foto ou escolhe um ficheiro';

  @override
  String get frmEditTransaction => 'Editar movimento';

  @override
  String get frmNewTransaction => 'Novo movimento';

  @override
  String get frmImportStatementTip => 'Importar extrato';

  @override
  String get frmDeleteThisTransaction => 'Apagar este movimento?';

  @override
  String get frmCalculator => 'Calculadora';

  @override
  String get frmCategory => 'Categoria';

  @override
  String get frmChooseCategory => 'Escolher categoria';

  @override
  String get frmReversesExpense => 'Anula uma despesa (reembolso, devolução)';

  @override
  String frmReversedAmount(String currency) {
    return 'Valor anulado ($currency)';
  }

  @override
  String get frmDescriptionOptional => 'Descrição (opcional)';

  @override
  String get frmToday => 'Hoje';

  @override
  String get frmYesterday => 'Ontem';

  @override
  String get frmOtherDate => 'Outra data';

  @override
  String get frmToInvestOptional => 'Para investir (opcional)';

  @override
  String get frmOutgoing => 'Saída';

  @override
  String get frmIncoming => 'Entrada';

  @override
  String get frmNotCountedNote =>
      'Não conta como despesa nem receita na Análise.';

  @override
  String get frmMoreOptions => 'Mais opções (conta, recibo)';

  @override
  String frmAmountCurrency(String currency) {
    return 'Valor ($currency)';
  }

  @override
  String frmOnlyLeftToAllocate(String amount) {
    return 'Só faltam $amount para associar.';
  }

  @override
  String get frmOptional => ' (opcional)';

  @override
  String get frmCalcHint => 'Ex.: 12,50+3*2';

  @override
  String get frmUse => 'Usar';

  @override
  String get frmWholeFile => 'Todo o ficheiro';

  @override
  String get frmPeriodToImport => 'Período a importar';

  @override
  String frmFileDataRange(String from, String to) {
    return 'O ficheiro tem dados de $from a $to. Escolhe só o intervalo que queres importar.';
  }

  @override
  String get frmFrom => 'De';

  @override
  String get frmUntil => 'Até';

  @override
  String frmInRangeOfTotal(int inRange, int total) {
    return '$inRange de $total no período';
  }

  @override
  String frmTotalInFile(int total) {
    return '$total no ficheiro';
  }

  @override
  String get frmSelectCategory => 'Seleciona uma categoria';

  @override
  String get frmNewCategory => '➕  Nova categoria…';

  @override
  String get frmNoCategoryItem => '✖️  Sem categoria';

  @override
  String get frmHideEndedFuture => '🙈  Esconder terminadas e futuras';

  @override
  String get frmShowEndedFuture => '👁  Mostrar terminadas e futuras';

  @override
  String get frmEnded => '  · terminada';

  @override
  String get frmUpcoming => '  · futura';

  @override
  String get frmSelectSubcategory => 'Seleciona uma subcategoria';

  @override
  String get frmSubcategory => 'Subcategoria';

  @override
  String get frmNewSubcategory => '➕  Nova subcategoria…';

  @override
  String get frmNoSubcategory => '— Sem subcategoria —';

  @override
  String get frmChoose => 'Escolher';

  @override
  String get frmChooseEmoji => 'Escolher emoji';

  @override
  String get frmOrUseKeyboardEmoji => 'Ou usa outro emoji do teclado';

  @override
  String get frmRemove => 'Remover';

  @override
  String get frmChooseColor => 'Escolher cor';

  @override
  String get frmHue => 'Matiz';

  @override
  String get frmSaturation => 'Saturação';

  @override
  String get frmBrightness => 'Brilho';

  @override
  String get frmHex => 'Hexadecimal';

  @override
  String frmMandatoryTitle(String name) {
    return 'Obrigatória · $name';
  }

  @override
  String get frmMandatoryExplain =>
      'Os meses abaixo contam como despesa obrigatória nesta categoria. Nos restantes meses é opcional.';

  @override
  String get frmNoPeriodDefined => 'Nenhum período definido.';

  @override
  String frmFromMonth(String month) {
    return 'A partir de $month';
  }

  @override
  String get frmClose => 'Fechar';

  @override
  String get frmAddPeriod => 'Adicionar período';

  @override
  String get frmAdd => 'Adicionar';

  @override
  String get frmPickAnyDayOfMonth => 'Escolhe qualquer dia do mês';

  @override
  String get frmNewPeriod => 'Novo período';

  @override
  String frmSinceMonth(String month) {
    return 'Desde $month';
  }

  @override
  String get frmNoEndDate => 'Sem data de fim';

  @override
  String frmUntilMonth(String month) {
    return 'Até $month';
  }

  @override
  String get frmMainCategories => 'Principais';

  @override
  String frmOnlyName(String name) {
    return 'Só $name';
  }

  @override
  String get frmNoSubcategories => 'Esta categoria não tem subcategorias.';

  @override
  String get frmSearchCategory => 'Procurar categoria';

  @override
  String get frmNoCategoriesYet =>
      'Ainda não tens categorias. Cria a primeira.';

  @override
  String get frmNoCategoryFound => 'Nenhuma categoria encontrada.';

  @override
  String get frmNewCategoryTitle => 'Nova categoria';

  @override
  String get frmChooseMonth => 'Escolher mês';

  @override
  String get frmEnterName => 'Indica um nome';

  @override
  String get frmMainCategoryExists =>
      'Já existe uma categoria principal com este nome';

  @override
  String frmSubcategoryExists(String parent) {
    return 'Já existe esta subcategoria em $parent';
  }

  @override
  String get frmThisCategory => 'esta categoria';

  @override
  String get frmRepeatedName => 'Nome repetido';

  @override
  String frmRemoveSubQuestion(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count movimentos ficam',
      one: 'O movimento fica',
      zero: 'Os $count movimentos ficam',
    );
    return 'Remover “$name”? $_temp0 sem categoria (só depois de guardares).';
  }

  @override
  String get frmEditCategory => 'Editar categoria';

  @override
  String get frmEditSubcategory => 'Editar subcategoria';

  @override
  String get frmNewSubcategoryTitle => 'Nova subcategoria';

  @override
  String get frmEditCategoryHint => 'Altera os dados e as subcategorias';

  @override
  String get frmEditSubcategoryHint => 'Altera os dados desta subcategoria';

  @override
  String frmCreateSubsIn(String name) {
    return 'Cria subcategorias dentro de $name';
  }

  @override
  String get frmCreateCategoryHint =>
      'Cria uma categoria e as suas subcategorias';

  @override
  String get frmSubcategoryName => 'Nome da subcategoria';

  @override
  String get frmName => 'Nome';

  @override
  String get frmParentCategory => 'Categoria-mãe';

  @override
  String get frmNoneMainCategory => 'Nenhuma (categoria principal)';

  @override
  String get frmHasSubsLock =>
      'Tem subcategorias, por isso não pode ser uma subcategoria.';

  @override
  String get frmSubcategoryOf => 'Subcategoria de ';

  @override
  String get frmCreatingSubcategoryOf => 'A criar subcategoria de ';

  @override
  String frmMoreSubsOf(String name) {
    return 'Mais subcategorias de $name';
  }

  @override
  String get frmSubcategories => 'Subcategorias';

  @override
  String get frmRemoveSubcategory => 'Remover subcategoria';

  @override
  String get frmAddSubcategory => 'Adicionar subcategoria';

  @override
  String get frmOptions => 'Opções';

  @override
  String get frmType => 'Tipo';

  @override
  String get frmOnlyInPeriod => 'Só existe num período';

  @override
  String get frmOnlyInPeriodHint =>
      'Ex.: “Férias 2027”. Fora do período deixa de aparecer nas escolhas.';

  @override
  String get frmSince => 'Desde';

  @override
  String get frmSetEnd => 'Definir fim';

  @override
  String get frmMandatoryIn => 'Obrigatória em…';

  @override
  String get frmOptionalAllMonths => 'Opcional em todos os meses';

  @override
  String frmPeriodsDefined(int count) {
    return '$count período(s) definido(s)';
  }

  @override
  String get frmKindOptional => 'Despesa opcional';

  @override
  String get frmKindMandatory => 'Despesa obrigatória';

  @override
  String get frmKindIncome => 'Rendimento';

  @override
  String get frmKindInvestment => 'Investimento';

  @override
  String get frmKindBoth => 'Despesas e receitas';

  @override
  String get frmKindOptionalHelp =>
      'Gasto que podes cortar (lazer, restaurantes…).';

  @override
  String get frmKindMandatoryHelp =>
      'Gasto fixo do mês (renda, seguros…). Depois podes escolher só alguns meses.';

  @override
  String get frmKindIncomeHelp =>
      'Entradas de dinheiro (ex.: salário). Não conta como despesa.';

  @override
  String get frmKindInvestmentHelp =>
      'Dinheiro que pões a render. Não conta como gasto; aparece como investido.';

  @override
  String get frmKindBothHelp =>
      'Aceita gastos e entradas (ex.: vendas, reembolsos). Os gastos contam como despesa e as entradas como receita.';

  @override
  String get frmAccounts => 'Contas';

  @override
  String get frmNewAccount => 'Nova conta';

  @override
  String get frmEditAccount => 'Editar conta';

  @override
  String get frmAccountNameHint => 'Ex.: Conta à ordem';

  @override
  String frmOpeningBalanceCurrency(String currency) {
    return 'Saldo inicial ($currency)';
  }

  @override
  String get frmOpeningBalanceHelp =>
      'Quanto tinhas na conta antes dos movimentos registados aqui.';

  @override
  String get frmNewAccountItem => 'Nova conta…';

  @override
  String get frmNoAccount => 'Sem conta';

  @override
  String get frmNoAccountsYet =>
      'Ainda não tens contas.\nCria uma para saberes de onde vem cada movimento e para registar transferências entre contas.';

  @override
  String frmAccountSubtitle(int count, String balance) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return '$_temp0 · saldo $balance';
  }

  @override
  String frmDeleteAccountQuestion(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count movimentos ficam',
      one: 'O movimento fica',
      zero: 'Os $count movimentos ficam',
    );
    return 'Apagar a conta “$name”? $_temp0 sem conta.';
  }

  @override
  String get frmAccountDeleted => 'Conta apagada.';

  @override
  String get frmEdit => 'Editar';

  @override
  String get frmBalance => 'Saldo';

  @override
  String frmOpeningBalanceLine(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return 'Saldo inicial $amount · $_temp0';
  }

  @override
  String get frmThisMonth => 'Este mês';

  @override
  String get frmMonthBalance => 'Saldo do mês';

  @override
  String get frmGoalsFedByAccount => 'Objetivos alimentados por esta conta';

  @override
  String get frmNoGoalFunded =>
      'Nenhum objetivo recebe dinheiro desta conta ainda.';

  @override
  String get frmNoTransactionsInAccount => 'Sem movimentos nesta conta.';

  @override
  String get frmObWelcome => 'Bem-vindo';

  @override
  String get frmObFirstAccount => 'Primeira conta';

  @override
  String get frmObSalary => 'Salário';

  @override
  String get frmObDone => 'Pronto';

  @override
  String get frmObEnterAmount1250 => 'Escreve um valor, por exemplo 1250,00';

  @override
  String get frmObEnterAmount1500 => 'Escreve um valor, por exemplo 1500,00';

  @override
  String get frmObWelcomeTitle => 'Bem-vindo às Finanças';

  @override
  String get frmObWelcomeText =>
      'Regista o dinheiro que entra e sai e vê para onde ele vai. Os teus dados ficam guardados só neste telemóvel, sem contas nem partilha.';

  @override
  String get frmObAccountTitle => 'Qual é a tua conta principal?';

  @override
  String get frmObAccountText =>
      'Podes adicionar mais contas depois. Se não quiseres agora, deixa em branco.';

  @override
  String get frmObAccountName => 'Nome da conta';

  @override
  String get frmObSalaryTitle => 'Quanto recebes por mês?';

  @override
  String get frmObSalaryText =>
      'Salário líquido. Serve para o planeamento e para ver quanto ainda podes gastar. Podes mudar ou deixar em branco.';

  @override
  String frmObSalaryField(String currency) {
    return 'Salário líquido mensal ($currency)';
  }

  @override
  String get frmObReadyTitle => 'Está pronto';

  @override
  String get frmObReadyText =>
      'Adiciona movimentos à mão ou importa um extrato. Podes mudar tudo depois nos ecrãs próprios.';

  @override
  String get frmBack => 'Voltar';

  @override
  String get frmFinish => 'Concluir';

  @override
  String get frmNext => 'Seguinte';

  @override
  String get frmAll => 'Todos';

  @override
  String get frmExpenses => 'Despesas';

  @override
  String get frmTransfers => 'Transferências';

  @override
  String frmTransactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return '$_temp0';
  }

  @override
  String frmInvestmentOf(String name) {
    return 'Investimento · $name';
  }

  @override
  String frmOfAmount(String amount) {
    return 'de $amount';
  }

  @override
  String get frmNoIncomeDefined => 'sem rendimento definido';

  @override
  String get frmSetSalaryToSpend =>
      'Define o salário no Orçamento para ver quanto ainda podes gastar.';

  @override
  String frmOverPlanned(String amount) {
    return 'Passaste $amount do previsto';
  }

  @override
  String get frmIncomeExpected => 'Receitas (previstas)';

  @override
  String frmPercentOfIncome(int percent) {
    return '$percent% do rendimento';
  }

  @override
  String frmToClassify(int count) {
    return '$count por classificar';
  }

  @override
  String frmDeliveriesCount(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entregas',
      one: '1 entrega',
      zero: '$count entregas',
    );
    return '$_temp0 · $total';
  }

  @override
  String get frmSetSalaryLeft =>
      'Define o salário no Orçamento para ver o que sobra.';

  @override
  String frmPlanExceeds(String amount) {
    return 'O plano excede o salário em $amount';
  }

  @override
  String frmSavedOfTarget(String saved, String target, String deadline) {
    return '$saved de $target$deadline';
  }

  @override
  String frmUntilDate(String date) {
    return ' · até $date';
  }

  @override
  String get impImportTitle => 'Importar extrato';

  @override
  String get impFormatsInfo =>
      'Formatos suportados: PDF (com texto), CSV e Excel (.xlsx). O ficheiro é lido apenas no telemóvel e nunca sai daqui.';

  @override
  String get impChooseFile => 'Escolher ficheiro';

  @override
  String get impChooseOtherFile => 'Escolher outro ficheiro';

  @override
  String impFileName(String name) {
    return 'Ficheiro: $name';
  }

  @override
  String get impPdfNoRows =>
      'Não encontrei movimentos neste PDF. Pode ser um PDF digitalizado (imagem) ou um formato diferente. Tenta exportar CSV/Excel no homebanking.';

  @override
  String get impCsvNoRows =>
      'Não consegui ler movimentos. Ajusta as colunas abaixo.';

  @override
  String impReadError(String error) {
    return 'Erro ao ler o ficheiro: $error';
  }

  @override
  String get impStatementAccount => 'Conta deste extrato';

  @override
  String get impPickAccountOptional => 'Seleciona uma conta (opcional)';

  @override
  String impTxnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return '$_temp0';
  }

  @override
  String impIncomeExpense(String income, String expense) {
    return 'Entradas $income   ·   Saídas $expense';
  }

  @override
  String get impInvertSigns => 'Inverter sinais';

  @override
  String get impInvertSignsHint => 'Usa se as despesas aparecem como positivas';

  @override
  String impImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count movimentos',
      one: 'Importar 1 movimento',
      zero: 'Importar $count movimentos',
    );
    return '$_temp0';
  }

  @override
  String impImportDone(int added, int duplicates, int unclassified) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added importados',
      one: '1 importado',
      zero: '$added importados',
    );
    String _temp1 = intl.Intl.pluralLogic(
      duplicates,
      locale: localeName,
      other: '$duplicates duplicados ignorados',
      one: '1 duplicado ignorado',
      zero: '$duplicates duplicados ignorados',
    );
    String _temp2 = intl.Intl.pluralLogic(
      unclassified,
      locale: localeName,
      other: '$unclassified grupos por classificar.',
      one: '1 grupo por classificar.',
      zero: '$unclassified grupos por classificar.',
    );
    return '$_temp0, $_temp1. $_temp2';
  }

  @override
  String impClassifiedOf(int classified, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total grupos',
      one: '1 grupo',
      zero: '$total grupos',
    );
    return 'Classificação: $classified de $_temp0';
  }

  @override
  String get impGroupsExplain =>
      'Movimentos com o mesmo nome estão juntos. Escolhe a categoria e a subcategoria de cada grupo (ou deixa por classificar). As regras já memorizadas vêm preenchidas.';

  @override
  String impTransfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transferências entre contas',
      one: '1 transferência entre contas',
      zero: '$count transferências entre contas',
    );
    return '$_temp0';
  }

  @override
  String get impTransfersHint =>
      'Não precisam de categoria e ficam fora das despesas e receitas.';

  @override
  String impOriginal(String description) {
    return 'Original: $description';
  }

  @override
  String impActiveOfTotal(int active, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total movimentos',
      one: '1 movimento',
      zero: '$total movimentos',
    );
    return '$active de $_temp0';
  }

  @override
  String get impRememberedRule => ' · regra memorizada';

  @override
  String get impNameOrGroup => 'Nome ou grupo (opcional)';

  @override
  String get impNameHint => 'Ex.: Ginásio, Restaurante Arminda…';

  @override
  String impJoinsGroup(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count títulos',
      one: '1 título',
      zero: '$count títulos',
    );
    return 'Junta-se ao grupo “$name” ($_temp0)';
  }

  @override
  String get impRememberNameCategory =>
      'Memorizar nome e categoria para o futuro';

  @override
  String get impViewTransactions => 'Ver movimentos';

  @override
  String get impAccountsInStatement => 'Contas neste extrato';

  @override
  String impAccountsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contas detetadas',
      one: '1 conta detetada',
      zero: '$count contas detetadas',
    );
    return '$_temp0. Escolhe a que corresponde a cada uma na app.';
  }

  @override
  String impAccountTxns(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String impCreateAccount(String name) {
    return '➕  Criar conta “$name”';
  }

  @override
  String get impNoAccount => 'Sem conta';

  @override
  String get impDetectTransfers => 'Detetar transferências entre estas contas';

  @override
  String get impDetectTransfersHint =>
      'Saída numa conta e entrada noutra, do mesmo valor, não contam como despesa nem receita.';

  @override
  String impSkippedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linhas parecem movimentos mas não foram reconhecidas',
      one: '1 linha parece movimentos mas não foi reconhecida',
      zero: '$count linhas parecem movimentos mas não foram reconhecidas',
    );
    return '$_temp0';
  }

  @override
  String impSkippedSub(int count) {
    return 'Lidos: $count. Toca para ver as linhas ignoradas.';
  }

  @override
  String impAndMore(int count) {
    return '… e mais $count';
  }

  @override
  String get impSkippedHelp =>
      'Se for um extrato do teu banco, exporta em CSV/Excel no homebanking ou envia-me um exemplo (com os dados tapados) para eu ajustar o leitor.';

  @override
  String get impYearForDates => 'Ano das datas sem ano';

  @override
  String get impYearHint => 'Só afeta datas escritas como dd-mm';

  @override
  String get impFileColumns => 'Colunas do ficheiro';

  @override
  String get impHeaderRow => 'Linha de cabeçalho';

  @override
  String get impDate => 'Data';

  @override
  String get impDescription => 'Descrição';

  @override
  String get impAmountSigned => 'Montante (com sinal)';

  @override
  String get impDebitOut => 'Débito (saídas)';

  @override
  String get impCreditIn => 'Crédito (entradas)';

  @override
  String get impBalanceOptional => 'Saldo (opcional)';

  @override
  String get impDoNotUse => '— não usar —';

  @override
  String impColumnN(int n) {
    return 'Coluna $n';
  }

  @override
  String get impClassifyTitle => 'Classificar';

  @override
  String get impClassifySubtitle =>
      'Revê e categoriza as tuas transações importadas';

  @override
  String get impSort => 'Ordenar';

  @override
  String get impSortCount => 'Mais movimentos';

  @override
  String get impSortTotal => 'Maior valor';

  @override
  String get impSortRecent => 'Mais recentes';

  @override
  String get impSortName => 'Nome (A-Z)';

  @override
  String get impGroups => 'Grupos';

  @override
  String get impRules => 'Regras memorizadas';

  @override
  String get impSearchGroups => 'Pesquisar grupos ou estabelecimentos…';

  @override
  String impToClassifyChip(int count) {
    return 'Por classificar ($count)';
  }

  @override
  String get impAll => 'Todos';

  @override
  String get impApplyRules => 'Aplicar regras';

  @override
  String impClassifiedByRules(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos classificados pelas regras.',
      one: '1 movimento classificado pelas regras.',
      zero: '$count movimentos classificados pelas regras.',
    );
    return '$_temp0';
  }

  @override
  String get impAllClassified => 'Tudo classificado! 🎉';

  @override
  String get impNoTransactionsYet => 'Ainda não há movimentos.';

  @override
  String impClassifiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos classificados.',
      one: '1 movimento classificado.',
      zero: '$count movimentos classificados.',
    );
    return '$_temp0';
  }

  @override
  String get impSelectAll => 'Selecionar tudo';

  @override
  String impApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return 'Aplicar a $_temp0';
  }

  @override
  String impTxnCountDate(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos',
      one: '1 movimento',
      zero: '$count movimentos',
    );
    return '$_temp0 · $date';
  }

  @override
  String impGroupChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count títulos',
      one: '1 título',
      zero: '$count títulos',
    );
    return 'Grupo · $_temp0';
  }

  @override
  String get impRemembered => 'Memorizado';

  @override
  String impSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
      zero: '$count selecionados',
    );
    return '$_temp0';
  }

  @override
  String get impChooseCategory => 'Escolhe a categoria';

  @override
  String impMoveTo(String category) {
    return 'Mover para $category';
  }

  @override
  String get impRememberForFuture => 'Memorizar para futuros';

  @override
  String get impWhatIsThis => 'O que é isto?';

  @override
  String get impRememberHelp =>
      'Guarda uma regra: da próxima vez que aparecer um movimento com este título, a app aplica logo o nome e a categoria que escolheste.';

  @override
  String get impOk => 'OK';

  @override
  String get impNameAndNotes => 'Nome e notas';

  @override
  String get impForgetRule => 'Esquecer regra';

  @override
  String impForgetRuleQuestion(String key) {
    return 'Esquecer a regra para “$key”? Os movimentos já classificados mantêm-se.';
  }

  @override
  String get impForget => 'Esquecer';

  @override
  String get impJoinGroup => 'Juntar a grupo';

  @override
  String get impManageGroup => 'Gerir grupo';

  @override
  String get impJoinAGroup => 'Juntar a um grupo';

  @override
  String get impFriendlyName => 'Nome amigável (opcional)';

  @override
  String get impExampleGym => 'Ex.: Ginásio';

  @override
  String get impRuleDescription => 'Descrição da regra (opcional)';

  @override
  String get impNoteAllTx => 'Nota em todos os movimentos (opcional)';

  @override
  String get impNameSavedHint =>
      'O nome e a descrição ficam guardados na regra, para as próximas importações.';

  @override
  String get impSave => 'Guardar';

  @override
  String get impNoRules =>
      'Sem regras. Ao mover movimentos com “Memorizar”, as regras aparecem aqui.';

  @override
  String get impEquals => 'Igual a';

  @override
  String get impContains => 'Contém';

  @override
  String get impRule => 'Regra';

  @override
  String get impNewRule => 'Nova regra';

  @override
  String get impEditRule => 'Editar regra';

  @override
  String get impTextToRecognize => 'Texto a reconhecer (MAIÚSCULAS)';

  @override
  String get impExactName => 'Nome exatamente igual';

  @override
  String get impExactNameOff => 'Desligado: basta conter o texto';

  @override
  String get impDescriptionOptional => 'Descrição (opcional)';

  @override
  String get impNewGroup => 'Novo grupo';

  @override
  String get impName => 'Nome';

  @override
  String get impExampleRestaurant => 'Ex.: Restaurante Arminda';

  @override
  String get impCreate => 'Criar';

  @override
  String get impGroupsEmpty =>
      'Ainda não tens grupos.\n\nUm grupo junta títulos diferentes que são a mesma coisa, por exemplo “TRANS RESTAURANTE ARMINDA” e “MB WAY RESTAURANTE ARMINDA” → “Restaurante Arminda”, com uma categoria só.';

  @override
  String get impDeleteGroup => 'Apagar grupo';

  @override
  String get impGroupDeleted => 'Grupo apagado.';

  @override
  String impDeleteGroupQuestion(String name) {
    return 'Apagar o grupo “$name”? Os títulos ficam com o nome e a categoria que tinham no grupo, mas deixam de estar juntos.';
  }

  @override
  String get impJoinTitles => 'Juntar títulos';

  @override
  String get impGroupName => 'Nome do grupo';

  @override
  String get impGroupSaved => 'Grupo guardado.';

  @override
  String impGroupExists(String name) {
    return 'Já existe um grupo chamado “$name”.';
  }

  @override
  String impTitlesInGroup(int count) {
    return 'Títulos neste grupo ($count)';
  }

  @override
  String get impGroupAnyTitle =>
      'Qualquer movimento com um destes títulos recebe o nome e a categoria do grupo, agora e nas próximas importações.';

  @override
  String get impGroupEmptyHint => 'Ainda vazio. Usa “Juntar títulos”.';

  @override
  String get impRemoveFromGroup => 'Tirar do grupo';

  @override
  String get impSearchTitles => 'Pesquisar títulos';

  @override
  String get impNoTitlesFound => 'Nenhum título encontrado.';

  @override
  String impAlreadyInGroup(String name) {
    return ' · já está em “$name”';
  }

  @override
  String get impOrAnyTitle => 'Ou: qualquer título que contenha…';

  @override
  String get impJoin => 'Juntar';

  @override
  String impTitleLabel(String title) {
    return 'Título: $title';
  }

  @override
  String impTitlesList(int count, String list) {
    return '$count títulos: $list';
  }

  @override
  String get impExistingGroup => 'Grupo existente';

  @override
  String get impOr => 'ou';

  @override
  String impExistsJoins(String name) {
    return 'Já existe: vai juntar-se a “$name”';
  }

  @override
  String impTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count títulos',
      one: '1 título',
      zero: '$count títulos',
    );
    return '$_temp0';
  }

  @override
  String get invAdd => 'Adicionar';

  @override
  String get invRecordOperation => 'Registar operação';

  @override
  String get invRecordOperationHint =>
      'Compra, venda, dividendo ou o que já tinhas';

  @override
  String get invImportFromFile => 'Importar de um ficheiro';

  @override
  String get invImportFileHint => 'PDF, CSV ou Excel da corretora';

  @override
  String get invNewHolding => 'Novo ativo';

  @override
  String get invNewHoldingHint => 'ETF, ação, cripto, fundo…';

  @override
  String get invNewAccount => 'Nova plataforma';

  @override
  String get invNewAccountHint => 'XTB, Trade Republic, exchange…';

  @override
  String get invTitle => 'Investimentos';

  @override
  String get invImportTrades => 'Importar compras e vendas';

  @override
  String get invRefreshPrices => 'Atualizar preços';

  @override
  String get invImportCardHint =>
      'Escolhe um ficheiro PDF, CSV ou Excel da tua corretora';

  @override
  String get invMyPortfolio => 'A minha carteira';

  @override
  String get invTotalValue => 'Valor total';

  @override
  String get invInvested => 'Investido';

  @override
  String get invCurrentValue => 'Valor atual';

  @override
  String get invGainLoss => 'Ganho / perda';

  @override
  String get invUnallocated => 'Por alocar';

  @override
  String get invUnallocatedStandby => 'Por alocar (standby)';

  @override
  String get invRealizedGain => 'Ganho realizado';

  @override
  String get invDividends => 'Dividendos';

  @override
  String invPricesUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preços atualizados.',
      one: '1 preço atualizado.',
      zero: '$count preços atualizados.',
    );
    return '$_temp0';
  }

  @override
  String invPricesFailed(String details) {
    return 'Falhou: $details';
  }

  @override
  String get invNoAutoPrices => 'Nenhum ativo com preço automático.';

  @override
  String invPricesUpdatedAgo(String ago) {
    return 'Preços atualizados $ago';
  }

  @override
  String get invNoPricesYet => 'Ainda sem preços. Carrega em atualizar.';

  @override
  String get invPricesManual => 'Preços definidos à mão em cada ativo.';

  @override
  String get invUnpricedNote =>
      'Ativos sem preço contam pelo custo, para não distorcer o total.';

  @override
  String get invWhereMoneyIs => 'Onde está o dinheiro';

  @override
  String get invByAsset => 'Por ativo';

  @override
  String get invByPlatform => 'Por plataforma';

  @override
  String get invByType => 'Por tipo';

  @override
  String get invTotal => 'Total';

  @override
  String get invCashToAllocate => 'Dinheiro por alocar';

  @override
  String get invCashSubtitle =>
      'Enviado para as plataformas e ainda não investido (standby)';

  @override
  String get invNegativeCashHint =>
      'Negativo: falta uma entrega ou um acerto de dinheiro';

  @override
  String get invAllocate => 'Alocar';

  @override
  String get invAdjust => 'Acertar';

  @override
  String get invPlatforms => 'Plataformas';

  @override
  String invAssetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ativos',
      one: '1 ativo',
      zero: '$count ativos',
    );
    return '$_temp0';
  }

  @override
  String invAccountLine(String cash, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ativos',
      one: '1 ativo',
      zero: '$count ativos',
    );
    return 'Por alocar $cash · $_temp0';
  }

  @override
  String get invIntroTitle => 'Acompanha o que tens investido';

  @override
  String get invIntroSubtitle =>
      'Onde está o teu dinheiro, quanto vale e quanto está por alocar';

  @override
  String get invStep1Title => '1. Cria uma plataforma';

  @override
  String get invStep1Desc => 'XTB, Trade Republic, uma exchange de cripto…';

  @override
  String get invStep2Title => '2. Associa as transferências do banco';

  @override
  String get invStep2Desc =>
      'Marcas quais foram dinheiro enviado para a plataforma. Deixam de contar como despesa.';

  @override
  String get invStep3Title => '3. Diz o que já tinhas';

  @override
  String get invStep3Desc =>
      'Quantidade e preço médio de compra do que investiste antes de usar a app.';

  @override
  String get invStep4Title => '4. Aloca o dinheiro';

  @override
  String get invStep4Desc =>
      'Regista compras. O que sobra fica por alocar (standby).';

  @override
  String get invStep5Title => '5. Atualiza os preços';

  @override
  String get invStep5Desc =>
      'Com APIs gratuitas (Yahoo Finance e CoinGecko), só quando tu pedires.';

  @override
  String get invCreateFirstPlatform => 'Criar a primeira plataforma';

  @override
  String get invImportFromFileButton =>
      'Importar compras e vendas de um ficheiro';

  @override
  String invTopAssetWeight(String label, String share) {
    return '$label pesa $share da carteira.';
  }

  @override
  String get invKindEtf => 'ETF';

  @override
  String get invKindStock => 'Ação';

  @override
  String get invKindCrypto => 'Cripto';

  @override
  String get invKindFund => 'Fundo';

  @override
  String get invKindBond => 'Obrigação';

  @override
  String get invKindOther => 'Outro';

  @override
  String get invProviderManual => 'Manual';

  @override
  String get invProviderYahoo => 'Yahoo Finance';

  @override
  String get invProviderCoingecko => 'CoinGecko';

  @override
  String get invOpInitial => 'Posição inicial';

  @override
  String get invOpBuy => 'Compra';

  @override
  String get invOpSell => 'Venda';

  @override
  String get invOpDividend => 'Dividendo';

  @override
  String get invOpCash => 'Acerto de dinheiro';

  @override
  String invAddToAccount(String name) {
    return 'Adicionar a $name';
  }

  @override
  String invDeleteAccountConfirm(String name) {
    return 'Apagar a plataforma “$name” com os seus ativos e operações? Os movimentos do banco ficam (deixam de estar associados).';
  }

  @override
  String get invSummary => 'Resumo';

  @override
  String get invCashAccountSubtitle =>
      'O que está na plataforma e ainda não foi investido';

  @override
  String get invBankDepositsNet => 'Entregas do banco (líquidas)';

  @override
  String get invCashAdjustments => 'Acertos de dinheiro';

  @override
  String get invSales => 'Vendas';

  @override
  String get invPurchases => 'Compras';

  @override
  String get invNegativeAccountCash =>
      'O valor está negativo: gastaste mais do que o dinheiro registado. Associa a transferência do banco ou acerta o dinheiro que já lá estava.';

  @override
  String get invAllocateMoney => 'Alocar dinheiro';

  @override
  String get invBankTransfers => 'Transferências do banco';

  @override
  String invMarkTransfersFor(String name) {
    return 'Marca quais foram dinheiro enviado para $name';
  }

  @override
  String invLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count associadas · não contam como despesa',
      one: '1 associada · não conta como despesa',
      zero: '$count associadas · não contam como despesa',
    );
    return '$_temp0';
  }

  @override
  String get invLinkBankTransfers => 'Associar transferências do banco';

  @override
  String invSuggestedMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos parecem ser desta plataforma',
      one: '1 movimento parece ser desta plataforma',
      zero: '$count movimentos parecem ser desta plataforma',
    );
    return '$_temp0';
  }

  @override
  String invSuggestedBody(String name) {
    return 'Têm “$name” no nome. Toca para rever e associar.';
  }

  @override
  String get invUnlink => 'Desassociar';

  @override
  String get invDeliveryLower => 'entrega';

  @override
  String get invWithdrawalLower => 'levantamento';

  @override
  String invAndMore(int count) {
    return '… e mais $count';
  }

  @override
  String get invRememberedTitles =>
      'Títulos lembrados para as próximas importações';

  @override
  String get invAssets => 'Ativos';

  @override
  String get invNew => 'Novo';

  @override
  String get invNoAssetsYet =>
      'Ainda sem ativos. Cria um (ex.: o ETF ou a ação que compraste) e regista a posição que já tinhas ou uma compra.';

  @override
  String get invHistory => 'Histórico';

  @override
  String get invTapToEdit => 'Toca para editar';

  @override
  String get invEdit => 'Editar';

  @override
  String get invHoldingDeleted => 'Ativo apagado.';

  @override
  String get invHoldingDeletedShort => 'Ativo apagado';

  @override
  String get invAccountDeleted => 'Plataforma apagada.';

  @override
  String get invTransferDeleted => 'Transferência apagada.';

  @override
  String get invTransfersTitle => 'Transferências para investir';

  @override
  String invTapToAssignWithAmount(String amount) {
    return 'Toca numa para dizer em que compras foi usada. Por investir: $amount';
  }

  @override
  String get invTapToAssign => 'Toca numa para dizer em que compras foi usada';

  @override
  String invSeeAll(int count) {
    return 'Ver todas ($count)';
  }

  @override
  String get invNoTransfersYet =>
      'Ainda não associaste transferências do banco a uma plataforma.';

  @override
  String get invNothingAssigned =>
      'Nada associado ainda · toca para escolher as compras';

  @override
  String invAllocationSummary(String allocated, String holdText) {
    return 'Investido $allocated · $holdText';
  }

  @override
  String invOnHoldLower(String amount) {
    return 'em espera $amount';
  }

  @override
  String invOverAllocatedLower(String amount) {
    return 'mais $amount do que a transferência';
  }

  @override
  String invInvestedAmount(String amount) {
    return 'Investido $amount';
  }

  @override
  String invOnHold(String amount) {
    return 'Em espera $amount';
  }

  @override
  String invMoreThanAmount(String amount) {
    return 'Mais $amount';
  }

  @override
  String get invUseTransfer => 'Usar esta transferência';

  @override
  String get invPlatformDefault => 'Plataforma';

  @override
  String get invThePlatform => 'a plataforma';

  @override
  String invTransferTo(String amount, String name) {
    return '$amount para $name';
  }

  @override
  String get invOverAllocatedNote =>
      'As compras escolhidas somam mais do que a transferência. Deve ter entrado dinheiro de antes; podes continuar.';

  @override
  String invHoldRemainder(String amount) {
    return '$amount desta transferência ficou em espera, por investir.';
  }

  @override
  String get invSuggest => 'Sugerir';

  @override
  String get invClearAll => 'Limpar (tudo em espera)';

  @override
  String get invSaveAllOnHold => 'Guardar (tudo em espera)';

  @override
  String get invSave => 'Guardar';

  @override
  String get invBuysOnPlatform => 'Compras nesta plataforma';

  @override
  String get invMarkBuysHint =>
      'Marca as que foram pagas com esta transferência.';

  @override
  String get invNoBuysYet =>
      'Ainda não há compras registadas nesta plataforma.';

  @override
  String get invUsedElsewhere => 'usada noutra transferência';

  @override
  String invUnits(String qty) {
    return '$qty un.';
  }

  @override
  String get invSetPrice => 'Definir preço';

  @override
  String get invSetPriceManual => 'Definir à mão';

  @override
  String invPricePerUnit(String currency) {
    return 'Preço por unidade ($currency)';
  }

  @override
  String invFxRate(String base, String currency) {
    return 'Câmbio: 1 $base = ? $currency';
  }

  @override
  String get invCurrentPrice => 'Preço atual';

  @override
  String get invNoPrice => 'Sem preço';

  @override
  String invCurrencyChip(String currency, String mode) {
    return 'Moeda: $currency · $mode';
  }

  @override
  String get invCurrencyChosen => 'escolhida';

  @override
  String get invCurrencyAuto => 'automática';

  @override
  String invUpdatedAgo(String ago, String date) {
    return 'Atualizado $ago · $date';
  }

  @override
  String get invRefreshPrice => 'Atualizar preço';

  @override
  String get invPriceUpdated => 'Preço atualizado.';

  @override
  String invRefreshFailedReason(String reason) {
    return 'Não consegui atualizar: $reason';
  }

  @override
  String get invErrorWord => 'erro';

  @override
  String invDeleteHoldingConfirm(String name) {
    return 'Apagar o ativo “$name” e as suas operações?';
  }

  @override
  String get invMyPosition => 'A minha posição';

  @override
  String get invNoPositionYet =>
      'Ainda sem posição. Regista a quantidade e o preço médio do que já tinhas, ou uma compra.';

  @override
  String get invQuantity => 'Quantidade';

  @override
  String get invAvgCost => 'Preço médio de compra';

  @override
  String invGainIn(String currency) {
    return 'Ganho em $currency';
  }

  @override
  String get invPriceOnly => 'só o preço';

  @override
  String get invSetPriceToSeePl =>
      'Define o preço atual para ver o ganho ou perda.';

  @override
  String get invBuy => 'Comprar';

  @override
  String get invSell => 'Vender';

  @override
  String get invOperations => 'Operações';

  @override
  String invFeeLabel(String amount) {
    return 'comissão $amount';
  }

  @override
  String get invPlanTitle => 'Plano de investimento';

  @override
  String get invPlanCardDesc =>
      'Quando entra uma transferência numa plataforma, a Carteira mostra quanto vai para cada ativo. A app não regista compras.';

  @override
  String get invNoPlan => 'Sem plano';

  @override
  String invMissingPercent(String pct) {
    return 'faltam $pct% por distribuir';
  }

  @override
  String invPlanOf(String name) {
    return 'Plano de $name';
  }

  @override
  String get invPlanEditorHint =>
      'Percentagem de cada entrega para cada ativo. Podes deixar parte por distribuir.';

  @override
  String get invPlanNoAssets =>
      'Esta plataforma ainda não tem ativos. Adiciona ativos na Carteira.';

  @override
  String invPlanOver(String pct) {
    return 'Passa $pct% dos 100%.';
  }

  @override
  String invPlanTotal(String pct) {
    return 'Total: $pct%';
  }

  @override
  String get invSumOver100 => 'A soma não pode passar 100%.';

  @override
  String get invInvalidValue => 'Valor inválido.';

  @override
  String get invSavePlan => 'Guardar plano';

  @override
  String get invRemovePlan => 'Remover plano';

  @override
  String invPendingDeliveries(int count) {
    return 'Entregas para distribuir ($count)';
  }

  @override
  String invUndistributed(String amount) {
    return 'Por distribuir: $amount';
  }

  @override
  String get invSeen => 'Visto';

  @override
  String get invAvgShort => 'médio';

  @override
  String get invNoPriceShort => 'sem preço';

  @override
  String get invClosedPosition => 'Posição fechada';

  @override
  String get invfAccountNewTitle => 'Nova plataforma';

  @override
  String get invfAccountEditTitle => 'Editar plataforma';

  @override
  String get invfName => 'Nome';

  @override
  String get invfAccountNameHint => 'Ex.: XTB, Trade Republic';

  @override
  String get invfNoteOptional => 'Nota (opcional)';

  @override
  String get invfNote => 'Nota';

  @override
  String get invfSave => 'Guardar';

  @override
  String get invfSaveChanges => 'Guardar alterações';

  @override
  String get invfEnterName => 'Indica um nome';

  @override
  String get invfAccountNameTaken => 'Já existe uma plataforma com este nome';

  @override
  String invfSearchIn(String provider) {
    return 'Procurar em $provider';
  }

  @override
  String get invfCryptoSearchHint => 'Ex.: bitcoin';

  @override
  String get invfSymbolSearchHint => 'Ex.: VWCE, Apple, S&P 500';

  @override
  String get invfSearchFailed => 'Não foi possível pesquisar.';

  @override
  String get invfNothingFound => 'Nada encontrado.';

  @override
  String get invfClose => 'Fechar';

  @override
  String get invfHoldingNewTitle => 'Novo ativo';

  @override
  String get invfHoldingEditTitle => 'Editar ativo';

  @override
  String get invfHoldingNameHint => 'Ex.: Vanguard FTSE All-World';

  @override
  String get invfPlatform => 'Plataforma';

  @override
  String get invfType => 'Tipo';

  @override
  String get invfAssetCurrency => 'Moeda do ativo';

  @override
  String get invfAutoCurrency => 'Automática (a do preço)';

  @override
  String invfBaseCurrencyOption(String ccy) {
    return '$ccy · moeda de base';
  }

  @override
  String invfCurrencyAutoHint(String ccy) {
    return 'Usa a moeda em que o ativo cota ($ccy). Podes escolher outra à mão.';
  }

  @override
  String get invfDetectedOnPrice => 'detetada ao obter o preço';

  @override
  String get invfUsdHint =>
      'Para ações ou ETFs em dólares, escolhe USD: os preços de compra ficam na moeda do ativo, com o câmbio de cada compra.';

  @override
  String invfForeignCcyHint(String ccy) {
    return 'Compras e preço médio ficam em $ccy; o valor e o ganho da carteira são convertidos para a moeda de base ao câmbio de mercado (atualizado em \"Atualizar preços\").';
  }

  @override
  String invfPriceWithCcy(String ccy) {
    return 'Preço ($ccy)';
  }

  @override
  String invfAvgPriceWithCcy(String ccy) {
    return 'Preço médio ($ccy)';
  }

  @override
  String get invfYahooHint =>
      'Gratuito, sem chave. ETFs, ações e câmbios (ex.: VWCE.DE, AAPL, BTC-EUR). Converte para euros.';

  @override
  String get invfCoingeckoHint =>
      'Gratuito, sem chave. Criptomoedas, pelo id (ex.: bitcoin, ethereum).';

  @override
  String get invfManualHint =>
      'Tu defines o preço quando quiseres. Nada é enviado para a internet.';

  @override
  String get invfCoingeckoId => 'Id no CoinGecko';

  @override
  String get invfNewPlatformItem => '➕  Nova plataforma…';

  @override
  String get invfSymbol => 'Símbolo';

  @override
  String get invfPrice => 'Preço';

  @override
  String get invfSearchTooltip => 'Procurar';

  @override
  String invfCurrentPriceOptional(String ccy) {
    return 'Preço atual ($ccy, opcional)';
  }

  @override
  String invfFxLabel(String base, String ccy) {
    return 'Câmbio: 1 $base = ? $ccy';
  }

  @override
  String invfFxRateLabel(String base, String ccy) {
    return 'Câmbio (1 $base = ? $ccy)';
  }

  @override
  String invfAvgFxLabel(String base, String ccy) {
    return 'Câmbio médio (1 $base = ? $ccy)';
  }

  @override
  String get invfLiveFxTooltip => 'Câmbio de mercado atual (internet)';

  @override
  String invfFxFetchFailed(String message) {
    return 'Não consegui obter o câmbio: $message';
  }

  @override
  String invfPriceFetchFailed(String message) {
    return 'Não consegui obter o preço: $message';
  }

  @override
  String get invfSymbolRequired => 'Indica o símbolo (ou usa a pesquisa)';

  @override
  String get invfFxOrSyncRequired =>
      'Indica o câmbio, ou usa o botão de sincronizar para o câmbio de mercado.';

  @override
  String invfCurrencyPickerHint(String base) {
    return 'O valor é convertido para $base ao câmbio de mercado, atualizado em \"Atualizar preços\". As operações já registadas mantêm os valores que lá estão.';
  }

  @override
  String get invfOpNewTitle => 'Nova operação';

  @override
  String invfOpEditTitle(String type) {
    return 'Editar · $type';
  }

  @override
  String get invfOpInitial => 'Posição inicial';

  @override
  String get invfOpBuy => 'Compra';

  @override
  String get invfOpSell => 'Venda';

  @override
  String get invfOpDividend => 'Dividendo';

  @override
  String get invfOpCash => 'Acerto de dinheiro';

  @override
  String get invfOpAlreadyHeld => 'Já tinha';

  @override
  String get invfOpCashChip => 'Dinheiro';

  @override
  String get invfPlatformLower => 'plataforma';

  @override
  String invfTotalToPay(String amount) {
    return 'Total a pagar: $amount';
  }

  @override
  String invfTotalToPayFee(String amount, String fee) {
    return 'Total a pagar: $amount (com $fee de comissão)';
  }

  @override
  String get invfNoAllocationHint =>
      'Sem alocação: não desconta do dinheiro por alocar. Podes registar a transferência do banco quando quiseres.';

  @override
  String invfNotEnoughUnallocated(String amount, String cash) {
    return 'Ainda não tens $amount por alocar nesta plataforma (tens $cash). Regista a transferência do banco depois, ou desliga \"Descontar do dinheiro por alocar\" em Mais opções.';
  }

  @override
  String invfUnallocatedChange(String before, String after) {
    return 'Dinheiro por alocar: $before → $after.';
  }

  @override
  String invfUnallocatedChangeTitle(String before, String after) {
    return 'Dinheiro por alocar: $before → $after';
  }

  @override
  String invfBalanceChange(String before, String after) {
    return '$before → $after.';
  }

  @override
  String invfYouReceive(String amount) {
    return 'Recebes $amount';
  }

  @override
  String invfRealizedGain(String gain, String avg) {
    return 'Ganho realizado: $gain (preço médio $avg).';
  }

  @override
  String invfPositionCost(String amount) {
    return 'Custo da posição: $amount';
  }

  @override
  String get invfInitialHint =>
      'Posição que já tinhas antes de usar a app. Define o preço médio de compra e não mexe no dinheiro por alocar.';

  @override
  String invfDividendIn(String amount) {
    return 'Entram $amount no dinheiro por alocar';
  }

  @override
  String get invfCashHint =>
      'Usa isto para dinheiro que já estava na plataforma antes de começares a usar a app.';

  @override
  String invfValueWithCcy(String base) {
    return 'Valor ($base)';
  }

  @override
  String invfReceivedWithCcy(String base) {
    return 'Valor recebido ($base)';
  }

  @override
  String invfFeeWithCcy(String base) {
    return 'Comissão ($base)';
  }

  @override
  String get invfQuantity => 'Quantidade';

  @override
  String invfUnitsEquals(String qty) {
    return '= $qty unidades';
  }

  @override
  String get invfCashIn => 'Entrada';

  @override
  String get invfCashOut => 'Saída';

  @override
  String get invfDate => 'Data';

  @override
  String get invfHolding => 'Ativo';

  @override
  String get invfNewAssetItem => '➕  Novo ativo…';

  @override
  String get invfChoosePlatformHint => 'Escolher plataforma';

  @override
  String get invfChoosePlatformShort => 'Escolhe a plataforma';

  @override
  String get invfChoosePlatform => 'Escolhe a plataforma.';

  @override
  String get invfChooseAsset => 'Escolhe o ativo (ou cria um).';

  @override
  String get invfEnterValidAmounts => 'Indica valores válidos.';

  @override
  String invfFxRequired(String base, String ccy) {
    return 'Indica o câmbio (1 $base = ? $ccy).';
  }

  @override
  String get invfEnterQtyPrice => 'Indica a quantidade e o preço.';

  @override
  String invfOnlyHaveUnits(String qty) {
    return 'Só tens $qty unidades para vender.';
  }

  @override
  String get invfMoreOptionsTrade => 'Mais opções (comissão, nota…)';

  @override
  String get invfDeductUnallocated => 'Descontar do dinheiro por alocar';

  @override
  String get invfDeductHint =>
      'Desliga se ainda não registaste a transferência do banco para a plataforma, ou se esta operação já está contada noutro lado.';

  @override
  String get invfUseTotalInstead =>
      'Indicar o valor total em vez da quantidade';

  @override
  String invfAssetCurrencyChange(String ccy) {
    return 'Moeda do ativo: $ccy · alterar';
  }

  @override
  String get invfHasInitialTitle => 'Este ativo já tem uma posição inicial';

  @override
  String get invfHasInitialBody =>
      'Está carregada aqui. Ao guardar, substitui a anterior.';

  @override
  String get invfDeleteOp => 'Apagar operação';

  @override
  String invfLinkTitle(String name) {
    return 'Associar a $name';
  }

  @override
  String get invfLinkButton => 'Associar';

  @override
  String invfLinkCount(int count, String amount) {
    return 'Associar $count ($amount para a plataforma)';
  }

  @override
  String get invfLinkHint =>
      'Escolhe os movimentos do banco que foram dinheiro enviado para (ou recebido de) esta plataforma. Deixam de contar como despesa.';

  @override
  String get invfSearchTransactions => 'Pesquisar movimentos';

  @override
  String get invfNoTransactionsToLink => 'Não há movimentos por associar.';

  @override
  String get invfLooksLikeThis => ' · parece desta plataforma';

  @override
  String get invfRememberTitles => 'Lembrar estes títulos';

  @override
  String get invfRememberHint =>
      'Nas próximas importações, movimentos com o mesmo título são associados sozinhos.';

  @override
  String get invfImportTitle => 'Importar compras e vendas';

  @override
  String get invfImportIntro =>
      'Formatos: PDF (com texto), CSV e Excel (.xlsx). O ficheiro é lido no telemóvel e nunca sai daqui. Reconhece compras, vendas e dividendos; o resto (depósitos, impostos…) é ignorado.';

  @override
  String get invfChooseFile => 'Escolher ficheiro';

  @override
  String get invfChooseOtherFile => 'Escolher outro ficheiro';

  @override
  String invfFileName(String name) {
    return 'Ficheiro: $name';
  }

  @override
  String invfReadError(String error) {
    return 'Erro ao ler o ficheiro: $error';
  }

  @override
  String get invfExcelNoData => 'O ficheiro Excel não tem dados.';

  @override
  String get invfPdfNotFound =>
      'Não encontrei compras ou vendas neste PDF. Pode ser digitalizado (imagem) ou ter um formato diferente. Se a corretora permitir, exporta em CSV ou Excel.';

  @override
  String get invfNotFoundTrades =>
      'Não encontrei compras ou vendas. Indica abaixo que coluna é cada coisa.';

  @override
  String get invfNotFoundWithColumns =>
      'Não encontrei compras ou vendas com estas colunas.';

  @override
  String get invfCurrencyAndRate => 'Moeda e câmbio';

  @override
  String invfCurrencyIntro(String base) {
    return 'Linhas sem moeda indicada usam a moeda abaixo. Para moedas diferentes de $base indica o câmbio médio; podes afinar cada operação depois.';
  }

  @override
  String get invfTransactionCurrency => 'Moeda das operações';

  @override
  String invfAllInBase(String base) {
    return 'Todas as operações estão em $base.';
  }

  @override
  String get invfAssetsFound => 'Ativos encontrados';

  @override
  String get invfAssetsHint =>
      'Liga cada um a um ativo teu, cria um novo ou ignora.';

  @override
  String invfTradeCountLabel(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações',
      one: '$count operação',
      zero: '$count operações',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String get invfCreateNewAsset => '➕  Criar ativo novo';

  @override
  String get invfIgnore => 'Ignorar';

  @override
  String get invfOperations => 'Operações';

  @override
  String invfBuysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compras',
      one: '$count compra',
      zero: '$count compras',
    );
    return '$_temp0';
  }

  @override
  String invfSellsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vendas',
      one: '$count venda',
      zero: '$count vendas',
    );
    return '$_temp0';
  }

  @override
  String invfDividendsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dividendos',
      one: '$count dividendo',
      zero: '$count dividendos',
    );
    return '$_temp0';
  }

  @override
  String invfDuplicatesIgnored(int count) {
    return '$count já existentes (ignoradas)';
  }

  @override
  String get invfMissingRate => 'Falta o câmbio';

  @override
  String invfMissingRateBody(String currencies) {
    return 'Indica o câmbio de $currencies para importar essas operações.';
  }

  @override
  String get invfAllCurrencies => 'todas as moedas';

  @override
  String invfMissingQtyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações sem quantidade',
      one: '1 operação sem quantidade',
      zero: '$count operações sem quantidade',
    );
    return '$_temp0';
  }

  @override
  String get invfMissingQtyBody =>
      'O ficheiro só tem o valor pago. Escolhe a coluna que traz a quantidade e o preço (ex.: o comentário) em \"Colunas do ficheiro\".';

  @override
  String invfShowingFirst(int total) {
    return 'A mostrar as primeiras 300 de $total.';
  }

  @override
  String get invfAlreadyExists => ' · já existe';

  @override
  String invfTradeQtyPart(String qty, String price, String ccy) {
    return ' · $qty un. × $price $ccy';
  }

  @override
  String invfImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações',
      one: '1 operação',
      zero: '0 operações',
    );
    return 'Importar $_temp0';
  }

  @override
  String get invfFileColumns => 'Colunas do ficheiro';

  @override
  String get invfAutoRecognized =>
      'Reconhecidas automaticamente. Toca para ajustar.';

  @override
  String get invfIndicateColumns => 'Indica que coluna é cada coisa.';

  @override
  String get invfExcelSheet => 'Folha do Excel';

  @override
  String invfSheetRows(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linhas',
      one: '1 linha',
      zero: '$count linhas',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String get invfHeaderRow => 'Linha dos títulos das colunas';

  @override
  String get invfNoHeaders => 'Sem títulos';

  @override
  String invfHeaderRowItem(int n, String text) {
    return 'Linha $n: $text';
  }

  @override
  String get invfNotExists => '— não existe —';

  @override
  String invfColumnNumber(int n) {
    return 'Coluna $n';
  }

  @override
  String invfColumnNumberLower(int n) {
    return 'coluna $n';
  }

  @override
  String get invfFileValidation => 'Validação do ficheiro';

  @override
  String get invfRequiredNote =>
      'Preciso, no mínimo, da data, da quantidade e do preço (ou do valor total).';

  @override
  String get invfQuantityOrComment => 'Quantidade (ou o comentário que a traz)';

  @override
  String get invfPriceOrTotal => 'Preço ou Valor total';

  @override
  String invfMissingColumn(String name) {
    return 'Falta escolher a coluna: $name';
  }

  @override
  String invfValidationSummary(int dataRows, int recognized) {
    String _temp0 = intl.Intl.pluralLogic(
      dataRows,
      locale: localeName,
      other: '$dataRows linhas com dados',
      one: '1 linha com dados',
      zero: '0 linhas com dados',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recognized,
      locale: localeName,
      other: '$recognized operações reconhecidas',
      one: '1 operação reconhecida',
      zero: '0 operações reconhecidas',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String invfWithProblems(int count) {
    return ' · $count com problemas';
  }

  @override
  String invfIgnoredByUser(int count) {
    return ' · $count ignoradas (não são compras/vendas)';
  }

  @override
  String invfColumnValid(String label, int ok, int total) {
    return '$label: $ok de $total válidas';
  }

  @override
  String invfColumnValidNamed(String label, String column, int ok, int total) {
    return '$label ($column): $ok de $total válidas';
  }

  @override
  String get invfUnknownTypes => 'Tipos que não reconheci';

  @override
  String get invfUnknownTypesHint =>
      'Diz-me o que são para os importar (ou ignora).';

  @override
  String invfUnknownTypeRows(String type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linhas',
      one: '1 linha',
      zero: '$count linhas',
    );
    return '“$type” · $_temp0';
  }

  @override
  String get invfEmpty => '(vazio)';

  @override
  String get invfChoose => 'Escolher';

  @override
  String invfSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linhas não importadas',
      one: '1 linha não importada',
      zero: '$count linhas não importadas',
    );
    return '$_temp0';
  }

  @override
  String invfRowReason(int row, String reason) {
    return 'Linha $row: $reason';
  }

  @override
  String invfAndMore(int count) {
    return '… e mais $count';
  }

  @override
  String get invfAllRowsOk => 'Todas as linhas foram lidas sem problemas.';

  @override
  String invfImportedOps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações importadas',
      one: '1 operação importada',
      zero: '$count operações importadas',
    );
    return '$_temp0';
  }

  @override
  String invfImportedHoldings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ativos criados',
      one: '1 ativo criado',
      zero: '$count ativos criados',
    );
    return ' e $_temp0';
  }

  @override
  String get invfUpdatePrices => '. Atualiza os preços na Carteira.';

  @override
  String get invfNegativeCashWarning =>
      ' O dinheiro por alocar ficou negativo: associa as transferências do banco a esta plataforma ou acerta o dinheiro.';

  @override
  String get invfFieldDate => 'Data';

  @override
  String get invfFieldType => 'Tipo (compra / venda)';

  @override
  String get invfFieldName => 'Nome do ativo';

  @override
  String get invfFieldCategory => 'Categoria (ETF, ação…)';

  @override
  String get invfFieldComment => 'Comentário (ex.: OPEN BUY 0.5 @ 100)';

  @override
  String get invfFieldSymbol => 'Símbolo';

  @override
  String get invfFieldIsin => 'ISIN';

  @override
  String get invfFieldQuantity => 'Quantidade';

  @override
  String get invfFieldPrice => 'Preço por unidade';

  @override
  String get invfFieldTotal => 'Valor total';

  @override
  String get invfFieldFee => 'Comissão';

  @override
  String get invfFieldCurrency => 'Moeda';

  @override
  String get invfFieldRate =>
      'Câmbio (unidades da moeda por 1 da moeda de base)';

  @override
  String get invfKindEtf => 'ETF';

  @override
  String get invfKindStock => 'Ação';

  @override
  String get invfKindCrypto => 'Cripto';

  @override
  String get invfKindFund => 'Fundo';

  @override
  String get invfKindBond => 'Obrigação';

  @override
  String get invfKindOther => 'Outro';

  @override
  String get morMoreTitle => 'Mais';

  @override
  String get morBudgetSubtitle => 'Salário e limites por categoria';

  @override
  String get morPlanningSubtitle => 'Salário e despesas planeadas por mês';

  @override
  String get morGoalsSubtitle => 'Poupar para férias, um carro…';

  @override
  String get morAnalysisSubtitle => 'Onde gastas e onde podes poupar';

  @override
  String get morClassifyTitle => 'Classificar movimentos';

  @override
  String get morClassifySubtitle => 'Um cartão por nome';

  @override
  String get morUpdatesTitle => 'Atualizações';

  @override
  String get morUpdatesSubtitle => 'Procurar e instalar uma versão nova';

  @override
  String get morAppearanceSubtitle => 'Modo escuro e cores';

  @override
  String get morAccountsTitle => 'Contas';

  @override
  String morAccountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contas',
      one: '1 conta',
      zero: '$count contas',
    );
    return '$_temp0';
  }

  @override
  String get morRecurringTitle => 'Movimentos recorrentes';

  @override
  String morRecurringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recorrentes',
      one: '1 recorrente',
      zero: '$count recorrentes',
    );
    return '$_temp0 · salário, renda, subscrições';
  }

  @override
  String get morCategoriesTitle => 'Categorias e subcategorias';

  @override
  String morCategoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorias',
      one: '1 categoria',
      zero: '$count categorias',
    );
    return '$_temp0';
  }

  @override
  String get morGroupsTitle => 'Grupos de títulos';

  @override
  String morGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupos',
      one: '1 grupo',
      zero: '$count grupos',
    );
    return '$_temp0';
  }

  @override
  String get morRulesTitle => 'Regras memorizadas';

  @override
  String morRulesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regras',
      one: '1 regra',
      zero: '$count regras',
    );
    return '$_temp0';
  }

  @override
  String get morImportTitle => 'Importar extrato';

  @override
  String get morImportSubtitle => 'PDF, CSV ou Excel';

  @override
  String get morImportsHistoryTitle => 'Histórico de importações';

  @override
  String get morExportTitle => 'Exportar movimentos (CSV)';

  @override
  String get morBackupTitle => 'Cópia de segurança';

  @override
  String get morBackupSubtitle =>
      'Guardar ou restaurar no Google Drive ou num ficheiro';

  @override
  String get morWipeTransactionsTitle => 'Apagar todos os movimentos';

  @override
  String get morWipeTransactionsConfirm =>
      'Apagar TODOS os movimentos, regras e salários? As categorias mantêm-se. Não é possível desfazer.';

  @override
  String get morWipeAllTitle => 'Apagar tudo, incluindo categorias';

  @override
  String get morWipeAllConfirm =>
      'Apagar TUDO: movimentos, categorias, orçamentos, regras, salários e investimentos? Não é possível desfazer.';

  @override
  String get morPrivacyNote =>
      'Todos os dados ficam guardados apenas neste telemóvel. A internet só é usada se carregares em “Atualizar preços” na Carteira (é enviado apenas o símbolo do ativo).';

  @override
  String get morImportsTitle => 'Importações';

  @override
  String get morNoImports => 'Ainda sem importações.';

  @override
  String get morUndoImport => 'Desfazer importação';

  @override
  String morImportItemSubtitle(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date · $count movimentos',
      one: '$date · 1 movimento',
      zero: '$date · $count movimentos',
    );
    return '$_temp0';
  }

  @override
  String morRemoveImportQuestion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remover os $count movimentos desta importação?',
      one: 'Remover o movimento desta importação?',
      zero: 'Remover os $count movimentos desta importação?',
    );
    return '$_temp0';
  }

  @override
  String get morCategoriesScreenTitle => 'Categorias';

  @override
  String get morNewCategory => 'Categoria';

  @override
  String get morIncomeKind => 'Rendimento';

  @override
  String get morInvestmentKind => 'Investimento';

  @override
  String get morBothKinds => 'Despesas e receitas';

  @override
  String get morFromStart => 'desde sempre';

  @override
  String morFromMonth(String month) {
    return 'de $month';
  }

  @override
  String get morOpenEnded => 'em diante';

  @override
  String morToMonth(String month) {
    return 'a $month';
  }

  @override
  String get morEnded => 'terminada';

  @override
  String get morFuture => 'futura';

  @override
  String morTxnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mov.',
      one: '1 mov.',
      zero: '$count mov.',
    );
    return '$_temp0';
  }

  @override
  String morMandatoryPeriods(int count) {
    return 'Obrigatória em $count período(s)';
  }

  @override
  String get morNewSubcategory => 'Nova subcategoria';

  @override
  String get morDuplicateNextYear => 'Duplicar para o ano seguinte';

  @override
  String get morReactivate => 'Reativar';

  @override
  String get morArchive => 'Arquivar';

  @override
  String morCreatedCategory(String name) {
    return 'Criada “$name”.';
  }

  @override
  String morDeleteCategoryQuestion(String name, int count, String subs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count movimentos ficam',
      one: 'O movimento fica',
      zero: 'Os $count movimentos ficam',
    );
    return 'Apagar “$name”? $_temp0 sem categoria$subs.';
  }

  @override
  String get morSubcategoriesDeleted => ' e as subcategorias são apagadas';

  @override
  String get morThemeTitle => 'Tema';

  @override
  String get morThemeSystem => 'Sistema';

  @override
  String get morThemeLight => 'Claro';

  @override
  String get morThemeDark => 'Escuro';

  @override
  String get morAmoledTitle => 'Preto total (AMOLED)';

  @override
  String get morAmoledSubtitle => 'No modo escuro, fundo totalmente preto';

  @override
  String get morBaseCurrencyTitle => 'Moeda de base';

  @override
  String get morBaseCurrencyHint =>
      'É a moeda dos teus movimentos, orçamentos e carteira. Os ativos noutras moedas (USD, GBP…) são convertidos para esta.';

  @override
  String morBaseCurrencyChanged(String code) {
    return 'Moeda de base: $code. Os valores já registados não são convertidos; atualiza os preços da Carteira.';
  }

  @override
  String get morMainColor => 'Cor principal';

  @override
  String get morMainColorHint =>
      'Define a cor da barra de navegação, botões e gráficos.';

  @override
  String get morIncomeColor => 'Cor das receitas';

  @override
  String get morExpenseColor => 'Cor das despesas';

  @override
  String get morPreview => 'Pré-visualização';

  @override
  String get morSamplePlace => 'Supermercado';

  @override
  String get morSampleCategory => 'Categoria › Subcategoria';

  @override
  String get morSampleSalary => 'Salário';

  @override
  String get morResetAppearance => 'Repor aparência original';

  @override
  String get morEmojiHint =>
      'Cada categoria e subcategoria tem um emoji próprio, que escolhes ao criar ou editar.';

  @override
  String get morBackupDescription =>
      'Guarda todos os teus dados (movimentos, categorias, orçamentos, carteira…) num ficheiro. Não inclui as fotos dos recibos.';

  @override
  String get morBackupDriveHint =>
      'Não precisas de ligar nenhuma conta na app: ao guardar, escolhe “Google Drive” (ou outra pasta) no ecrã do Android. Para restaurar, escolhe o ficheiro, do telemóvel ou do Drive.';

  @override
  String morLastBackup(String date, String ago) {
    return 'Última cópia guardada: $date ($ago)';
  }

  @override
  String get morSaveBackup => 'Guardar cópia (Google Drive ou ficheiro)';

  @override
  String get morRestoreFromFile => 'Restaurar de um ficheiro';

  @override
  String get morBackupSaved => 'Cópia guardada.';

  @override
  String get morDataRestored => 'Dados restaurados.';

  @override
  String morRestoreConfirm(String name) {
    return 'Isto substitui TODOS os dados deste telemóvel pelos da cópia “$name”. Não dá para desfazer. Continuar?';
  }

  @override
  String get morRestore => 'Restaurar';

  @override
  String morCouldNotFinish(String error) {
    return 'Não consegui concluir: $error';
  }

  @override
  String get morInstalledVersion => 'Versão instalada';

  @override
  String get morUpdateDescription =>
      'Procura no GitHub se há uma versão nova e instala-a por cima desta, sem perderes dados. A internet só é usada quando carregas no botão.';

  @override
  String get morChecking => 'A procurar…';

  @override
  String get morCheckUpdates => 'Procurar atualizações';

  @override
  String morNewVersion(String version) {
    return 'Há uma versão nova: $version';
  }

  @override
  String get morUpToDate => 'Já tens a versão mais recente';

  @override
  String get morDownloadInstall => 'Descarregar e instalar';

  @override
  String morDownloadInstallSize(String mb) {
    return 'Descarregar e instalar ($mb MB)';
  }

  @override
  String morDownloadingPercent(String percent) {
    return 'A descarregar… $percent%';
  }

  @override
  String get morDownloading => 'A descarregar…';

  @override
  String get morOpenReleasePage => 'Abrir a página da versão';

  @override
  String get morWhatsNew => 'O que mudou';

  @override
  String morInstallerError(String message) {
    return 'Não consegui abrir o instalador ($message). Se o Android pediu permissão para instalar apps desta origem, ativa-a e carrega outra vez em \"Descarregar e instalar\".';
  }

  @override
  String get morUpdateAvailableTitle => 'Atualização disponível';

  @override
  String morUpdateAvailableBody(String version) {
    return 'Finanças $version já está disponível. Abre Mais › Atualizações para instalar.';
  }

  @override
  String get morUpdateChannelName => 'Atualizações';

  @override
  String get morUpdateChannelDescription => 'Aviso quando sai uma versão nova';

  @override
  String morRecurringNotifBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimentos recorrentes registados',
      one: '1 movimento recorrente registado',
      zero: '$count movimentos recorrentes registados',
    );
    return '$_temp0';
  }

  @override
  String get morAllocationTitle => 'Entrega de investimento';

  @override
  String morAllocationBody(String account, String deliveries, String details) {
    return '$account$deliveries: $details';
  }

  @override
  String morDeliveriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count entregas)',
      one: '(1 entrega)',
      zero: '($count entregas)',
    );
    return '$_temp0';
  }

  @override
  String morUndistributed(String amount) {
    return '$amount por distribuir';
  }

  @override
  String get morAlertsChannelName => 'Alertas';

  @override
  String get morAlertsChannelDescription =>
      'Movimentos recorrentes e entregas de investimento';

  @override
  String get morAssetFallback => 'Ativo';

  @override
  String get morNavMonth => 'Mês';

  @override
  String get morNavPortfolio => 'Carteira';
}
