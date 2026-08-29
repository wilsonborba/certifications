import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

class ValuePropositionSection extends StatelessWidget {
  const ValuePropositionSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 36 : 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua Inteligência de Estudos, Potencializada por IA de Alta Precisão.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 28 : 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transforme PDFs, livros, aulas em áudio e vídeos em simulados e quizzes interativos em segundos. Estude do seu jeito, no seu ritmo e sem complicação.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.75),
              fontSize: isDesktop ? 16 : 13,
            ),
          ),
          const SizedBox(height: 28),
          _ValueTile(
            icon: Icons.auto_awesome,
            title: '1. Aprenda Qualquer Assunto em 1 Clique',
            description:
                'Esqueça a perda de tempo criando perguntas manualmente. Escolha um tema em nossa lista de sugestões (como Certificações AWS, Python, ENEM ou Direito) ou digite o assunto que deseja dominar.',
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.upload_file,
            title: '2. Estude com Seus Próprios Materiais',
            description:
                'Possui um PDF extenso, uma aula gravada em MP3, um documento Word ou uma planilha? Basta carregar o arquivo e selecionar exatamente o capítulo ou os minutos que deseja revisar.',
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.touch_app,
            title: '3. Interface Ultra-Simples Estilo Apple',
            description:
                'Desenhado para quem busca máxima eficiência. Uma experiência visual moderna, limpa e fluida em 4 passos simples. Mude de etapa quando quiser sem perder o que já preencheu.',
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.dashboard,
            title: '4. Dashboard Inteligente & Retomada Rápida',
            description:
                'Precisou pausar os estudos? Seu rascunho fica salvo automaticamente. Com 1 clique, você retoma o preenchimento exatamente no ponto onde parou.',
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 16),
          _ValueTile(
            icon: Icons.emoji_events,
            title: '5. Compartilhe com Segurança e Dispute o Ranking',
            description:
                'Crie quizzes privados com links seguros que expiram automaticamente ou publique seus simulados no catálogo da comunidade Asodya e dispute o Ranking Oficial!',
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDesktop,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                    fontSize: isDesktop ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
