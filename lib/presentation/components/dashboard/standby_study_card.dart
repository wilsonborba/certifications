import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class StandbyStudyCard extends StatefulWidget {
  const StandbyStudyCard({
    super.key,
    required this.study,
    required this.onDeleted,
    required this.onUpdated,
    required this.onOpen,
    required this.isDesktop,
  });

  final Study study;
  final VoidCallback onDeleted;

  /// Called after a successful rename or source-range edit so the parent
  /// dashboard can reload the studies list with fresh data.
  final VoidCallback onUpdated;
  final VoidCallback onOpen;
  final bool isDesktop;

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

  Future<void> _addFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result?.files.single == null) return;
    final file = result!.files.single;
    try {
      await api.upload(
        studyId: widget.study.id,
        kind: file.extension?.toLowerCase() ?? 'pdf',
        filename: file.name,
        bytes: file.bytes!,
        mimeType: 'application/octet-stream',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('fileAttachedSuccess'))),
        );
        widget.onUpdated();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('errorGeneric'))),
        );
      }
    }
  }

  Future<void> _openEditModal() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _EditStudyDialog(study: widget.study, api: api),
    );
    if (updated == true) widget.onUpdated();
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
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.1),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
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
                                const SizedBox(width: 10),
                                Text(
                                  '$sizeMb ${context.tr('mbUsedLabel')}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        onPressed: () => setState(() => isExpanded = !isExpanded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => setState(() => isExpanded = !isExpanded),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: Text(context.tr('quickInfo')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addFile,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(context.tr('addFile')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openEditModal,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(context.tr('editStudy')),
                      ),
                      ElevatedButton.icon(
                        onPressed: widget.onOpen,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text(context.tr('startQuiz')),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: _deleteStudy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(20),
                color: scheme.surfaceVariant.withOpacity(0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trParams('attachedSourcesLabel', {
                        'count': '${study.sources.length}',
                      }),
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
                          return ListTile(
                            dense: true,
                            leading: Icon(_fileIcon(src.kind), size: 18),
                            title: Text(src.filename),
                            subtitle: Text('${(src.sizeBytes / 1024).toStringAsFixed(0)} KB'),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
}

/// Rename the study and/or tweak the selected page/line/time range of each
/// already-uploaded source.
class _EditStudyDialog extends StatefulWidget {
  const _EditStudyDialog({required this.study, required this.api});

  final Study study;
  final StudyApiService api;

  @override
  State<_EditStudyDialog> createState() => _EditStudyDialogState();
}

class _EditStudyDialogState extends State<_EditStudyDialog> {
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
    if (newName.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (newName != widget.study.name) {
        await widget.api.rename(widget.study.id, newName);
      }
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

  Future<void> _editSourceRange(StudySource source) async {
    final first = TextEditingController();
    final last = TextEditingController();
    final selected = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('editSourceRangesLabel')),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: first,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('start')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: last,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('end')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final a = int.tryParse(first.text);
              final b = int.tryParse(last.text);
              if (a != null && b != null) {
                Navigator.pop(
                  context,
                  source.kind == 'pdf'
                      ? {'page_start': a, 'page_end': b}
                      : source.kind == 'audio'
                      ? {'audio_start_ms': a, 'audio_end_ms': b}
                      : {'line_start': a, 'line_end': b},
                );
              }
            },
            child: Text(context.tr('process')),
          ),
        ],
      ),
    );
    if (selected == null) return;
    setState(() => _saving = true);
    try {
      await widget.api.select(
        studyId: widget.study.id,
        sourceId: source.id,
        selection: selected,
      );
      await widget.api.ingest(widget.study.id, source.id);
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
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.tr('renameStudyLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.study.sources.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                context.tr('editSourceRangesLabel'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.study.sources.map(
                (source) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(source.filename, overflow: TextOverflow.ellipsis),
                  trailing: OutlinedButton(
                    onPressed: _saving ? null : () => _editSourceRange(source),
                    child: Text(context.tr('selectRange')),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
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
