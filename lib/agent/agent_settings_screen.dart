import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'agent_settings.dart';
import 'ondevice/on_device_models.dart';
import 'provider/provider_kind.dart';

class AgentSettingsScreen extends StatefulWidget {
  const AgentSettingsScreen({super.key});
  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _url = TextEditingController();
  String? _error;
  AgentProviderKind _kind = AgentProviderKind.claude;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _load(null);
  }

  /// Carrega a chave e o modelo de [kind] (nulo = o fornecedor guardado).
  Future<void> _load(AgentProviderKind? kind) async {
    final k = kind ?? await AgentSettings.readKind();
    final key = await AgentSettings.readApiKey(k);
    final model = await AgentSettings.readModel(k);
    final url = await AgentSettings.readBaseUrl();
    if (!mounted) return;
    setState(() {
      _error = null;
      _url.text = url ?? '';
      _kind = k;
      _hasKey = key != null;
      _key.clear();
      _model.text = model;
    });
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (_kind == AgentProviderKind.onDevice) {
      if (await OnDeviceModels.activeFile() == null) {
        setState(() => _error = l.agOnDeviceNeedModel);
        return;
      }
      await AgentSettings.saveKind(_kind);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.agSaved)));
      Navigator.pop(context, true);
      return;
    }
    if (_kind.isLocal) {
      if (normalizeBaseUrl(_url.text) == null) {
        setState(() => _error = l.agLocalUrlInvalid);
        return;
      }
      if (_model.text.trim().isEmpty) {
        setState(() => _error = l.agLocalModelRequired);
        return;
      }
      await AgentSettings.saveBaseUrl(normalizeBaseUrl(_url.text));
    }
    await AgentSettings.saveKind(_kind);
    if (_key.text.trim().isNotEmpty) {
      await AgentSettings.saveApiKey(_kind, _key.text);
    }
    await AgentSettings.saveModel(_kind, _model.text);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l.agSaved)));
    Navigator.pop(context, true);
  }

  Future<void> _remove() async {
    await AgentSettings.saveApiKey(_kind, null);
    if (!mounted) return;
    setState(() {
      _hasKey = false;
      _key.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.agSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<AgentProviderKind>(
            initialValue: _kind,
            key: ValueKey(_kind),
            decoration: InputDecoration(
              labelText: l.agProviderLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final k in AgentProviderKind.values)
                DropdownMenuItem(value: k, child: Text(k.label)),
            ],
            onChanged: (k) {
              if (k != null) _load(k);
            },
          ),
          const SizedBox(height: 16),
          if (_kind == AgentProviderKind.onDevice)
            const OnDeviceModelsPanel()
          else ...[
            if (_kind.isLocal) ...[
              TextField(
                controller: _url,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l.agLocalUrlLabel,
                  hintText: 'http://192.168.1.10:11434/v1',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _key,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: _kind.isLocal
                    ? l.agKeyOptional
                    : l.agKeyLabel(_kind.label),
                helperText: _hasKey ? l.agKeyStored : null,
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _model,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.agModelLabel,
                hintText: _kind.defaultModel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Text(switch (_kind) {
            AgentProviderKind.local => l.agLocalNote,
            AgentProviderKind.onDevice => l.agOnDeviceNote,
            _ => l.agPrivacy,
          }, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l.agSave)),
          if (_hasKey && _kind != AgentProviderKind.onDevice)
            TextButton(onPressed: _remove, child: Text(l.agRemoveKey)),
        ],
      ),
    );
  }
}

/// Lista de modelos para o telemóvel: descarregar, usar e apagar.
class OnDeviceModelsPanel extends StatefulWidget {
  const OnDeviceModelsPanel({super.key});
  @override
  State<OnDeviceModelsPanel> createState() => _OnDeviceModelsPanelState();
}

class _OnDeviceModelsPanelState extends State<OnDeviceModelsPanel> {
  List<OnDeviceModelOption>? _options;
  Set<String> _installed = {};
  String? _active;
  String? _busyFile; // modelo a descarregar ou a mudar
  int _percent = 0;
  String? _error;
  bool _unsupported = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final options = await OnDeviceModels.options();
      final installed = await OnDeviceModels.installedFiles();
      final active = await OnDeviceModels.activeFile();
      if (!mounted) return;
      setState(() {
        _options = options;
        _installed = installed;
        _active = active;
        _unsupported = options.isEmpty;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _options = const [];
        _unsupported = true;
      });
    }
  }

  Future<void> _install(OnDeviceModelOption o) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busyFile = o.file;
      _percent = 0;
      _error = null;
    });
    try {
      await OnDeviceModels.install(
        o,
        onProgress: (p) {
          if (mounted) setState(() => _percent = p);
        },
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.agDownloadFailed('$e'));
    } finally {
      if (mounted) setState(() => _busyFile = null);
      await _refresh();
    }
  }

  Future<void> _delete(OnDeviceModelOption o) async {
    final l = AppLocalizations.of(context)!;
    try {
      await OnDeviceModels.uninstall(o);
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.agDownloadFailed('$e'));
    }
    await _refresh();
  }

  static String _size(int bytes) => bytes >= 1000 * 1000 * 1000
      ? '${(bytes / 1e9).toStringAsFixed(1)} GB'
      : '${(bytes / 1e6).round()} MB';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = _options;
    if (options == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_unsupported) return Text(l.agOnDeviceUnsupported);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in options)
          Card(
            child: ListTile(
              title: Text(
                o.recommended ? '${o.name} · ${l.agRecommended}' : o.name,
              ),
              subtitle: Text(
                _busyFile == o.file
                    ? l.agDownloading(_percent)
                    : _active == o.file
                    ? '${_size(o.sizeBytes)} · ${l.agInUse}'
                    : _size(o.sizeBytes),
              ),
              trailing: _busyFile == o.file
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: _percent > 0 ? _percent / 100 : null,
                        strokeWidth: 3,
                      ),
                    )
                  : _installed.contains(o.file)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_active != o.file)
                          TextButton(
                            onPressed: _busyFile == null
                                ? () => _install(o)
                                : null,
                            child: Text(l.agUse),
                          ),
                        IconButton(
                          tooltip: l.agDeleteModel,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _busyFile == null
                              ? () => _delete(o)
                              : null,
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: _busyFile == null ? () => _install(o) : null,
                      child: Text(l.agDownload),
                    ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
