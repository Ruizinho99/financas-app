import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../cloud/cloud_provider.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/form_kit.dart';
import 'transactions_screen.dart' show confirm;

/// Pacote e impressão digital do certificado com que as versões publicadas são assinadas.
const kAppPackage = 'pt.financas.financas';
const kAppSha1 = '81:96:32:0F:EB:FE:B2:B2:57:E8:49:94:BF:EF:94:A1:B1:A1:83:3D';

/// Ligar contas (Google, Apple…) e guardar/restaurar uma cópia dos dados nelas.
class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});
  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  final Map<String, bool> busy = {};
  final Map<String, CloudBackupInfo?> remote = {};
  final Map<String, String> errors = {};
  late final TextEditingController clientId;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    clientId = TextEditingController(text: s.googleClientId);
    for (final p in s.cloud.where((p) => p.available)) {
      p.restoreSession().then((email) async {
        if (email != null && mounted) {
          setState(() {});
          _refreshRemote(p);
        }
      });
    }
  }

  @override
  void dispose() {
    clientId.dispose();
    super.dispose();
  }

  Future<void> _run(CloudProvider p, Future<void> Function() f) async {
    setState(() {
      busy[p.id] = true;
      errors.remove(p.id);
    });
    try {
      await f();
    } on CloudException catch (e) {
      errors[p.id] = e.message;
    } catch (e) {
      errors[p.id] = 'Erro inesperado: $e';
    }
    if (mounted) setState(() => busy[p.id] = false);
  }

  Future<void> _refreshRemote(CloudProvider p) async {
    try {
      final i = await p.latest();
      if (mounted) setState(() => remote[p.id] = i);
    } on CloudException catch (e) {
      if (mounted) setState(() => errors[p.id] = e.message);
    }
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Conta e cópia na nuvem')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          FormCard(
            children: [
              Text(
                'Guarda uma cópia de todos os teus dados (movimentos, categorias, orçamentos, carteira…) na tua conta. Fica numa pasta privada que só esta app vê e não aparece no teu Drive. Não inclui as fotos dos recibos.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'A internet só é usada quando carregas nos botões desta página.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (s.lastCloudBackup != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Última cópia guardada: ${fmtDate(s.lastCloudBackup!)} (${fmtAgo(s.lastCloudBackup!)})',
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          for (final p in s.cloud) ...[
            const SizedBox(height: 14),
            _providerCard(context, s, p),
          ],
          const SizedBox(height: 14),
          _setupCard(context, s),
        ],
      ),
    );
  }

  Widget _providerCard(BuildContext context, AppState s, CloudProvider p) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isBusy = busy[p.id] == true;
    final acc = p.account;
    final r = remote[p.id];
    return FormCard(
      children: [
        Row(
          children: [
            Icon(
              p.id == 'google'
                  ? Icons.cloud_outlined
                  : Icons.cloud_circle_outlined,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(p.label, style: tt.titleMedium)),
            if (isBusy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (!p.available)
          Text(
            p.unavailableReason,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          )
        else if (acc == null) ...[
          Text('Sem ${p.accountHint} ligada.', style: tt.bodyMedium),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isBusy
                ? null
                : () => _run(p, () async {
                    final email = await p.signIn();
                    _snack('Ligado a $email');
                    await _refreshRemote(p);
                  }),
            icon: const Icon(Icons.login),
            label: Text('Ligar ${p.accountHint}'),
          ),
        ] else ...[
          Text(acc, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            r == null
                ? 'Ainda sem cópia nesta conta.'
                : 'Cópia na nuvem: ${fmtDate(r.modified)} · ${(r.size / 1024).toStringAsFixed(0)} KB',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: isBusy
                    ? null
                    : () async {
                        if (r != null &&
                            !await confirm(
                              context,
                              'Já existe uma cópia de ${fmtDate(r.modified)}. Substituir pela versão atual?',
                              ok: 'Substituir',
                            ))
                          return;
                        await _run(p, () async {
                          await s.backupToCloud(p);
                          await _refreshRemote(p);
                          _snack('Cópia guardada.');
                        });
                      },
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Guardar cópia agora'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy || r == null
                    ? null
                    : () async {
                        if (!await confirm(
                          context,
                          'Isto substitui TODOS os dados deste telemóvel pelos da cópia de ${fmtDate(r.modified)}. Não dá para desfazer. Continuar?',
                          ok: 'Restaurar',
                        ))
                          return;
                        await _run(p, () async {
                          final d = await s.restoreFromCloud(p);
                          _snack(
                            'Dados restaurados da cópia de ${fmtDate(d)}.',
                          );
                        });
                      },
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('Restaurar'),
              ),
              TextButton(
                onPressed: isBusy
                    ? null
                    : () => _run(p, () async {
                        await p.signOut();
                        remote.remove(p.id);
                      }),
                child: const Text('Terminar sessão'),
              ),
            ],
          ),
        ],
        if (errors[p.id] != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(errors[p.id]!, style: TextStyle(color: cs.error)),
          ),
      ],
    );
  }

  Widget _setupCard(BuildContext context, AppState s) {
    final tt = Theme.of(context).textTheme;
    Widget step(String n, String t) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text('$n  $t', style: tt.bodyMedium),
    );
    Widget copy(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(child: Text('$label\n$value', style: tt.bodySmall)),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              _snack('Copiado');
            },
          ),
        ],
      ),
    );
    return FormCard(
      children: [
        Material(
          type: MaterialType.transparency,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Configurar a ligação Google (uma vez)',
                style: tt.titleMedium,
              ),
              subtitle: Text(
                s.googleClientId.isEmpty
                    ? 'Falta o ID de cliente'
                    : 'ID de cliente guardado',
                style: tt.bodySmall,
              ),
              initiallyExpanded: s.googleClientId.isEmpty,
              children: [
                Text(
                  'A Google exige que cada app tenha um projeto próprio. É grátis e demora uns minutos:',
                  style: tt.bodyMedium,
                ),
                step(
                  '1.',
                  'Em console.cloud.google.com cria um projeto e ativa a “Google Drive API”.',
                ),
                step(
                  '2.',
                  'Em “Ecrã de consentimento OAuth” escolhe Externo, preenche o nome da app e acrescenta o teu email como utilizador de teste.',
                ),
                step(
                  '3.',
                  'Em “Credenciais” cria um ID de cliente OAuth do tipo Android com este pacote e esta impressão digital:',
                ),
                copy('Nome do pacote', kAppPackage),
                copy('Impressão digital SHA-1', kAppSha1),
                step(
                  '4.',
                  'Cria outro ID de cliente OAuth do tipo “Aplicação Web” e cola aqui o ID dele (termina em .apps.googleusercontent.com):',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: clientId,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'ID de cliente Web',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Guardar',
                      onPressed: () {
                        s.setGoogleClientId(clientId.text);
                        _snack('ID guardado');
                      },
                    ),
                  ),
                  onSubmitted: (v) => s.setGoogleClientId(v),
                ),
                const SizedBox(height: 8),
                Text(
                  'O ID não é uma palavra-passe: só diz à Google qual é a app. Fica apenas neste telemóvel.',
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
