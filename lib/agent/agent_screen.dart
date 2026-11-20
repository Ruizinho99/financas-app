import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import 'agent_loop.dart';
import 'agent_settings.dart';
import 'agent_settings_screen.dart';
import 'provider/claude_provider.dart';
import 'provider/llm_provider.dart';
import 'tools/read_tools.dart';

/// Conversa com o agente. [provider] só serve para testes: sem ele usa-se o
/// Claude com a chave guardada nas definições.
class AgentScreen extends StatefulWidget {
  final LlmProvider? provider;
  const AgentScreen({super.key, this.provider});
  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<AgentMessage> _history = [];
  bool _loading = true;
  bool _hasKey = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _checkKey() async {
    final has =
        widget.provider != null || await AgentSettings.readApiKey() != null;
    if (!mounted) return;
    setState(() {
      _hasKey = has;
      _loading = false;
    });
  }

  Future<LlmProvider?> _provider() async {
    if (widget.provider != null) return widget.provider;
    final key = await AgentSettings.readApiKey();
    if (key == null) return null;
    return ClaudeProvider(apiKey: key, model: await AgentSettings.readModel());
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AgentSettingsScreen()),
    );
    await _checkKey();
  }

  String _errorText(AppLocalizations l, Object e) {
    if (e is LlmException) {
      if (e.statusCode == 401 || e.statusCode == 403) return l.agErrKey;
      if (e.message.startsWith('network:')) return l.agErrNetwork;
      if (e.message == 'too-many-steps') return l.agErrSteps;
      return l.agErrGeneric(e.message);
    }
    return l.agErrGeneric('$e');
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    final state = context.read<AppState>();
    final l = AppLocalizations.of(context)!;
    final provider = await _provider();
    if (provider == null) {
      await _openSettings();
      return;
    }
    final before = _history.length;
    setState(() {
      _history.add(AgentMessage.user(text));
      _input.clear();
      _busy = true;
      _error = null;
    });
    _scrollDown();
    try {
      final added = await AgentLoop(
        provider: provider,
        tools: buildReadTools(state),
      ).run(List.of(_history));
      if (!mounted) return;
      setState(() => _history.addAll(added));
    } on Object catch (e) {
      if (!mounted) return;
      // a pergunta fica no ecrã; a conversa interna volta ao estado anterior
      // para o utilizador poder tentar de novo sem mensagens por responder
      setState(() {
        _history.removeRange(before, _history.length);
        _input.text = text;
        _error = _errorText(l, e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final visible = [
      for (final m in _history)
        if (m.text.isNotEmpty) m,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.agTitle),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: l.agNewChat,
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _history.clear();
                      _error = null;
                    }),
            ),
          IconButton(
            tooltip: l.agSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasKey
          ? _NeedKey(onSet: _openSettings)
          : Column(
              children: [
                Expanded(
                  child: visible.isEmpty && !_busy
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '${l.agEmpty}\n\n${l.agReadOnly}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.all(12),
                          children: [
                            for (final m in visible) _Bubble(m),
                            if (_busy)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(l.agThinking),
                              ),
                          ],
                        ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: l.agInputHint,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l.agSend,
                          icon: const Icon(Icons.send),
                          onPressed: _busy ? null : _send,
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

class _NeedKey extends StatelessWidget {
  final VoidCallback onSet;
  const _NeedKey({required this.onSet});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.agNeedKey, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onSet, child: Text(l.agNeedKeyAction)),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final AgentMessage message;
  const _Bubble(this.message);
  @override
  Widget build(BuildContext context) {
    final mine = message.role == AgentRole.user;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: mine
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(message.text),
      ),
    );
  }
}
