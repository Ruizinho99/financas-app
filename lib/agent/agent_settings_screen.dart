import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'agent_settings.dart';
import 'provider/claude_provider.dart';

class AgentSettingsScreen extends StatefulWidget {
  const AgentSettingsScreen({super.key});
  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await AgentSettings.readApiKey();
    final m = await AgentSettings.readModel();
    if (!mounted) return;
    setState(() {
      _hasKey = k != null;
      _model.text = m;
    });
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (_key.text.trim().isNotEmpty) {
      await AgentSettings.saveApiKey(_key.text);
    }
    await AgentSettings.saveModel(_model.text);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l.agSaved)));
    Navigator.pop(context, true);
  }

  Future<void> _remove() async {
    await AgentSettings.saveApiKey(null);
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
          TextField(
            controller: _key,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l.agKeyLabel,
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
              hintText: ClaudeProvider.defaultModel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.agPrivacy, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l.agSave)),
          if (_hasKey)
            TextButton(onPressed: _remove, child: Text(l.agRemoveKey)),
        ],
      ),
    );
  }
}
