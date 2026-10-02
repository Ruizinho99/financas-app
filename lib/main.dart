import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'db/database.dart';
import 'screens/analysis_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/classify_screen.dart';
import 'screens/more_screen.dart';
import 'screens/transactions_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_PT');
  final db = await Db.open();
  runApp(ChangeNotifierProvider(create: (_) => AppState(db), child: const FinancasApp()));
}

class FinancasApp extends StatelessWidget {
  const FinancasApp({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    ThemeData theme(Brightness b) {
      var scheme = ColorScheme.fromSeed(seedColor: Color(st.seedColor), brightness: b);
      final black = b == Brightness.dark && st.amoled;
      if (black) scheme = scheme.copyWith(surface: Colors.black, surfaceContainerLowest: Colors.black, surfaceContainerLow: const Color(0xFF0A0A0A), surfaceContainer: const Color(0xFF101010));
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: black ? Colors.black : null,
        cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6)),
      );
    }

    return MaterialApp(
      title: 'Finanças',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: st.themeMode,
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
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
  static const pages = <Widget>[TransactionsScreen(), ClassifyScreen(), BudgetScreen(), AnalysisScreen(), MoreScreen()];

  @override
  Widget build(BuildContext context) {
    final pending = context.select<AppState, int>((s) => s.transactions.where((t) => t.categoryId == null).length);
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Movimentos'),
          NavigationDestination(
            icon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.style_outlined)),
            selectedIcon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.style)),
            label: 'Classificar',
          ),
          const NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Orçamento'),
          const NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Análise'),
          const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}
