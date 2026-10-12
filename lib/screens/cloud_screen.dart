import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../cloud/cloud_provider.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/form_kit.dart';
import 'transactions_screen.dart' show confirm;

/// Guardar e restaurar uma cópia dos dados no OneDrive, numa pasta privada da app.
class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});
  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  bool busy = false;
  CloudBackupInfo? remote;
  String? error;
  late final TextEditingController clientId;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    clientId = TextEditingController(text: s.oneDriveClientId);
    if (s.cloud.account != null) _refresh(s.cloud);
  }

  @override
  void dispose() {
    clientId.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await f();
    } on CloudException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Erro inesperado: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _refresh(CloudProvider p) async {
    await _run(() async {
      remote = await p.latest();
    });
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final p = s.cloud;
    final acc = p.account;
    return Scaffold(
      appBar: AppBar(title: const Text('Cópia no OneDrive')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          FormCard(
            children: [
              Text(
                'Guarda uma cópia de todos os teus dados (movimentos, categorias, orçamentos, carteira…) numa pasta privada da app no teu OneDrive. Não inclui as fotos dos recibos.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'A internet só é usada quando carregas nos botões.',
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
          const SizedBox(height: 14),
          FormCard(
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      acc == null ? 'Conta Microsoft' : acc,
                      style: tt.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (acc == null)
                Text(
                  'Sem conta ligada. Liga uma conta pessoal ou de trabalho da Microsoft.',
                  style: tt.bodyMedium,
                )
              else
                Text(
                  remote == null
                      ? 'Ainda sem cópia no OneDrive.'
                      : 'Cópia no OneDrive: ${fmtDate(remote!.modified)} · ${(remote!.size / 1024).toStringAsFixed(0)} KB',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              const SizedBox(height: 10),
              if (acc == null)
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => _run(() async {
                          final name = await p.signIn();
                          _snack('Ligado a $name');
                          remote = await p.latest();
                          if (mounted) setState(() {});
                        }),
                  icon: const Icon(Icons.login),
                  label: const Text('Ligar conta Microsoft'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => _run(() async {
                              if (remote != null &&
                                  !await confirm(
                                    context,
                                    'Já existe uma cópia de ${fmtDate(remote!.modified)}. Substituir pela versão atual?',
                                    ok: 'Substituir',
                                  ))
                                return;
                              await s.backupToCloud(p);
                              remote = await p.latest();
                              _snack('Cópia guardada no OneDrive.');
                            }),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Guardar cópia agora'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy || remote == null
                          ? null
                          : () => _run(() async {
                              if (!await confirm(
                                context,
                                'Isto substitui TODOS os dados deste telemóvel pelos da cópia de ${fmtDate(remote!.modified)}. Não dá para desfazer. Continuar?',
                                ok: 'Restaurar',
                              ))
                                return;
                              final d = await s.restoreFromCloud(p);
                              _snack(
                                'Dados restaurados da cópia de ${fmtDate(d)}.',
                              );
                            }),
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text('Restaurar'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _run(() async {
                              await p.signOut();
                              remote = null;
                            }),
                      child: const Text('Terminar sessão'),
                    ),
                  ],
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error!, style: TextStyle(color: cs.error)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FormCard(
            children: [
              Text('Configuração (uma vez)', style: tt.titleMedium),
              const SizedBox(height: 6),
              Text(
                s.oneDriveClientId.isEmpty
                    ? 'Falta o ID da aplicação. Cria o registo no Azure e cola o ID aqui.'
                    : 'ID da aplicação guardado.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clientId,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'ID da aplicação (cliente)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Guardar',
                    onPressed: () {
                      s.setOneDriveClientId(clientId.text);
                      _snack('ID guardado');
                    },
                  ),
                ),
                onSubmitted: (v) => s.setOneDriveClientId(v),
              ),
              Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      'Como criar o registo no Azure',
                      style: tt.titleSmall,
                    ),
                    children: [
                      _step(
                        tt,
                        '1.',
                        'Abre portal.azure.com com a tua conta Microsoft e vai a “Microsoft Entra ID › Registos de aplicações › Novo registo”.',
                      ),
                      _step(
                        tt,
                        '2.',
                        'Nome: Finanças. Em “Tipos de conta suportados” escolhe “Contas em qualquer diretório organizacional e contas pessoais da Microsoft”.',
                      ),
                      _step(
                        tt,
                        '3.',
                        'Em “Redirecionamento”, escolhe a plataforma “Clientes públicos/nativos (móvel e ambiente de trabalho)” e coloca este URI:',
                      ),
                      _copy(context, tt, 'pt.financas.financas:/oauth'),
                      _step(
                        tt,
                        '4.',
                        'Depois de criar, em “Permissões de API › Adicionar uma permissão › Microsoft Graph › Delegadas”, adiciona: Files.ReadWrite.AppFolder, offline_access e User.Read.',
                      ),
                      _step(
                        tt,
                        '5.',
                        'Na página de visão geral copia o “ID da aplicação (cliente)” e cola-o no campo acima.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _step(TextTheme tt, String n, String t) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text('$n  $t', style: tt.bodyMedium),
  );

  Widget _copy(BuildContext context, TextTheme tt, String value) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Expanded(
          child: SelectableText(
            value,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Copiar',
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Copiado')));
          },
        ),
      ],
    ),
  );
}
