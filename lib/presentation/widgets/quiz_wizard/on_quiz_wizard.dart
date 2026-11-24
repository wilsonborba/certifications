import 'dart:async';
import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/models/study_selection.dart';
import 'package:certifications/domain/services/client_telemetry_service.dart';
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
    this.apiService,
    this.draft,
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

  /// Optional service and draft seams for isolated review and contract tests.
  final StudyApiService? apiService;
  final QuizWizardData? draft;

  @override
  State<OnQuizWizardScreen> createState() => _OnQuizWizardScreenState();
}

class _OnQuizWizardScreenState extends State<OnQuizWizardScreen> {
  late final _api = widget.apiService ?? StudyApiService();

  late final wizardData =
      widget.draft ??
      (QuizWizardData()
        ..name = widget.initialName ?? ''
        ..currentStep = widget.initialStep.clamp(0, 3));

  bool _generating = false;
  bool _analyzingSources = false;
  bool _analysisComplete = false;
  String? _analysisStatus;
  int _inspectedSources = 0;
  int _inspectedPages = 0;
  int _inspectedCharacters = 0;
  String? _activeStudyId;
  int _generateStep = 0; // tracks which pipeline step is currently running
  String? _generateError;

  Timer? _progressTimer;
  int _questionsGenerated = 0;
  int? _questionsTarget;
  int _chunksDone = 0;
  int _chunksTotal = 0;
  double? _uploadProgress;
  int _uploadFileIndex = 0;
  Future<void>? _draftPreparation;

  @override
  void initState() {
    super.initState();
    _activeStudyId = widget.studyId;
    wizardData.addListener(_persistDraftState);
    if (widget.studyId != null) {
      _loadExistingStudy(widget.studyId!);
    }
  }

  Future<void> _loadExistingStudy(String studyId) async {
    try {
      final study = await _api.get(studyId);
      if (!mounted) return;
      if (wizardData.name.isEmpty && study.name.isNotEmpty) {
        wizardData.name = study.name;
      }
      wizardData.setAccountQuota(
        usedBytes: study.accountUsedBytes,
        maxBytes: study.accountMaxBytes,
        fileLimitBytes: study.maxFileBytes,
        studyLimitBytes: study.maxStudyBytes,
      );
      wizardData.setExistingSources(study.sources);
    } catch (_) {
      // Keep quota explicitly unavailable when the backend cannot provide it.
    }
  }

  Future<void> _ensureStudyDraft() async {
    if (_activeStudyId != null) return;
    final pending = _draftPreparation;
    if (pending != null) return pending;
    final operation = () async {
      final study = await _api.create(wizardData.name);
      if (!mounted) return;
      _activeStudyId = study.id;
      wizardData.setAccountQuota(
        usedBytes: study.accountUsedBytes,
        maxBytes: study.accountMaxBytes,
        fileLimitBytes: study.maxFileBytes,
        studyLimitBytes: study.maxStudyBytes,
      );
      wizardData.setExistingSources(study.sources);
      DraftProgressStore.instance.saveStep(study.id, wizardData.currentStep);
      DraftProgressStore.instance.saveVisibility(
        study.id,
        wizardData.visibility,
      );
    }();
    _draftPreparation = operation;
    try {
      await operation;
    } finally {
      if (identical(_draftPreparation, operation)) _draftPreparation = null;
    }
  }

  void _persistDraftState() {
    final studyId = _activeStudyId;
    if (studyId != null) {
      DraftProgressStore.instance.saveStep(studyId, wizardData.currentStep);
      DraftProgressStore.instance.saveVisibility(
        studyId,
        wizardData.visibility,
      );
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

  /// Matches the Rust API's content-type allowlist for uploaded sources.
  String _mimeType(String kind) {
    switch (kind.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      case 'md':
        return 'text/markdown';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'txt':
      default:
        return 'text/plain';
    }
  }

  Future<void> _uploadAttachedFiles(String studyId) async {
    for (var index = 0; index < wizardData.attachedFiles.length; index++) {
      final file = wizardData.attachedFiles[index];
      setState(() {
        _uploadFileIndex = index;
        _uploadProgress = null;
      });
      final selectionKind = file.isWholeDocument ? 'all' : file.selectionKind;
      final selectionSpec = file.isWholeDocument
          ? ''
          : _canonicalSelection(file);
      if (!file.isWholeDocument && selectionSpec.isEmpty) {
        throw const FormatException('Invalid source selection');
      }
      var source = file.remoteSourceId == null
          ? await _api.upload(
              studyId: studyId,
              filename: file.name,
              bytes: file.bytes,
              mimeType: _mimeType(file.kind),
              onProgress: (progress) {
                if (!mounted) return;
                setState(() => _uploadProgress = progress);
              },
            )
          : await _api.getSource(studyId, file.remoteSourceId!);
      file.remoteSourceId = source.id;
      if (source.selectionKind != selectionKind ||
          source.selectionSpec != selectionSpec) {
        source = await _api.select(
          studyId: studyId,
          sourceId: source.id,
          kind: selectionKind,
          spec: selectionSpec,
        );
      }
      file.remoteSourceId = source.id;
      wizardData.addExistingSource(source);
      final refreshed = await _api.get(studyId);
      wizardData.setAccountQuota(
        usedBytes: refreshed.accountUsedBytes,
        maxBytes: refreshed.accountMaxBytes,
        fileLimitBytes: refreshed.maxFileBytes,
        studyLimitBytes: refreshed.maxStudyBytes,
      );
      wizardData.setExistingSources(refreshed.sources);
    }
  }

  String _canonicalSelection(AttachedFile file) {
    switch (file.selectionKind) {
      case 'pages':
        return StudySelection.pages(
              file.selectionSpec,
              pageCount: file.totalPages,
            ) ??
            '';
      case 'passages':
        return StudySelection.passage(
              file.selectionSpec,
              StudySelection.normalizeText(utf8.decode(file.bytes)),
            ) ??
            '';
      case 'intervals':
        return StudySelection.audio(file.selectionSpec) ?? '';
      default:
        return '';
    }
  }

  Future<void> _inspectSources() async {
    if (_analyzingSources || _generating) return;
    setState(() {
      _analyzingSources = true;
      _analysisComplete = false;
      _analysisStatus = context.tr('sourceInspectionStarting');
      _inspectedSources = 0;
      _inspectedPages = 0;
      _inspectedCharacters = 0;
    });
    try {
      await _ensureStudyDraft();
      final studyId = _activeStudyId;
      if (studyId == null) {
        throw const FormatException('Study draft unavailable');
      }
      await _uploadAttachedFiles(studyId);
      await _api.streamAnalysis(
        studyId,
        onEvent: (event) {
          if (!mounted) return;
          switch (event.name) {
            case 'stage':
              setState(
                () => _analysisStatus = context.tr('sourceInspectionRunning'),
              );
              break;
            case 'source_inspected':
              setState(() {
                _inspectedSources++;
                _inspectedPages +=
                    (event.data['page_count'] as num?)?.toInt() ?? 0;
                _inspectedCharacters +=
                    (event.data['text_char_count'] as num?)?.toInt() ?? 0;
                _analysisStatus = context.tr('sourceInspectionRunning');
              });
              break;
            case 'error':
              setState(
                () => _analysisStatus = context.tr('sourceInspectionError'),
              );
              break;
            case 'complete':
              setState(() {
                _analysisComplete = true;
                _analysisStatus = context.trParams('sourceInspectionComplete', {
                  'count':
                      '${event.data['inspected_sources'] ?? _inspectedSources}',
                  'pages': '$_inspectedPages',
                  'characters': '$_inspectedCharacters',
                });
              });
              break;
          }
        },
      );
      if (!_analysisComplete && mounted) {
        setState(() => _analysisStatus = context.tr('sourceInspectionError'));
      }
    } on StudyApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _analysisStatus = error.statusCode == 404 || error.statusCode == 405
            ? context.tr('sourceInspectionUnavailable')
            : context.tr('sourceInspectionError');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _analysisStatus = context.tr('sourceInspectionError'));
    } finally {
      if (mounted) setState(() => _analyzingSources = false);
    }
  }

  Future<void> _generate() async {
    if (_analyzingSources) return;
    setState(() {
      _generating = true;
      _generateStep = 0; // step 0: preparing the saved study
      _generateError = null;
    });

    try {
      // 1. Reuse the draft opened before source selection, or create one as a
      // fallback when generation is started directly.
      final studyId = _activeStudyId ?? (await _api.create(wizardData.name)).id;
      _activeStudyId = studyId;

      setState(() => _generateStep = 1); // step 1: uploading files

      // 2. Upload each local source once, reusing persisted draft sources on
      // retries or after an optional source inspection.
      await _uploadAttachedFiles(studyId);

      setState(() {
        _generateStep = 2; // step 2: generating questions with AI
        _questionsGenerated = 0;
        _chunksDone = 0;
        _chunksTotal = 0;
        _questionsTarget = wizardData.questionCount;
      });
      _startProgressPolling(studyId);

      List<StudyQuestion> questions;
      try {
        questions = await _api.generateQuestions(
          studyId: studyId,
          difficulty: wizardData.difficulty.name,
          useWeb: wizardData.useWeb,
          idempotencyKey: '${DateTime.now().microsecondsSinceEpoch}-question',
          questionCount: wizardData.questionCount,
        );
      } catch (e) {
        // Immediate client/auth/quota errors should not enter recovery loop
        if (e is StudyApiException &&
            (e.statusCode == 400 ||
                e.statusCode == 401 ||
                e.statusCode == 402 ||
                e.statusCode == 403 ||
                e.statusCode == 404 ||
                e.statusCode == 422 ||
                e.statusCode == 429)) {
          rethrow;
        }

        // If the HTTP connection dropped or timed out on client while server continued
        // (e.g. Cloudflare 100s proxy timeout 524, 504 Gateway Timeout, or network drop),
        // poll until generation completes on the server or fails.
        List<StudyQuestion> recovered = [];
        final deadline = DateTime.now().add(const Duration(minutes: 6));
        while (DateTime.now().isBefore(deadline)) {
          await Future.delayed(const Duration(seconds: 4));
          if (!mounted) return;
          try {
            final progress = await _api.getGenerationProgress(studyId);
            if (mounted) {
              setState(() {
                _questionsGenerated = progress.questionsGenerated;
                _questionsTarget = progress.questionsTarget;
                _chunksDone = progress.chunksDone;
                _chunksTotal = progress.chunksTotal;
              });
            }
            if (progress.status == 'error') {
              rethrow;
            }
            if (progress.status == 'ready' || progress.questionsGenerated > 0) {
              final list = await _api.getQuestions(studyId);
              if (list.isNotEmpty &&
                  (progress.status == 'ready' ||
                      list.length >= wizardData.questionCount)) {
                recovered = list;
                break;
              }
            }
          } catch (pollErr) {
            if (pollErr is StudyApiException && pollErr.statusCode == 404) {
              rethrow;
            }
            // Direct check for questions
            final list = await _api
                .getQuestions(studyId)
                .catchError((_) => <StudyQuestion>[]);
            if (list.isNotEmpty) {
              recovered = list;
              break;
            }
          }
        }
        if (recovered.isNotEmpty) {
          questions = recovered;
        } else {
          rethrow;
        }
      }
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
    } on StudyApiException catch (e, stack) {
      _progressTimer?.cancel();
      ClientTelemetryService.instance.reportHandledError(
        title: 'Quiz Wizard API Failure (${e.statusCode})',
        error: e.message ?? e.toString(),
        stackTrace: stack,
        errorCode: 'STUDY_API_${e.statusCode}',
        requestId: e.requestId,
        route: '/quiz_wizard',
        details: {
          'status_code': e.statusCode,
          'message': e.message,
          'study_id': widget.studyId,
        },
      );
      if (!mounted) return;
      setState(() {
        _generating = false;
        _generateStep = 0;
        _generateError = e.statusCode == 402
            ? context.tr('errorPaymentRequired')
            : (e.message != null && e.message!.isNotEmpty
                  ? e.message
                  : context.tr('errorGeneric'));
      });
    } catch (e, stack) {
      _progressTimer?.cancel();
      ClientTelemetryService.instance.reportHandledError(
        title: 'Quiz Wizard Unhandled Error',
        error: e.toString(),
        stackTrace: stack,
        errorCode: 'WIZARD_EXCEPTION',
        route: '/quiz_wizard',
        details: {'study_id': widget.studyId},
      );
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
              context.tr('loadingAlmostReady'),
            ],
            questionsGenerated: _generateStep == 2 ? _questionsGenerated : null,
            questionsTarget: _questionsTarget,
            chunksDone: _chunksDone,
            chunksTotal: _chunksTotal,
            uploadProgress: _generateStep == 1 ? _uploadProgress : null,
            uploadFileIndex: _uploadFileIndex,
            uploadFileCount: wizardData.attachedFiles.length,
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
                  onPrepareSources: _ensureStudyDraft,
                  onInspectSources: _inspectSources,
                  isInspectingSources: _analyzingSources,
                  inspectionStatus: _analysisStatus,
                  uploadProgress: _analyzingSources ? _uploadProgress : null,
                  onGenerate: _generate,
                  generateError: _generateError,
                )
              : MobileQuizWizard(
                  wizardData: wizardData,
                  onPrepareSources: _ensureStudyDraft,
                  onInspectSources: _inspectSources,
                  isInspectingSources: _analyzingSources,
                  inspectionStatus: _analysisStatus,
                  uploadProgress: _analyzingSources ? _uploadProgress : null,
                  onGenerate: _generate,
                  generateError: _generateError,
                ),
        ),
      ),
    );
  }
}
