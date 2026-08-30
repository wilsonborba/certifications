import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/presentation/components/quiz/granular_range_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Extensions accepted by the Step 2 "upload my own material" picker.
const uploadAllowedExtensions = [
  'pdf',
  'docx',
  'csv',
  'txt',
  'md',
  'mp3',
  'wav',
  'm4a',
  'mp4',
  'mov',
];

/// Step 1: pick a quick preset or type a custom study topic.
///
/// Shared by [DesktopQuizWizard] and [MobileQuizWizard]; [isDesktop] only
/// tunes spacing and touch-target size, the behavior is identical.
class Step1ThemeView extends StatelessWidget {
  const Step1ThemeView({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final presets = [
      ('☁️', context.tr('presetAws')),
      ('🐍', context.tr('presetPython')),
      ('📐', context.tr('presetEnem')),
      ('⚖️', context.tr('presetLaw')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('step1Title'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('welcomeBody'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 20),
        Text(
          context.tr('quickPresetsLabel'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: presets.map((preset) {
            final isSelected = wizardData.categoryPreset == preset.$2;
            return ChoiceChip(
              label: Text(preset.$2),
              selected: isSelected,
              onSelected: (_) => wizardData.selectCategoryPreset(preset.$2),
              avatar: Text(preset.$1),
              visualDensity: isDesktop
                  ? VisualDensity.standard
                  : VisualDensity.comfortable,
              labelPadding: isDesktop
                  ? null
                  : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            );
          }).toList(),
        ),
        SizedBox(height: isDesktop ? 28 : 20),
        TextField(
          controller: TextEditingController(text: wizardData.name)
            ..selection = TextSelection.collapsed(offset: wizardData.name.length),
          onChanged: (val) => wizardData.setName(val),
          style: isDesktop ? null : const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: context.tr('studyName'),
            hintText: context.tr('studyNameHint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.edit),
            contentPadding: isDesktop
                ? null
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}

/// Step 2: pick where the quiz content comes from (AI, upload, or web).
class Step2SourceView extends StatelessWidget {
  const Step2SourceView({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  Future<void> _pickFile() async {
    wizardData.setSourceType(SourceType.uploadFile);
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: uploadAllowedExtensions,
    );
    final file = result?.files.single;
    if (file?.bytes == null || file == null) return;
    final ext = file.extension?.toLowerCase() ?? 'pdf';
    wizardData.setFile(bytes: file.bytes!, name: file.name, kind: ext);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: 16,
      vertical: isDesktop ? 8 : 14,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('step2Title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: contentPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: wizardData.sourceType == SourceType.aiGeneral
                    ? scheme.primary
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            title: Text(context.tr('sourceAi')),
            leading: const Icon(Icons.psychology),
            selected: wizardData.sourceType == SourceType.aiGeneral,
            onTap: () => wizardData.setSourceType(SourceType.aiGeneral),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: contentPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: wizardData.sourceType == SourceType.uploadFile
                    ? scheme.primary
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            title: Text(context.tr('sourceUpload')),
            subtitle: wizardData.fileName == null
                ? Text(context.tr('sourceUploadHint'))
                : _UploadedFileSummary(wizardData: wizardData),
            leading: const Icon(Icons.upload_file),
            selected: wizardData.sourceType == SourceType.uploadFile,
            onTap: _pickFile,
          ),
          if (wizardData.sourceType == SourceType.uploadFile &&
              wizardData.fileBytes != null) ...[
            const SizedBox(height: 16),
            GranularRangeSelector(wizardData: wizardData, isDesktop: isDesktop),
          ],
          const SizedBox(height: 10),
          ListTile(
            contentPadding: contentPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: wizardData.sourceType == SourceType.webSearch
                    ? scheme.primary
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            title: Text(context.tr('sourceWeb')),
            leading: const Icon(Icons.language),
            selected: wizardData.sourceType == SourceType.webSearch,
            onTap: () => wizardData.setSourceType(SourceType.webSearch),
          ),
        ],
      ),
    );
  }
}

/// Compact filename + size + format-badge + remove-icon row shown once a
/// file has been picked for the "upload my own material" source option.
class _UploadedFileSummary extends StatelessWidget {
  const _UploadedFileSummary({required this.wizardData});

  final QuizWizardData wizardData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = wizardData.fileKind?.toLowerCase() ?? '';
    final visual = fileKindVisual(kind);
    final size = wizardData.fileBytes != null
        ? formatFileSize(wizardData.fileBytes!.length)
        : '';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: visual.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(visual.icon, size: 12, color: visual.color),
                const SizedBox(width: 4),
                Text(
                  kind.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: visual.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${wizardData.fileName} · $size',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: context.tr('removeFile'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => wizardData.clearFile(),
          ),
        ],
      ),
    );
  }
}

/// Step 3: difficulty and question count.
class Step3FormatView extends StatelessWidget {
  const Step3FormatView({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('step3Title'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('difficultyLabel'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _maybeFullWidth(
          SegmentedButton<DifficultyLevel>(
            segments: [
              ButtonSegment(
                value: DifficultyLevel.easy,
                label: Text(context.tr('easy')),
                icon: const Icon(Icons.sentiment_satisfied),
              ),
              ButtonSegment(
                value: DifficultyLevel.medium,
                label: Text(context.tr('medium')),
                icon: const Icon(Icons.sentiment_neutral),
              ),
              ButtonSegment(
                value: DifficultyLevel.hard,
                label: Text(context.tr('hard')),
                icon: const Icon(Icons.sentiment_very_dissatisfied),
              ),
            ],
            selected: {wizardData.difficulty},
            onSelectionChanged: (set) => wizardData.setDifficulty(set.first),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '${context.tr('questionCount')}: ${wizardData.questionCount}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _maybeFullWidth(
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 15, label: Text('15')),
              ButtonSegment(value: 20, label: Text('20')),
            ],
            selected: {wizardData.questionCount},
            onSelectionChanged: (set) => wizardData.setQuestionCount(set.first),
          ),
        ),
      ],
    );
  }

  Widget _maybeFullWidth(Widget child) =>
      isDesktop ? child : SizedBox(width: double.infinity, child: child);
}

/// Step 4: review the chosen options before generating the quiz.
class Step4ReviewView extends StatelessWidget {
  const Step4ReviewView({
    super.key,
    required this.wizardData,
    required this.onGenerate,
  });

  final QuizWizardData wizardData;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('step4Title'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.tr('reviewThemeLabel')} ${wizardData.name.isEmpty ? wizardData.categoryPreset : wizardData.name}',
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr('reviewSourceLabel')} ${wizardData.sourceType.name} ${wizardData.fileName ?? ''}',
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr('reviewLevelLabel')} ${wizardData.difficulty.name} • ${wizardData.questionCount} ${context.tr('questionCount')}',
              ),
            ],
          ),
        ),
        // A fixed gap (rather than Spacer) keeps this step safe to render
        // inside an unbounded-height scroll view on mobile, not just the
        // desktop card's bounded Expanded region.
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              context.tr('generateQuizNow'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
