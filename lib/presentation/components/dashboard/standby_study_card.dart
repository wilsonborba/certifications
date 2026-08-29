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
    required this.onOpen,
    required this.isDesktop,
  });

  final Study study;
  final VoidCallback onDeleted;
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
        content: Text('Deseja realmente excluir o estudo "${widget.study.name}"?'),
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
          const SnackBar(content: Text('Estudo removido com sucesso.')),
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
          const SnackBar(content: Text('Arquivo anexado com sucesso.')),
        );
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('errorGeneric'))),
        );
      }
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
                                  '$sizeMb MB Usados',
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
                      'Arquivos e Fontes Anexadas (${study.sources.length}):',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (study.sources.isEmpty)
                      Text(
                        'Nenhum arquivo anexado ainda.',
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
