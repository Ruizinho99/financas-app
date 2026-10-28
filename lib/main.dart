import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'db/database.dart';
import 'l10n/app_localizations.dart';
import 'invest/invest_screen.dart';
import 'notify/notifications.dart';
import 'onboarding/onboarding_screen.dart';
import 'screens/month_screen.dart';
import 'screens/more_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/update_screen.dart';
import 'util/format.dart';
import 'state/app_state.dart';
import 'update/update_checker.dart';
import 'update/update_service.dart';
import 'util/receipts.dart';

Future<void> _checkUpdates(Db db) async {
  try {
    final checker = UpdateChecker(
      db: db,
      service: UpdateService(),
      currentVersion: await UpdateChecker.installedVersion(),
      notify: (tag) async => pendingUpdate.value = tag,
    );
    await checker.check();
  } catch (_) {
    // sem internet ou sem permissão: a app abre normalmente
  }
}

/// Ao abrir: cria os movimentos recorrentes em falta e avisa do que entrou. Nunca bloqueia nem falha a app.
Future<void> _arranque(AppState s) async {
  var criados = 0;
  try {
    criados = s.generateRecurring();
  } catch (_) {}
  try {
    await notifyStartup(s, recurringCreated: criados);
  } catch (_) {
    // sem permissão de notificações: a app abre normalmente
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_PT');
  await initializeDateFormatting('en');
  await Receipts.init();
  final db = await Db.open();
  // ao abrir: verifica se há versão nova (no máximo uma vez por dia) e mostra um popup na app
  unawaited(_checkUpdates(db));
  final state = AppState(db);
  unawaited(_arranque(state));
  runApp(
    ChangeNotifierProvider(create: (_) => state, child: const FinancasApp()),
  );
}

class FinancasApp extends StatelessWidget {
  const FinancasApp({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    ThemeData theme(Brightness b) {
      var scheme = ColorScheme.fromSeed(
        seedColor: Color(st.seedColor),
        brightness: b,
      );
      final black = b == Brightness.dark && st.amoled;
      if (black)
        scheme = scheme.copyWith(
          surface: Colors.black,
          surfaceContainerLowest: Colors.black,
          surfaceContainerLow: const Color(0xFF0A0A0A),
          surfaceContainer: const Color(0xFF101010),
        );
      final outline = OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      );
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: black ? Colors.black : null,
        cardTheme: CardThemeData(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: outline,
          enabledBorder: outline,
          disabledBorder: outline.copyWith(
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: outline.copyWith(
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          errorBorder: outline.copyWith(
            borderSide: BorderSide(color: scheme.error),
          ),
          focusedErrorBorder: outline.copyWith(
            borderSide: BorderSide(color: scheme.error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          selectedColor: scheme.primaryContainer,
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 48),
            shape: const StadiumBorder(),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, toolbarHeight: 64),
        // 6 separadores: etiquetas mais pequenas para "Movimentos" e "Classificar" caberem numa só linha em ecrãs de 360 dp
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          labelPadding: EdgeInsets.zero,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          minVerticalPadding: 8,
        ),
        dividerTheme: const DividerThemeData(space: 24),
      );
    }

    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appName,
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: st.themeMode,
      // 'system' segue o telemóvel; se não for português nem inglês, usa português
      locale: switch (st.appLanguage) {
        'pt' => const Locale('pt', 'PT'),
        'en' => const Locale('en'),
        _ => null,
      },
      supportedLocales: const [Locale('pt', 'PT'), Locale('en')],
      // os formatos de datas e valores seguem o idioma escolhido
      builder: (context, child) {
        setFormatLocale(Localizations.localeOf(context).languageCode);
        return child!;
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const OnboardingGate(child: HomeShell()),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    pendingUpdate.addListener(_offerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerUpdate());
  }

  @override
  void dispose() {
    pendingUpdate.removeListener(_offerUpdate);
    super.dispose();
  }

  /// Popup "há uma versão nova" ao abrir a app (uma vez por versão).
  Future<void> _offerUpdate() async {
    final tag = pendingUpdate.value;
    if (tag == null || !mounted) return;
    pendingUpdate.value = null;
    final l = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.system_update),
        title: Text(l.updPopupTitle),
        content: Text(l.updPopupBody(tag)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.updPopupLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.updPopupNow),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpdateScreen()),
      );
    }
  }

  static const pages = <Widget>[
    MonthScreen(),
    TransactionsScreen(),
    InvestScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = context.select<AppState, int>(
      (s) => s.transactions
          .where((t) => t.categoryId == null && !t.isTransfer)
          .length,
    );
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.calendar_month_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.calendar_month),
            ),
            label: l.morNavMonth,
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: l.transactions,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: l.morNavPortfolio,
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: l.morMoreTitle,
          ),
        ],
      ),
    );
  }
}
