import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:flutter/material.dart';

/// One draft/standby study. Exactly two inline actions besides delete:
/// Info (expands in place to show fuller stats/context) and Quick Edit
/// (rename only, not a full edit surface). Tapping the card itself always
/// resumes the wizard at its saved step, there is no separate destination.
///
/// In selection mode (bulk delete), tapping toggles selection instead of
/// resuming, and long-pressing any card enters selection mode.
class StandbyStudyCard extends StatefulWidget {
  const StandbyStudyCard({
    super.key,
    required this.study,
    required this.onDeleted,
    required this.onUpdated,
    required this.onOpen,
    required this.isDesktop,
    this.selectionMode = false,
    this.selected = false,
    this.onToggleSelected,
    this.onEnterSelectionMode,
  });

  final Study study;
  final VoidCallback onDeleted;

  /// Called after a successful rename so the parent dashboard can reload the
  /// studies list with fresh data.
  final VoidCallback onUpdated;
  final VoidCallback onOpen;
  final bool isDesktop;

  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onEnterSelectionMode;

  @override
  State<StandbyStudyCard> createState() => _StandbyStudyCardState();
}

class _StandbyStudyCardState extends State<StandbyStudyCard> {
  bool isExpanded = false;
  bool isDeleting = false;
  final api = StudyApiService();

  Future<void> _deleteStudy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text(
          context.trParams('deleteStudyConfirm', {'name': widget.study.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isDeleting = true);
    try {
      await api.delete(widget.study.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('studyDeletedSuccess'))),
        );
        widget.onDeleted();
      }
    } catch (_) {
      if (mounted) {
        setState(() => isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('errorGeneric'))),
        );
      }
    }
  }

  Future<void> _openEditModal() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _QuickEditStudyDialog(study: widget.study, api: api),
    );
    if (updated == true) widget.onUpdated();
  }

  void _handleTap() {
    if (widget.selectionMode) {
      widget.onToggleSelected?.call();
    } else {
      widget.onOpen();
    }
  }

  void _handleLongPress() {
    if (!widget.selectionMode) {
      widget.onEnterSelectionMode?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final study = widget.study;
    final sizeMb = (study.activeSizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDeleting ? 0.0 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: widget.selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _handleTap,
            onLongPress: _handleLongPress,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.selectionMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                widget.selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: widget.selected
                                    ? scheme.primary
                                    : scheme.onSurface.withValues(alpha: 0.4),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.folder_special, color: scheme.primary),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  study.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        study.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$sizeMb ${context.tr('mbUsedLabel')}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    Text(
                                      context.trParams('attachedSourcesLabel', {
                                        'count': '${study.sources.length}',
                                      }),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!widget.selectionMode)
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurface.withValues(alpha: 0.35),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => setState(() => isExpanded = !isExpanded),
                            icon: Icon(
                              isExpanded ? Icons.expand_less : Icons.visibility_outlined,
                              size: 16,
                            ),
                            label: Text(context.tr('quickInfo')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openEditModal,
                            icon: const Icon(Icons.drive_file_rename_outline, size: 16),
                            label: Text(context.tr('editStudy')),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: context.tr('delete'),
                            onPressed: _deleteStudy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: isExpanded
                      ? _QuickInfoDetail(study: study)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Info/Quick View accordion body: the fuller stat set requested for
/// this card (per-file size and selected range, plus when it was last
/// touched locally).
class _QuickInfoDetail extends StatelessWidget {
  const _QuickInfoDetail({required this.study});

  final Study study;

  String _formatSelection(BuildContext context, StudySource source) {
    final sel = source.selection;
    if (sel == null || sel.isEmpty) return context.tr('wholeDocument');
    if (sel.containsKey('page_start')) {
      return '${context.tr('pageStartLabel')} ${sel['page_start']} ${context.tr('rangeUntil')} ${sel['page_end']}';
    }
    if (sel.containsKey('line_start')) {
      return '${context.tr('lineStartLabel')} ${sel['line_start']} ${context.tr('rangeUntil')} ${sel['line_end']}';
    }
    if (sel.containsKey('audio_start_ms')) {
      final startMin = ((sel['audio_start_ms'] as num) / 60000).floor();
      final endMin = ((sel['audio_end_ms'] as num? ?? 0) / 60000).floor();
      return '${context.tr('timeRangeLabel')} ${startMin}min ${context.tr('rangeUntil')} ${endMin}min';
    }
    return context.tr('wholeDocument');
  }

  IconData _fileIcon(String kind) {
    switch (kind.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'csv':
        return Icons.table_chart;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<DateTime?>(
            future: DraftProgressStore.instance.getLastOpenedAt(study.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final touched = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: scheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Text(
                      context.trParams('lastOpenedLabel', {
                        'date':
                            '${touched.day.toString().padLeft(2, '0')}/${touched.month.toString().padLeft(2, '0')}/${touched.year} ${touched.hour.toString().padLeft(2, '0')}:${touched.minute.toString().padLeft(2, '0')}',
                      }),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Text(
            context.trParams('attachedSourcesLabel', {'count': '${study.sources.length}'}),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (study.sources.isEmpty)
            Text(
              context.tr('noFilesAttachedYet'),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Column(
              children: study.sources.map((src) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_fileIcon(src.kind), size: 18, color: scheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(src.filename, style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              '${(src.sizeBytes / 1024).toStringAsFixed(0)} KB · ${_formatSelection(context, src)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// Quick Edit: inline, limited to simple fields (the study's name), not the
/// full edit surface.
class _QuickEditStudyDialog extends StatefulWidget {
  const _QuickEditStudyDialog({required this.study, required this.api});

  final Study study;
  final StudyApiService api;

  @override
  State<_QuickEditStudyDialog> createState() => _QuickEditStudyDialogState();
}

class _QuickEditStudyDialogState extends State<_QuickEditStudyDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.study.name);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.study.name) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.rename(widget.study.id, newName);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.tr('errorGeneric');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('editStudy')),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: context.tr('renameStudyLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('saveChanges')),
        ),
      ],
    );
  }
}
