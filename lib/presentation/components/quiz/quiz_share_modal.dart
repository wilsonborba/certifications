import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Expiration presets mapped to `expires_in_hours` / `max_uses` per the
/// backend contract: 24h -> 24, 7d -> 168, 30d -> 720; the 1-use option
/// sends `max_uses: 1` with a generous 24h default window.
enum _SharePreset { hours24, days7, days30, oneUse }

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
  final _api = QuizApiService();
  _SharePreset selectedPreset = _SharePreset.hours24;
  String generatedUrl = '';
  bool isGenerating = false;
  String? error;

  Future<void> _generateLink() async {
    setState(() {
      isGenerating = true;
      error = null;
    });
    try {
      final share = await _api.createShare(
        widget.quizId,
        expiresInHours: _expiresInHoursFor(selectedPreset),
        maxUses: selectedPreset == _SharePreset.oneUse ? 1 : null,
      );
      if (mounted) {
        setState(() {
          generatedUrl = share.url;
          isGenerating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isGenerating = false;
          error = context.tr('errorGeneric');
        });
      }
    }
  }

  int _expiresInHoursFor(_SharePreset preset) {
    switch (preset) {
      case _SharePreset.hours24:
        return 24;
      case _SharePreset.days7:
        return 168;
      case _SharePreset.days30:
        return 720;
      case _SharePreset.oneUse:
        return 24;
    }
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
            context.trParams('shareModalSubtitle', {'title': widget.quizTitle}),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('expirationLabel'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<_SharePreset>(
            initialValue: selectedPreset,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              DropdownMenuItem(
                value: _SharePreset.hours24,
                child: Text(context.tr('expiration24h')),
              ),
              DropdownMenuItem(
                value: _SharePreset.days7,
                child: Text(context.tr('expiration7d')),
              ),
              DropdownMenuItem(
                value: _SharePreset.days30,
                child: Text(context.tr('expiration30d')),
              ),
              DropdownMenuItem(
                value: _SharePreset.oneUse,
                child: Text(context.tr('expirationOneUse')),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedPreset = val;
                  generatedUrl = '';
                });
              }
            },
          ),
          const SizedBox(height: 20),
          if (error != null) ...[
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
          ],
          if (generatedUrl.isNotEmpty) ...[
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
                      generatedUrl,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: generatedUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('linkCopied'))),
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
                generatedUrl.isEmpty
                    ? context.tr('generateSecureLink')
                    : context.tr('regenerateLink'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
