import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizShareModal extends StatefulWidget {
  const QuizShareModal({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  State<QuizShareModal> createState() => _QuizShareModalState();
}

class _QuizShareModalState extends State<QuizShareModal> {
  int selectedHours = 24;
  String generatedToken = '';
  bool isGenerating = false;

  void _generateLink() {
    setState(() {
      isGenerating = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          generatedToken = 'https://certifications.asodya.app/quizzes/share/${widget.quizId}_${selectedHours}h';
          isGenerating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.share, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                context.tr('shareLink'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Compartilhar: "${widget.quizTitle}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tempo de Expiração do Link:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: selectedHours,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 24, child: Text('24 Horas (Curto Prazo)')),
              DropdownMenuItem(value: 168, child: Text('7 Dias (1 Semana)')),
              DropdownMenuItem(value: 720, child: Text('30 Dias (1 Mês)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedHours = val;
                  generatedToken = '';
                });
              }
            },
          ),
          const SizedBox(height: 20),
          if (generatedToken.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      generatedToken,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: generatedToken));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copiado para a área de transferência!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : _generateLink,
              icon: isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(
                generatedToken.isEmpty ? 'Gerar Link Seguro Expirável' : 'Regerar Link',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
