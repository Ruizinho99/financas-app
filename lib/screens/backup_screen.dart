import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/form_kit.dart';
import 'transactions_screen.dart' show confirm;

/// Cópia de segurança sem contas nem configuração: o Android mostra o seletor de ficheiros,
/// onde escolhes o Google Drive (ou o telemóvel). Para restaurar, escolhes o ficheiro de onde está.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;
  String? error;

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await f();
    } on FormatException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Não consegui concluir: $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _save(AppState s) => _run(() async {
    final name = 'financas-${isoDate(DateTime.now())}.db';
    final path = await FilePicker.saveFile(
      fileName: name,
      bytes: s.backupBytes(),
    );
    if (path == null) return; // cancelado
    s.markBackup();
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cópia guardada.')));
  });

  Future<void> _restore(AppState s) => _run(() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return; // cancelado
    final f = files.first;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    if (!await confirm(
      context,
      'Isto substitui TODOS os dados deste telemóvel pelos da cópia “${f.name}”. Não dá para desfazer. Continuar?',
      ok: 'Restaurar',
    ))
      return;
    await s.restoreBackup(bytes);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dados restaurados.')));
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cópia de segurança')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          FormCard(
            children: [
              Text(
                'Guarda todos os teus dados (movimentos, categorias, orçamentos, carteira…) num ficheiro. Não inclui as fotos dos recibos.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Não precisas de ligar nenhuma conta na app: ao guardar, escolhe “Google Drive” (ou outra pasta) no ecrã do Android. Para restaurar, escolhe o ficheiro, do telemóvel ou do Drive.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (s.lastBackup != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Última cópia guardada: ${fmtDate(s.lastBackup!)} (${fmtAgo(s.lastBackup!)})',
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: busy ? null : () => _save(s),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Guardar cópia (Google Drive ou ficheiro)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _restore(s),
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Restaurar de um ficheiro'),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error!, style: TextStyle(color: cs.error)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
