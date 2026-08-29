import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:flutter/material.dart';

class GranularRangeSelector extends StatelessWidget {
  const GranularRangeSelector({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fileKind = wizardData.fileKind?.toLowerCase() ?? 'pdf';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFileKindBadge(scheme, fileKind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wizardData.fileName ?? 'arquivo_desconhecido',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (wizardData.fileBytes != null)
                      Text(
                        '${(wizardData.fileBytes!.length / (1024 * 1024)).toStringAsFixed(2)} MB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  wizardData.fileBytes = null;
                  wizardData.fileName = null;
                  wizardData.fileKind = null;
                  wizardData.notifyListeners();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Qual trecho você deseja utilizar?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(context.tr('wholeDocument')),
                icon: const Icon(Icons.select_all),
              ),
              ButtonSegment(
                value: false,
                label: Text(context.tr('selectRange')),
                icon: const Icon(Icons.tune),
              ),
            ],
            selected: {wizardData.isWholeDocument},
            onSelectionChanged: (set) {
              wizardData.isWholeDocument = set.first;
              wizardData.notifyListeners();
            },
          ),
          if (!wizardData.isWholeDocument) ...[
            const SizedBox(height: 16),
            _buildRangeControls(context, fileKind),
          ],
        ],
      ),
    );
  }

  Widget _buildFileKindBadge(ColorScheme scheme, String kind) {
    Color badgeColor = scheme.primary;
    IconData iconData = Icons.insert_drive_file;

    if (kind == 'pdf') {
      badgeColor = Colors.redAccent;
      iconData = Icons.picture_as_pdf;
    } else if (kind == 'docx' || kind == 'doc') {
      badgeColor = Colors.blueAccent;
      iconData = Icons.description;
    } else if (kind == 'csv') {
      badgeColor = Colors.green;
      iconData = Icons.table_chart;
    } else if (kind == 'mp3' || kind == 'wav' || kind == 'm4a') {
      badgeColor = Colors.purpleAccent;
      iconData = Icons.audiotrack;
    } else if (kind == 'mp4' || kind == 'mov') {
      badgeColor = Colors.orangeAccent;
      iconData = Icons.video_library;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: badgeColor, size: 24),
    );
  }

  Widget _buildRangeControls(BuildContext context, String kind) {
    final scheme = Theme.of(context).colorScheme;

    if (kind == 'pdf' || kind == 'docx' || kind == 'doc') {
      return Row(
        children: [
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${wizardData.pageStart}'),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && p >= 1) wizardData.pageStart = p;
              },
              decoration: InputDecoration(
                labelText: 'Página Inicial',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('até', style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${wizardData.pageEnd}'),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && p >= wizardData.pageStart) wizardData.pageEnd = p;
              },
              decoration: InputDecoration(
                labelText: 'Página Final',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    if (kind == 'csv' || kind == 'txt' || kind == 'md') {
      return Row(
        children: [
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${wizardData.lineStart}'),
              onChanged: (val) {
                final l = int.tryParse(val);
                if (l != null && l >= 1) wizardData.lineStart = l;
              },
              decoration: InputDecoration(
                labelText: 'Linha Inicial',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('até', style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '${wizardData.lineEnd}'),
              onChanged: (val) {
                final l = int.tryParse(val);
                if (l != null && l >= wizardData.lineStart) wizardData.lineEnd = l;
              },
              decoration: InputDecoration(
                labelText: 'Linha Final',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    // Audio or Video timestamp range
    final startMin = (wizardData.audioStartMs / 60000).floor();
    final endMin = (wizardData.audioEndMs / 60000).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intervalo de Tempo: ${startMin}min até ${endMin}min',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        RangeSlider(
          values: RangeValues(startMin.toDouble(), endMin.toDouble()),
          min: 0,
          max: 60,
          divisions: 60,
          labels: RangeLabels('${startMin}m', '${endMin}m'),
          onChanged: (values) {
            wizardData.audioStartMs = (values.start * 60000).toInt();
            wizardData.audioEndMs = (values.end * 60000).toInt();
            wizardData.notifyListeners();
          },
        ),
      ],
    );
  }
}
