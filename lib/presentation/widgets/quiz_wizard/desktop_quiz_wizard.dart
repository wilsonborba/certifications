import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/presentation/components/quiz/quiz_timeline_stepper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DesktopQuizWizard extends StatelessWidget {
  const DesktopQuizWizard({
    super.key,
    required this.wizardData,
    required this.onGenerate,
  });

  final QuizWizardData wizardData;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuizTimelineStepper(wizardData: wizardData, isDesktop: true),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedBuilder(
                animation: wizardData,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildCurrentStepView(context),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildNavigationFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepView(BuildContext context) {
    switch (wizardData.currentStep) {
      case 0:
        return _Step1Theme(wizardData: wizardData);
      case 1:
        return _Step2Source(wizardData: wizardData);
      case 2:
        return _Step3Format(wizardData: wizardData);
      case 3:
        return _Step4Review(wizardData: wizardData, onGenerate: onGenerate);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationFooter(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (wizardData.currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => wizardData.previousStep(),
            icon: const Icon(Icons.arrow_back),
            label: Text(context.tr('close')),
          )
        else
          const SizedBox.shrink(),
        if (wizardData.currentStep < 3)
          ElevatedButton.icon(
            onPressed: wizardData.isStep1Valid
                ? () => wizardData.nextStep()
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(context.tr('next')),
          ),
      ],
    );
  }
}

class _Step1Theme extends StatelessWidget {
  const _Step1Theme({required this.wizardData});
  final QuizWizardData wizardData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final presets = [
      ('☁️ AWS', context.tr('presetAws')),
      ('🐍 Python', context.tr('presetPython')),
      ('📐 ENEM', context.tr('presetEnem')),
      ('⚖️ Direito', context.tr('presetLaw')),
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
        const SizedBox(height: 28),
        Text(
          'Presets Rápido (1 Clique):',
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
              avatar: Text(preset.$1.split(' ')[0]),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: TextEditingController(text: wizardData.name)
            ..selection = TextSelection.collapsed(offset: wizardData.name.length),
          onChanged: (val) {
            wizardData.name = val;
            wizardData.categoryPreset = '';
          },
          decoration: InputDecoration(
            labelText: context.tr('studyName'),
            hintText: 'ex: Arquitetura de Software / Biologia Celular',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }
}

class _Step2Source extends StatelessWidget {
  const _Step2Source({required this.wizardData});
  final QuizWizardData wizardData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: wizardData.sourceType == SourceType.uploadFile
                    ? scheme.primary
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            title: Text(context.tr('sourceUpload')),
            subtitle: Text(wizardData.fileName ?? 'PDF, DOCX, CSV, TXT, MD, MP3, MP4'),
            leading: const Icon(Icons.upload_file),
            selected: wizardData.sourceType == SourceType.uploadFile,
            onTap: () async {
              wizardData.setSourceType(SourceType.uploadFile);
              final result = await FilePicker.platform.pickFiles(withData: true);
              if (result?.files.single != null) {
                final file = result!.files.single;
                final ext = file.extension?.toLowerCase() ?? 'pdf';
                wizardData.setFile(
                  bytes: file.bytes!,
                  name: file.name,
                  kind: ext,
                );
              }
            },
          ),
          const SizedBox(height: 10),
          ListTile(
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

class _Step3Format extends StatelessWidget {
  const _Step3Format({required this.wizardData});
  final QuizWizardData wizardData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          'Dificuldade:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
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
          onSelectionChanged: (set) {
            wizardData.difficulty = set.first;
          },
        ),
        const SizedBox(height: 28),
        Text(
          '${context.tr('questionCount')}: ${wizardData.questionCount}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: wizardData.questionCount.toDouble(),
          min: 5,
          max: 20,
          divisions: 3,
          label: '${wizardData.questionCount}',
          onChanged: (val) {
            wizardData.questionCount = val.toInt();
          },
        ),
      ],
    );
  }
}

class _Step4Review extends StatelessWidget {
  const _Step4Review({required this.wizardData, required this.onGenerate});
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
              Text('📌 Tema: ${wizardData.name.isEmpty ? wizardData.categoryPreset : wizardData.name}'),
              const SizedBox(height: 8),
              Text('📄 Fonte: ${wizardData.sourceType.name} ${wizardData.fileName ?? ''}'),
              const SizedBox(height: 8),
              Text('🎯 Nível: ${wizardData.difficulty.name} • ${wizardData.questionCount} Questões'),
            ],
          ),
        ),
        const Spacer(),
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
