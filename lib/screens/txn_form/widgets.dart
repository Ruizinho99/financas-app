import 'package:flutter/material.dart';

/// Rótulo pequeno de uma secção do formulário (Onde / o quê, Categoria, Quando…).
class SecaoRotulo extends StatelessWidget {
  final String texto;
  const SecaoRotulo(this.texto, {super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Linha do bloco "Avançado": ícone, título e subtítulo de uma linha; [child] aparece por baixo.
class LinhaAvancada extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasValue; // destaca o ícone quando já tem valor
  final VoidCallback? onTap;
  final IconData trailing;
  final Widget? child;
  const LinhaAvancada({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hasValue = false,
    this.onTap,
    this.trailing = Icons.chevron_right,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            icon,
            color: hasValue ? cs.primary : cs.onSurfaceVariant,
          ),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(trailing, color: cs.onSurfaceVariant),
          onTap: onTap,
        ),
        if (child != null) child!,
      ],
    );
  }
}

/// Caixa pequena de conta (De / Para) das transferências.
class CaixaConta extends StatelessWidget {
  final String rotulo;
  final String texto;
  final bool dica;
  final VoidCallback onTap;
  const CaixaConta({
    super.key,
    required this.rotulo,
    required this.texto,
    required this.dica,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rotulo,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: dica ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
