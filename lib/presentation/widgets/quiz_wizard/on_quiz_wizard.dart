import 'dart:async';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/services/client_telemetry_service.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/models/generation.dart';
import 'package:certifications/domain/services/generation_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/quiz/futuristic_loading.dart';
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
    this.generationApi,
    this.progressStore,
    this.draft,
  });

  /// Called after a generation job is durably created or resumed so the
  /// caller (dashboard) can reload its study list.
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
  final GenerationApiService? generationApi;
  final DraftProgressStore? progressStore;
  final QuizWizardData? draft;

  @override
  State<OnQuizWizardScreen> createState() => _OnQuizWizardScreenState();
}

class _OnQuizWizardScreenState extends State<OnQuizWizardScreen> {
  late final _api = widget.apiService ?? StudyApiService();
  late final _generationApi = widget.generationApi ?? GenerationApiService();
  late final _progressStore =
      widget.progressStore ?? DraftProgressStore.instance;

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
      _progressStore.saveStep(study.id, wizardData.currentStep);
      _progressStore.saveVisibility(study.id, wizardData.visibility);
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
      _progressStore.saveStep(studyId, wizardData.currentStep);
      _progressStore.saveVisibility(studyId, wizardData.visibility);
    }
  }

  @override
  void dispose() {
    wizardData.removeListener(_persistDraftState);
    wizardData.dispose();
    super.dispose();
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
      final source = file.remoteSourceId == null
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
      // The current backend stores selection specs without enforcing their
      // meaning. Until the producer contract is available, new uploads keep
      // the backend's default whole-source selection and send no guessed spec.
      wizardData.addExistingSource(source);
      final refreshed = await _api.get(studyId);
      wizardData.setAccountQuota(
        usedBytes: refreshed.accountUsedBytes,
        maxBytes: refreshed.accountMaxBytes,
        fileLimitBytes: refreshed.maxFileBytes,
        studyLimitBytes: refreshed.maxStudyBytes,
      );
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
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _generating = true;
      _generateStep = 0;
      _generateError = null;
    });

    try {
      final studyId = _activeStudyId ?? (await _api.create(wizardData.name)).id;
      _activeStudyId = studyId;

      // A browser refresh or navigation back must resume the existing server
      // job instead of creating a second generation request.
      final savedJobId = await _progressStore.getGenerationJobId(studyId);
      if (savedJobId != null && savedJobId.isNotEmpty) {
        try {
          await _generationApi.get(savedJobId);
          await _openGeneration(studyId, savedJobId);
          return;
        } on GenerationApiException catch (error) {
          if (error.statusCode != 404) rethrow;
          await _progressStore.clearGenerationJobId(studyId);
        }
      }

      setState(() => _generateStep = 1);
      await _uploadAttachedFiles(studyId);
      setState(() => _generateStep = 2);

      // Persist before POST so a network timeout retries with the same key.
      var idempotencyKey = await _progressStore.getGenerationIdempotencyKey(
        studyId,
      );
      if (idempotencyKey == null || idempotencyKey.isEmpty) {
        idempotencyKey = '${DateTime.now().microsecondsSinceEpoch}-generation';
        await _progressStore.saveGenerationIdempotencyKey(
          studyId,
          idempotencyKey,
        );
      }
      final language = switch (locale) {
        'pt' => 'pt-BR',
        'th' => 'th',
        _ => 'en',
      };
      final job = await _generationApi.start(
        studyId,
        StartGenerationRequest(
          language: language,
          count: wizardData.questionCount,
          idempotencyKey: idempotencyKey,
        ),
      );
      await _progressStore.saveGenerationJobId(studyId, job.id);
      await _progressStore.clearGenerationIdempotencyKey(studyId);
      await _progressStore.touch(studyId);
      await _openGeneration(studyId, job.id);
    } on StudyApiException catch (e, stack) {
      _showGenerateError(e.message, e.statusCode, e.requestId, stack);
    } on GenerationApiException catch (e, stack) {
      _showGenerateError(e.message, e.statusCode, null, stack);
    } catch (e, stack) {
      ClientTelemetryService.instance.reportHandledError(
        title: 'Quiz Wizard Unhandled Error',
        error: e.toString(),
        stackTrace: stack,
        errorCode: 'WIZARD_EXCEPTION',
        route: '/quiz_wizard',
        details: {'study_id': _activeStudyId},
      );
      if (mounted) {
        setState(() {
          _generating = false;
          _generateStep = 0;
          _generateError = context.tr('errorGeneric');
        });
      }
    }
  }

  Future<void> _openGeneration(String studyId, String jobId) async {
    if (!mounted) return;
    await _progressStore.touch(studyId);
    if (!mounted) return;
    widget.onGenerate();
    await Navigator.pushReplacementNamed(
      context,
      '/v1/generations/${Uri.encodeComponent(jobId)}',
    );
  }

  void _showGenerateError(
    String? message,
    int statusCode,
    String? requestId,
    StackTrace stack,
  ) {
    ClientTelemetryService.instance.reportHandledError(
      title: 'Quiz Wizard Generation API Failure ($statusCode)',
      error: message ?? 'Generation request failed',
      stackTrace: stack,
      errorCode: 'GENERATION_API_$statusCode',
      requestId: requestId,
      route: '/quiz_wizard',
      details: {'status_code': statusCode, 'study_id': _activeStudyId},
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      _generateStep = 0;
      _generateError = statusCode == 402
          ? context.tr('errorPaymentRequired')
          : (message != null && message.isNotEmpty
                ? message
                : context.tr('errorGeneric'));
    });
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
              context.tr('generationStarting'),
            ],
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
