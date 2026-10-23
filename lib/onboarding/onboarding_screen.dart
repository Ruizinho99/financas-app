import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../util/format.dart';

/// Definição que marca a primeira utilização como concluída (ou saltada).
const kOnboardingKey = 'onboarding_done';

/// Decide, ao abrir a app, se mostra a primeira utilização: só numa instalação nova (sem contas,
/// sem movimentos e sem [kOnboardingKey]). Quem já tem dados marca-a como feita sem a mostrar,
/// para que nunca apareça depois de um apagamento.
bool verificarOnboarding(AppState s) {
  if (s.db.setting(kOnboardingKey) != null) return false;
  if (s.accounts.isNotEmpty || s.transactions.isNotEmpty) {
    s.db.putSetting(kOnboardingKey, '1');
    return false;
  }
  return true;
}

/// Entrada da app: mostra a primeira utilização numa instalação nova; senão, mostra [child].
class OnboardingGate extends StatefulWidget {
  final Widget child;
  const OnboardingGate({super.key, required this.child});
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  // Decidido uma vez ao arrancar: ao criar a primeira conta o ecrã não pode desaparecer a meio.
  bool _mostrar = false;

  @override
  void initState() {
    super.initState();
    _mostrar = verificarOnboarding(context.read<AppState>());
  }

  @override
  Widget build(BuildContext context) {
    if (!_mostrar) return widget.child;
    return OnboardingScreen(onDone: () => setState(() => _mostrar = false));
  }
}

/// Passos: boas-vindas, primeira conta, salário (opcional) e fim.
/// "Saltar" está sempre disponível e não cria nada.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  final _nomeConta = TextEditingController();
  final _saldo = TextEditingController();
  final _salario = TextEditingController();
  int _passo = 0;
  String? _erroSaldo, _erroSalario;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _page.dispose();
    _nomeConta.dispose();
    _saldo.dispose();
    _salario.dispose();
    super.dispose();
  }

  static const _numPassos = 4;

  /// Títulos dos passos visíveis, pela ordem em que aparecem.
  List<String> _titulos(AppLocalizations l) => [
    l.frmObWelcome,
    l.frmObFirstAccount,
    l.frmObSalary,
    l.frmObDone,
  ];

  bool get _ultimo => _passo == _numPassos - 1;

  void _ir(int p) {
    setState(() => _passo = p);
    _page.animateToPage(
      p,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Valida o passo atual antes de avançar. Devolve falso se houver erro.
  bool _validar() {
    final l = AppLocalizations.of(context)!;
    if (_passo == 1) {
      final s = _saldo.text.trim();
      _erroSaldo = s.isEmpty || parseCents(s) != null
          ? null
          : l.frmObEnterAmount1250;
    } else if (_passo == 2) {
      final s = _salario.text.trim();
      _erroSalario = s.isEmpty || parseCents(s) != null
          ? null
          : l.frmObEnterAmount1500;
    }
    setState(() {});
    return (_erroSaldo ?? _erroSalario) == null;
  }

  void _seguinte() {
    if (!_validar()) return;
    if (_ultimo) {
      _concluir();
    } else {
      _ir(_passo + 1);
    }
  }

  /// Cria a conta e o salário, se preenchidos; depois marca a utilização como feita.
  void _concluir() {
    final s = context.read<AppState>();
    final nome = _nomeConta.text.trim();
    if (nome.isNotEmpty) {
      s.addAccount(nome, openingCents: parseCents(_saldo.text.trim()) ?? 0);
    }
    final salario = parseCents(_salario.text.trim()) ?? 0;
    if (salario > 0) s.setDefaultSalary(salario);
    _terminar();
  }

  void _terminar() {
    context.read<AppState>().db.putSetting(kOnboardingKey, '1');
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final titulos = _titulos(l);

    final paginas = <Widget>[
      _Pagina(
        icone: Icons.savings_outlined,
        titulo: l.frmObWelcomeTitle,
        texto: l.frmObWelcomeText,
      ),
      _Pagina(
        icone: Icons.account_balance_wallet_outlined,
        titulo: l.frmObAccountTitle,
        texto: l.frmObAccountText,
        filhos: [
          TextField(
            controller: _nomeConta,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.frmObAccountName,
              hintText: l.frmAccountNameHint,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _saldo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _erroSaldo = null),
            decoration: InputDecoration(
              labelText: l.frmOpeningBalanceCurrency(baseSym),
              hintText: zeroHint,
              errorText: _erroSaldo,
            ),
          ),
        ],
      ),
      _Pagina(
        icone: Icons.payments_outlined,
        titulo: l.frmObSalaryTitle,
        texto: l.frmObSalaryText,
        filhos: [
          TextField(
            controller: _salario,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _erroSalario = null),
            decoration: InputDecoration(
              labelText: l.frmObSalaryField(baseSym),
              hintText: zeroHint,
              errorText: _erroSalario,
            ),
          ),
        ],
      ),
      _Pagina(
        icone: Icons.check_circle_outline,
        titulo: l.frmObReadyTitle,
        texto: l.frmObReadyText,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(titulos[_passo], style: tt.titleMedium),
        actions: [
          TextButton(onPressed: _terminar, child: Text(l.onboardingSkip)),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_passo + 1) / titulos.length,
            minHeight: 3,
            backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final p in paginas)
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: p,
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_passo > 0)
                    OutlinedButton(
                      onPressed: () {
                        _erroSaldo = _erroSalario = null;
                        _ir(_passo - 1);
                      },
                      child: Text(l.frmBack),
                    ),
                  if (_passo > 0) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _seguinte,
                      child: Text(
                        _passo == 0
                            ? l.onboardingStart
                            : (_ultimo ? l.frmFinish : l.frmNext),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagina extends StatelessWidget {
  final IconData icone;
  final String titulo, texto;
  final List<Widget> filhos;
  const _Pagina({
    required this.icone,
    required this.titulo,
    required this.texto,
    this.filhos = const [],
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: cs.primaryContainer,
            child: Icon(icone, size: 36, color: cs.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 20),
        Text(titulo, style: tt.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          texto,
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        if (filhos.isNotEmpty) ...[const SizedBox(height: 24), ...filhos],
      ],
    );
  }
}
