import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:certifications/presentation/components/quiz/granular_range_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Extensions accepted by the Step 2 file picker.
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

/// Step 1: name the study. Quick-preset cards (AWS/Python/ENEM/Law) were
/// removed after testing confirmed they were bad UX; free-text is now the
/// only input on this step.
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
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
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

/// Step 2: attach the study material. Upload is the sole real source (no
/// backend support exists for "AI generates it for me" or "search the web"),
/// so this step is a single elevated, primary-feeling upload zone rather than
/// a choice between three options.
///
/// Split into two visual phases:
/// - Phase A (add files): an "Add files" button, a horizontally scrollable
///   strip of the files added so far, and a running total against the
///   per-study 150MB cap.
/// - Phase B (configure a file, optional): each file defaults to whole
///   document. Tapping a file's chip expands [GranularRangeSelector] for
///   just that file, accordion-style, collapsed by default.
class Step2SourceView extends StatefulWidget {
  const Step2SourceView({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  State<Step2SourceView> createState() => _Step2SourceViewState();
}

class _Step2SourceViewState extends State<Step2SourceView> {
  int? _expandedIndex;

  Future<void> _pickFiles() async {
    final wizardData = widget.wizardData;
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: uploadAllowedExtensions,
      allowMultiple: true,
    );
    if (result == null) return;

    var blocked = false;
    for (final picked in result.files) {
      final bytes = picked.bytes;
      if (bytes == null) continue;
      if (wizardData.wouldExceedCap(bytes.length)) {
        blocked = true;
        continue;
      }
      wizardData.addFile(
        AttachedFile(
          bytes: bytes,
          name: picked.name,
          kind: picked.extension?.toLowerCase() ?? 'pdf',
        ),
      );
    }

    if (blocked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('capExceededWarning'))),
      );
    }
  }

  void _removeFile(int index) {
    widget.wizardData.removeFileAt(index);
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = null);
    } else if (_expandedIndex != null && _expandedIndex! > index) {
      setState(() => _expandedIndex = _expandedIndex! - 1);
    }
  }

  void _toggleExpanded(int index) {
    setState(() => _expandedIndex = _expandedIndex == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final wizardData = widget.wizardData;
    final scheme = Theme.of(context).colorScheme;
    final usedMb = (wizardData.totalAttachedBytes / (1024 * 1024));
    final capMb = QuizWizardData.maxTotalAttachedBytes / (1024 * 1024);
    final ratio = (usedMb / capMb).clamp(0.0, 1.0);
    final over = wizardData.totalAttachedBytes > QuizWizardData.maxTotalAttachedBytes;

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
          PremiumHoverCard(
            padding: EdgeInsets.all(widget.isDesktop ? 24 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.upload_file, color: scheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('sourceUpload'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              context.tr('sourceUploadHint'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('addFiles')),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _CapUsageBar(usedMb: usedMb, capMb: capMb, ratio: ratio, over: over),
                const SizedBox(height: 20),
                if (wizardData.attachedFiles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        context.tr('noFilesAddedYet'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: wizardData.attachedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => _FileChip(
                        file: wizardData.attachedFiles[index],
                        expanded: _expandedIndex == index,
                        onTap: () => _toggleExpanded(index),
                        onRemove: () => _removeFile(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('tapFileToConfigureHint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _expandedIndex == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: GranularRangeSelector(
                              key: ValueKey(_expandedIndex),
                              file: wizardData.attachedFiles[_expandedIndex!],
                              isDesktop: widget.isDesktop,
                              onUpdate: ({
                                bool? isWholeDocument,
                                int? pageStart,
                                int? pageEnd,
                                int? lineStart,
                                int? lineEnd,
                                int? audioStartMs,
                                int? audioEndMs,
                              }) => wizardData.updateFileRange(
                                _expandedIndex!,
                                isWholeDocument: isWholeDocument,
                                pageStart: pageStart,
                                pageEnd: pageEnd,
                                lineStart: lineStart,
                                lineEnd: lineEnd,
                                audioStartMs: audioStartMs,
                                audioEndMs: audioEndMs,
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A running-total bar against the per-study 150MB cap, always visible above
/// the file strip so the user knows how much room is left.
class _CapUsageBar extends StatelessWidget {
  const _CapUsageBar({
    required this.usedMb,
    required this.capMb,
    required this.ratio,
    required this.over,
  });

  final double usedMb;
  final double capMb;
  final double ratio;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = over ? scheme.error : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.trParams('filesCapUsageLabel', {
                'used': usedMb.toStringAsFixed(1),
                'cap': capMb.toStringAsFixed(0),
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (over) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber_rounded, size: 14, color: scheme.error),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: scheme.outlineVariant.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}

/// A single attached file, shown as a compact chip/card in the Phase A strip.
/// Tapping it toggles the Phase B range accordion for just that file; the
/// remove icon detaches it entirely.
class _FileChip extends StatelessWidget {
  const _FileChip({
    required this.file,
    required this.expanded,
    required this.onTap,
    required this.onRemove,
  });

  final AttachedFile file;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = fileKindVisual(file.kind.toLowerCase());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: expanded ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4),
            width: expanded ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(visual.icon, size: 11, color: visual.color),
                      const SizedBox(width: 3),
                      Text(
                        file.kind.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: visual.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 15,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              file.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatFileSize(file.sizeBytes),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Icon(
                  file.isWholeDocument ? Icons.select_all : Icons.tune,
                  size: 13,
                  color: expanded ? scheme.primary : scheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
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
          '${context.tr('questionCount')}: ${_questionCountLabel(context)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _maybeFullWidth(
          SegmentedButton<int>(
            segments: [
              const ButtonSegment(value: 5, label: Text('5')),
              const ButtonSegment(value: 10, label: Text('10')),
              const ButtonSegment(value: 15, label: Text('15')),
              const ButtonSegment(value: 20, label: Text('20')),
              ButtonSegment(
                value: QuizWizardData.unlimitedQuestionCount,
                label: Text(context.tr('questionCountMax')),
              ),
            ],
            selected: {wizardData.questionCount},
            onSelectionChanged: (set) => wizardData.setQuestionCount(set.first),
          ),
        ),
      ],
    );
  }

  String _questionCountLabel(BuildContext context) =>
      wizardData.questionCount == QuizWizardData.unlimitedQuestionCount
      ? context.tr('questionCountMaxLabel')
      : '${wizardData.questionCount}';

  Widget _maybeFullWidth(Widget child) =>
      isDesktop ? child : SizedBox(width: double.infinity, child: child);
}

/// Step 4: an Apple-premium receipt card reviewing every choice made so far,
/// plus the public/private visibility choice (with a warning when public)
/// right before the final generate action.
class Step4ReviewView extends StatelessWidget {
  const Step4ReviewView({
    super.key,
    required this.wizardData,
    required this.onGenerate,
  });

  final QuizWizardData wizardData;
  final VoidCallback onGenerate;

  String _difficultyLabel(BuildContext context) {
    switch (wizardData.difficulty) {
      case DifficultyLevel.easy:
        return context.tr('easy');
      case DifficultyLevel.medium:
        return context.tr('medium');
      case DifficultyLevel.hard:
        return context.tr('hard');
    }
  }

  String _questionCountLine(BuildContext context) =>
      wizardData.questionCount == QuizWizardData.unlimitedQuestionCount
      ? context.tr('questionCountMaxLabel')
      : '${wizardData.questionCount} ${context.tr('questionsSuffixLabel')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPublic = wizardData.visibility == QuizVisibility.public;
    final filesValue = wizardData.attachedFiles.isEmpty
        ? context.tr('noFilesAddedYet')
        : context.trParams('reviewFilesCountLabel', {
            'count': '${wizardData.attachedFiles.length}',
            'names': wizardData.attachedFiles.map((f) => f.name).join(', '),
          });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('step4Title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          PremiumHoverCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReceiptRow(
                  label: context.tr('reviewThemeLabel'),
                  value: wizardData.name,
                ),
                Divider(height: 32, color: scheme.outlineVariant.withValues(alpha: 0.3)),
                _ReceiptRow(
                  label: context.tr('reviewSourceLabel'),
                  value: filesValue,
                ),
                Divider(height: 32, color: scheme.outlineVariant.withValues(alpha: 0.3)),
                _ReceiptRow(
                  label: context.tr('reviewLevelLabel'),
                  value: '${_difficultyLabel(context)} • ${_questionCountLine(context)}',
                ),
                Divider(height: 32, color: scheme.outlineVariant.withValues(alpha: 0.3)),
                Text(
                  context.tr('reviewVisibilityLabel'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<QuizVisibility>(
                  segments: [
                    ButtonSegment(
                      value: QuizVisibility.private,
                      label: Text(context.tr('visibilityPrivate')),
                      icon: const Icon(Icons.lock_outline),
                    ),
                    ButtonSegment(
                      value: QuizVisibility.public,
                      label: Text(context.tr('visibilityPublic')),
                      icon: const Icon(Icons.public),
                    ),
                  ],
                  selected: {wizardData.visibility},
                  onSelectionChanged: (set) => wizardData.setVisibility(set.first),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !isPublic
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber.shade800,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.tr('visibilityPublicWarning'),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}

/// One label/value line of the Step 4 receipt card.
class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
