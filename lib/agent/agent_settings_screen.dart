import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'agent_settings.dart';
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
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Text(
            _kind.isLocal ? l.agLocalNote : l.agPrivacy,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l.agSave)),
          if (_hasKey)
            TextButton(onPressed: _remove, child: Text(l.agRemoveKey)),
        ],
      ),
    );
  }
}
