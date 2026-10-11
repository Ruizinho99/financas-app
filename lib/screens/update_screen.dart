import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../update/update_service.dart';
import '../widgets/form_kit.dart';

/// Procura uma versão nova no GitHub e instala-a. Só usa a internet quando carregas em "Procurar".
class UpdateScreen extends StatefulWidget {
  final UpdateService? service;
  final String? currentVersion; // para testes
  const UpdateScreen({super.key, this.service, this.currentVersion});
  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  late final UpdateService service = widget.service ?? UpdateService();
  String current = '';
  ReleaseInfo? release;
  bool checking = false, downloading = false;
  double progress = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.currentVersion != null) {
      current = widget.currentVersion!;
    } else {
      PackageInfo.fromPlatform().then((p) {
        if (mounted) setState(() => current = p.version);
      });
    }
  }

  bool get newer =>
      release != null && UpdateService.isNewer(release!.version, current);

  Future<void> _check() async {
    setState(() {
      checking = true;
      error = null;
      release = null;
    });
    try {
      final r = await service.latest();
      if (mounted) setState(() => release = r);
    } on UpdateException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
    if (mounted) setState(() => checking = false);
  }

  Future<void> _install() async {
    final r = release!;
    setState(() {
      downloading = true;
      progress = 0;
      error = null;
    });
    try {
      final f = await service.download(
        r,
        onProgress: (p) {
          if (mounted) setState(() => progress = p);
        },
      );
      final res = await OpenFilex.open(
        f.path,
        type: 'application/vnd.android.package-archive',
      );
      if (mounted && res.type != ResultType.done) {
        setState(
          () => error =
              'Não consegui abrir o instalador (${res.message}). Se o Android pediu permissão para instalar apps desta origem, ativa-a e carrega outra vez em "Descarregar e instalar".',
        );
      }
    } on UpdateException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
    if (mounted) setState(() => downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final r = release;
    return Scaffold(
      appBar: AppBar(title: const Text('Atualizações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          FormCard(
            children: [
              Text(
                'Versão instalada',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                current.isEmpty ? '…' : current,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Procura no GitHub se há uma versão nova e instala-a por cima desta, sem perderes dados. A internet só é usada quando carregas no botão.',
                style: tt.bodySmall,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: checking || downloading ? null : _check,
                icon: checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt),
                label: Text(checking ? 'A procurar…' : 'Procurar atualizações'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error!, style: TextStyle(color: cs.error)),
                ),
            ],
          ),
          if (r != null) ...[
            const SizedBox(height: 14),
            FormCard(
              children: [
                Row(
                  children: [
                    Icon(
                      newer
                          ? Icons.new_releases_outlined
                          : Icons.check_circle_outline,
                      color: newer ? cs.primary : Colors.green.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        newer
                            ? 'Há uma versão nova: ${r.version}'
                            : 'Já tens a versão mais recente',
                        style: tt.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (newer) ...[
                  if (r.name.isNotEmpty && r.name != r.tag)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        r.name,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (downloading) ...[
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progress > 0
                          ? 'A descarregar… ${(progress * 100).round()}%'
                          : 'A descarregar…',
                      style: tt.bodySmall,
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: r.apkUrl == null ? null : _install,
                      icon: const Icon(Icons.download),
                      label: Text(
                        'Descarregar e instalar${r.apkSize > 0 ? ' (${(r.apkSize / 1048576).toStringAsFixed(0)} MB)' : ''}',
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(r.pageUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Abrir a página da versão'),
                  ),
                  if (r.notes.trim().isNotEmpty)
                    Material(
                      type: MaterialType.transparency,
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          title: Text('O que mudou', style: tt.titleSmall),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(_plain(r.notes), style: tt.bodySmall),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Notas em markdown simples -> texto legível.
  static String _plain(String md) => md
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll('**', '')
      .replaceAll('`', '')
      .trim();
}
