import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:flutter/foundation.dart';

/// Upload is the only real content source: general "AI generates it for me"
/// and "search the web" were removed after confirming neither has any
/// backend support in certifications_api (no general-knowledge generation
/// path, no web-search ingestion path). Kept as an enum (rather than
/// dropping the concept entirely) so a future real source type has a place
/// to slot into.
enum SourceType { uploadFile }

enum DifficultyLevel { easy, medium, hard }

/// One file attached to the study being created in the wizard, together with
/// the portion of it (whole document by default, or a specific page/line/time
/// range) that should actually be used to generate questions.
class AttachedFile {
  AttachedFile({
    required this.bytes,
    required this.name,
    required this.kind,
    this.isWholeDocument = true,
    this.pageStart = 1,
    this.pageEnd = 10,
    this.lineStart = 1,
    this.lineEnd = 50,
    this.audioStartMs = 0,
    this.audioEndMs = 300000, // 5 minutes default
    this.selectionKind = 'all',
    this.selectionSpec = '',
    this.totalPages,
    this.totalLines,
  });

  final List<int> bytes;
  final String name;
  final String kind;

  bool isWholeDocument;
  int pageStart;
  int pageEnd;
  int lineStart;
  int lineEnd;
  int audioStartMs;
  int audioEndMs;
  String selectionKind;
  String selectionSpec;

  /// Real page count for PDFs, computed client-side right after picking the
  /// file so the range selector can show it and clamp its defaults instead
  /// of guessing a fixed 1-10 that may not exist in a short document. Null
  /// for kinds where a page count isn't known (DOCX has no reliable one
  /// without a full layout engine) or couldn't be read.
  int? totalPages;

  /// Real line count for text-based files (txt/md/csv), same reasoning as
  /// [totalPages].
  int? totalLines;
  String? remoteSourceId;
  int selectionRevision = 0;

  int get sizeBytes => bytes.length;
}

class QuizWizardData extends ChangeNotifier {
  int currentStep = 0;
  String name = '';
  SourceType sourceType = SourceType.uploadFile;
  final List<AttachedFile> attachedFiles = [];
  final List<StudySource> existingSources = [];
  DifficultyLevel difficulty = DifficultyLevel.easy;
  int questionCount = 10;
  String? generationLanguage;

  /// Chosen at creation time (Step 4), defaulting to private to match the
  /// backend's own default. Can still be changed later from the completed
  /// quizzes list.
  QuizVisibility visibility = QuizVisibility.private;

  /// Whether the backend should augment question generation with a live web
  /// search. Defaults to false (source material only).
  bool useWeb = false;
  int? accountUsedBytes;
  int? accountMaxBytes;
  int? maxFileBytes;
  int? maxStudyBytes;

  int get totalAttachedBytes => attachedFiles
      .where((file) => file.remoteSourceId == null)
      .fold(0, (sum, file) => sum + file.sizeBytes);

  /// Whether the known backend account allowance would be exceeded by the
  /// selected, not-yet-uploaded files. Unknown allowance is not treated as 0.
  bool wouldExceedAccountQuota(int additionalBytes) =>
      accountUsedBytes != null &&
      accountMaxBytes != null &&
      accountUsedBytes! + totalAttachedBytes + additionalBytes >
          accountMaxBytes!;

  bool wouldExceedFileLimit(int bytes) =>
      maxFileBytes != null && bytes > maxFileBytes!;

  bool wouldExceedStudyQuota(int additionalBytes) =>
      maxStudyBytes != null &&
      existingSources.fold<int>(0, (sum, s) => sum + s.sizeBytes) +
              totalAttachedBytes +
              additionalBytes >
          maxStudyBytes!;

  int? get projectedAccountUsageBytes =>
      accountUsedBytes == null ? null : accountUsedBytes! + totalAttachedBytes;

  void setAccountQuota({
    required int? usedBytes,
    required int? maxBytes,
    int? fileLimitBytes,
    int? studyLimitBytes,
  }) {
    accountUsedBytes = usedBytes;
    accountMaxBytes = maxBytes;
    maxFileBytes = fileLimitBytes;
    maxStudyBytes = studyLimitBytes;
    notifyListeners();
  }

  bool get isStep1Valid => name.trim().isNotEmpty;
  bool get isStep2Valid =>
      attachedFiles.isNotEmpty || existingSources.isNotEmpty;
  bool get isStep3Valid => true;
  bool get isStep4Valid => isStep1Valid && isStep2Valid && isStep3Valid;

  void setStep(int step) {
    if (step >= 0 && step <= 3) {
      currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (currentStep < 3) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setDifficulty(DifficultyLevel level) {
    difficulty = level;
    notifyListeners();
  }

  void setQuestionCount(int count) {
    if (count < 1 || count > 20) return;
    questionCount = count;
    notifyListeners();
  }

  void setGenerationLanguage(String language) {
    if (!const {'en', 'pt-BR', 'th'}.contains(language)) return;
    generationLanguage = language;
    notifyListeners();
  }

  void applyPreparedConfig(PreparedStudyConfig? config) {
    if (config == null) return;
    questionCount = config.count;
    generationLanguage = config.language;
    notifyListeners();
  }

  void setVisibility(QuizVisibility value) {
    visibility = value;
    notifyListeners();
  }

  void setUseWeb(bool value) {
    useWeb = value;
    notifyListeners();
  }

  /// Adds a newly picked file to the attached-files list. Callers may block
  /// only when the backend account allowance is known and would be exceeded.
  void addFile(AttachedFile file) {
    attachedFiles.add(file);
    notifyListeners();
  }

  void setExistingSources(Iterable<StudySource> sources) {
    existingSources
      ..clear()
      ..addAll(sources);
    notifyListeners();
  }

  void addExistingSource(StudySource source) {
    if (existingSources.any((item) => item.id == source.id)) return;
    existingSources.add(source);
    notifyListeners();
  }

  void updateFileSelection(
    AttachedFile file, {
    required bool isWholeDocument,
    required String selectionKind,
    required String selectionSpec,
  }) {
    if (!attachedFiles.any((item) => identical(item, file))) return;
    file.isWholeDocument = isWholeDocument;
    file.selectionKind = selectionKind;
    file.selectionSpec = selectionSpec;
    notifyListeners();
  }

  void restoreFileSelections(
    Iterable<(AttachedFile, String, String)> selections,
  ) {
    var changed = false;
    for (final (file, selectionKind, selectionSpec) in selections) {
      if (!attachedFiles.any((item) => identical(item, file))) continue;
      file.isWholeDocument = false;
      file.selectionKind = selectionKind;
      file.selectionSpec = selectionSpec;
      file.selectionRevision++;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void removeFileAt(int index) {
    if (index < 0 || index >= attachedFiles.length) return;
    attachedFiles.removeAt(index);
    notifyListeners();
  }

  /// Applies one or more range-selection updates to the file at [index] in a
  /// single notification. Pass only the fields that changed; the rest keep
  /// their current value. This is the only place that should ever mutate an
  /// [AttachedFile]'s range fields, so every change funnels through this
  /// object's own [notifyListeners] rather than a widget calling it directly.
  void updateFileRange(
    int index, {
    bool? isWholeDocument,
    int? pageStart,
    int? pageEnd,
    int? lineStart,
    int? lineEnd,
    int? audioStartMs,
    int? audioEndMs,
  }) {
    if (index < 0 || index >= attachedFiles.length) return;
    final file = attachedFiles[index];
    if (isWholeDocument != null) file.isWholeDocument = isWholeDocument;
    if (pageStart != null) file.pageStart = pageStart;
    if (pageEnd != null) file.pageEnd = pageEnd;
    if (lineStart != null) file.lineStart = lineStart;
    if (lineEnd != null) file.lineEnd = lineEnd;
    if (audioStartMs != null) file.audioStartMs = audioStartMs;
    if (audioEndMs != null) file.audioEndMs = audioEndMs;
    notifyListeners();
  }

  void reset() {
    currentStep = 0;
    name = '';
    sourceType = SourceType.uploadFile;
    attachedFiles.clear();
    difficulty = DifficultyLevel.medium;
    questionCount = 10;
    generationLanguage = null;
    visibility = QuizVisibility.private;
    useWeb = false;
    notifyListeners();
  }
}
