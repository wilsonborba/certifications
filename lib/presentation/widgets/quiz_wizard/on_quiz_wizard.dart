import 'dart:async';

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
  int _generateStep = 0; // tracks which pipeline step is currently running
  String? _generateError;

  Timer? _progressTimer;
  int _questionsGenerated = 0;
  int? _questionsTarget;
  int _chunksDone = 0;
  int _chunksTotal = 0;

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
    _progressTimer?.cancel();
    wizardData.removeListener(_persistDraftState);
    wizardData.dispose();
    super.dispose();
  }

  /// Polls the backend for real "questions generated so far" progress while
  /// the AI generation step runs, instead of leaving the loading screen on a
  /// static message. Cancelled as soon as [_generate] moves past step 3.
  void _startProgressPolling(String studyId) {
    _progressTimer?.cancel();
    _pollProgressOnce(studyId); // don't wait 5s for the first update
    // Polled, not pushed: every 5s is frequent enough to feel live without
    // hammering the backend on a loading screen users may sit on for a while.
    _progressTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollProgressOnce(studyId),
    );
  }

  Future<void> _pollProgressOnce(String studyId) async {
    try {
      final progress = await _api.getGenerationProgress(studyId);
      if (!mounted) return;
      setState(() {
        _questionsGenerated = progress.questionsGenerated;
        _questionsTarget = progress.questionsTarget;
        _chunksDone = progress.chunksDone;
        _chunksTotal = progress.chunksTotal;
      });
    } catch (_) {
      // Best-effort: a missed poll just means the count doesn't tick this
      // round, the loading screen still shows the last known progress.
    }
  }

  /// Maps a raw file extension to the [SourceKind] value the API expects.
  /// The API enum uses semantic names (text, audio, video), not extensions.
  String _apiKind(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'docx':
        return 'docx';
      case 'csv':
        return 'csv';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return 'audio';
      case 'mp4':
      case 'mov':
        return 'video';
      case 'txt':
      case 'md':
      default:
        return 'text';
    }
  }

  /// Returns the MIME type for an [AttachedFile.kind] string (raw extension).
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
      _generateStep = 0; // step 0: creating study
      _generateError = null;
    });

    try {
      // 1. Create study — skip when resuming an existing draft (studyId known).
      final studyId =
          widget.studyId ?? (await _api.create(wizardData.name)).id;

      setState(() => _generateStep = 1); // step 1: uploading files

      // 2. Upload each attached file, then apply granular range if configured.
      for (final file in wizardData.attachedFiles) {
        final source = await _api.upload(
          studyId: studyId,
          kind: _apiKind(file.kind),
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
        }
        // Ingest must always run — it extracts text and flips the source to
        // SourceStatus.ready. Without it, generate returns 422 because no
        // ready source is available, even for whole-document uploads.
        setState(() => _generateStep = 2); // step 2: processing content
        await _api.ingest(studyId, source.id);
      }

      setState(() {
        _generateStep = 3; // step 3: generating questions with AI
        _questionsGenerated = 0;
        _chunksDone = 0;
        _chunksTotal = 0;
        _questionsTarget = wizardData.questionCount == QuizWizardData.unlimitedQuestionCount
            ? null
            : wizardData.questionCount;
      });
      _startProgressPolling(studyId);

      // Generate the questions now so the user stays on the beautiful step-by-step
      // progress screen until the AI completes generation, avoiding any secondary
      // blank circular loading indicator on the question screen.
      final questions = await _api.generateQuestions(
        studyId: studyId,
        difficulty: wizardData.difficulty.name,
        useWeb: wizardData.useWeb,
        idempotencyKey: '${DateTime.now().microsecondsSinceEpoch}-question',
        questionCount: wizardData.questionCount,
      );
      _progressTimer?.cancel();

      // 3. Record last-opened time for the draft-resume hero card.
      await DraftProgressStore.instance.touch(studyId);

      if (!mounted) return;

      // 4. Navigate to the question session with pre-generated questions.
      // We replace the wizard route with QuestionSession so that the wizard
      // is completely unmounted and does not attempt to pop afterwards.
      widget.onGenerate();
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionSession(
            studyId: studyId,
            studyName: wizardData.name,
            difficulty: wizardData.difficulty.name,
            useWeb: wizardData.useWeb,
            questionCount: wizardData.questionCount,
            initialQuestions: questions,
          ),
        ),
      );
    } on StudyApiException catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generateStep = 0;
        _generateError = e.statusCode == 402
            ? context.tr('errorPaymentRequired')
            : context.tr('errorGeneric');
      });
    } catch (_) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generateStep = 0;
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
            currentStep: _generateStep,
            messages: [
              context.tr('loadingCreatingStudy'),
              context.tr('loadingUploadingFiles'),
              context.tr('loadingProcessingContent'),
              context.tr('loadingAlmostReady'),
            ],
            questionsGenerated: _generateStep == 3 ? _questionsGenerated : null,
            questionsTarget: _questionsTarget,
            chunksDone: _chunksDone,
            chunksTotal: _chunksTotal,
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
