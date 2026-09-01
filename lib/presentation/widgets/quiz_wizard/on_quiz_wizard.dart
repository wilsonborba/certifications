import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/quiz/futuristic_loading.dart';
import 'package:certifications/presentation/widgets/question_session.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/desktop_quiz_wizard.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/mobile_quiz_wizard.dart';
import 'package:flutter/material.dart';

class OnQuizWizardScreen extends StatefulWidget {
  const OnQuizWizardScreen({
    super.key,
    required this.onGenerate,
    this.studyId,
    this.initialName,
    this.initialStep = 0,
  });

  /// Called after the study is created and the quiz session is finished, so
  /// the caller (dashboard) can reload its list. This is now a post-success
  /// hook only — the actual generate work happens inside this screen.
  final VoidCallback onGenerate;

  /// The draft study being resumed, if any. When set the wizard's current
  /// step is persisted against this id via [DraftProgressStore] as the user
  /// navigates, so a later "Resume" lands back on the same step.
  /// When set, study creation is skipped — we upload directly to this id.
  final String? studyId;

  /// Pre-fills the topic step, e.g. when resuming a draft study.
  final String? initialName;

  /// Wizard step (0-3) to land on when opened, e.g. the step a draft study
  /// was left on.
  final int initialStep;

  @override
  State<OnQuizWizardScreen> createState() => _OnQuizWizardScreenState();
}

class _OnQuizWizardScreenState extends State<OnQuizWizardScreen> {
  final _api = StudyApiService();

  late final wizardData = QuizWizardData()
    ..name = widget.initialName ?? ''
    ..currentStep = widget.initialStep.clamp(0, 3);

  bool _generating = false;
  String? _generateError;

  @override
  void initState() {
    super.initState();
    if (widget.studyId != null) {
      wizardData.addListener(_persistDraftState);
    }
  }

  void _persistDraftState() {
    final studyId = widget.studyId;
    if (studyId != null) {
      DraftProgressStore.instance.saveStep(studyId, wizardData.currentStep);
      DraftProgressStore.instance.saveVisibility(studyId, wizardData.visibility);
    }
  }

  @override
  void dispose() {
    wizardData.removeListener(_persistDraftState);
    wizardData.dispose();
    super.dispose();
  }

  /// Returns the MIME type for an [AttachedFile.kind] string.
  String _mimeType(String kind) {
    switch (kind.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'csv':
        return 'text/csv';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'txt':
      case 'md':
      default:
        return 'text/plain';
    }
  }

  /// Converts an [AttachedFile]'s range fields into the selection map the
  /// backend expects, keyed by kind: pdf → page_start/page_end, audio →
  /// audio_start_ms/audio_end_ms, text/other → line_start/line_end.
  Map<String, int> _rangeSelection(AttachedFile file) {
    switch (file.kind.toLowerCase()) {
      case 'pdf':
        return {'page_start': file.pageStart, 'page_end': file.pageEnd};
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'mp4':
      case 'mov':
        return {
          'audio_start_ms': file.audioStartMs,
          'audio_end_ms': file.audioEndMs,
        };
      default:
        return {'line_start': file.lineStart, 'line_end': file.lineEnd};
    }
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _generateError = null;
    });

    try {
      // 1. Create study — skip when resuming an existing draft (studyId known).
      final studyId =
          widget.studyId ?? (await _api.create(wizardData.name)).id;

      // 2. Upload each attached file, then apply granular range if configured.
      for (final file in wizardData.attachedFiles) {
        final source = await _api.upload(
          studyId: studyId,
          kind: file.kind,
          filename: file.name,
          bytes: file.bytes,
          mimeType: _mimeType(file.kind),
        );

        if (!file.isWholeDocument) {
          await _api.select(
            studyId: studyId,
            sourceId: source.id,
            selection: _rangeSelection(file),
          );
          await _api.ingest(studyId, source.id);
        }
      }

      // 3. Record last-opened time for the draft-resume hero card.
      await DraftProgressStore.instance.touch(studyId);

      if (!mounted) return;

      // 4. Navigate to the question session. The whole generate/answer/result
      //    flow happens inside QuestionSession → QuizResultScreen, so we push
      //    and wait for the user to finish (pop back to us) before notifying
      //    the dashboard.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionSession(
            studyId: studyId,
            studyName: wizardData.name,
            difficulty: wizardData.difficulty.name,
            useWeb: wizardData.useWeb,
            questionCount: wizardData.questionCount,
          ),
        ),
      );

      if (!mounted) return;

      // 5. Notify the caller (dashboard) to refresh its list, then close the
      //    wizard so the user lands back on a refreshed dashboard.
      widget.onGenerate();
      Navigator.pop(context);
    } on StudyApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generateError = e.statusCode == 402
            ? context.tr('errorPaymentRequired')
            : context.tr('errorGeneric');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generateError = context.tr('errorGeneric');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    // Show the futuristic loading overlay while the async generate sequence
    // (create study → upload files → ingest → navigate to session) is running.
    if (_generating) {
      return Scaffold(
        appBar: AttachmentAppBar(title: context.tr('wizardTitle')),
        body: SafeArea(
          child: FuturisticLoading(
            messages: [
              context.tr('loadingCreatingStudy'),
              context.tr('loadingUploadingFiles'),
              context.tr('loadingProcessingContent'),
              context.tr('loadingAlmostReady'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('wizardTitle')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isDesktop
              ? DesktopQuizWizard(
                  wizardData: wizardData,
                  onGenerate: _generate,
                  generateError: _generateError,
                )
              : MobileQuizWizard(
                  wizardData: wizardData,
                  onGenerate: _generate,
                  generateError: _generateError,
                ),
        ),
      ),
    );
  }
}
