import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compact "Sources" strip under a question: a clickable link for each
/// web-sourced citation, plain text for study-material ones. Renders
/// nothing when the question has no citations worth showing (i.e. only the
/// generic "Study material" fallback with no real web source).
class QuestionCitations extends StatelessWidget {
  const QuestionCitations({super.key, required this.citations});

  final List<QuestionCitation> citations;

  @override
  Widget build(BuildContext context) {
    final webCitations = citations.where((c) => c.isWeb).toList();
    if (webCitations.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('sourcesLabel'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final citation in webCitations)
                _SourceChip(citation: citation),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.citation});
  final QuestionCitation citation;

  Future<void> _open() async {
    final uri = Uri.tryParse(citation.source);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final host = Uri.tryParse(citation.source)?.host ?? citation.source;

    return Tooltip(
      message: citation.selection,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                host,
                style: TextStyle(fontSize: 12, color: scheme.onSecondaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
