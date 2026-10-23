import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
      error = mounted
          ? AppLocalizations.of(context)!.morCouldNotFinish('$e')
          : '$e';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.morBackupSaved)),
      );
  });

  Future<void> _restore(AppState s) => _run(() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return; // cancelado
    final f = files.first;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    if (!await confirm(
      context,
      AppLocalizations.of(context)!.morRestoreConfirm(f.name),
      ok: AppLocalizations.of(context)!.morRestore,
    ))
      return;
    await s.restoreBackup(bytes);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.morDataRestored)),
      );
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.morBackupTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          FormCard(
            children: [
              Text(l.morBackupDescription, style: tt.bodyMedium),
              const SizedBox(height: 10),
              Text(
                l.morBackupDriveHint,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (s.lastBackup != null) ...[
                const SizedBox(height: 10),
                Text(
                  l.morLastBackup(
                    fmtDate(s.lastBackup!),
                    fmtAgo(s.lastBackup!),
                  ),
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: busy ? null : () => _save(s),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(l.morSaveBackup),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _restore(s),
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(l.morRestoreFromFile),
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
