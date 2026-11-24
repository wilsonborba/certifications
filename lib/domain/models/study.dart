/// Source record returned by Certifications API `/studies/{id}`.
class StudySource {
  StudySource.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      filename = json['filename'] as String? ?? '',
      mimeType = json['mime_type'] as String? ?? 'application/octet-stream',
      sizeBytes = (json['size_bytes'] as num? ?? 0).toInt(),
      sha256 = json['sha256'] as String? ?? '',
      sourceKind = json['source_kind'] as String? ?? 'upload',
      status = json['status'] as String? ?? 'unknown',
      selectionKind = json['selection_kind'] as String? ?? 'all',
      selectionSpec = json['selection_spec'] as String? ?? '',
      isRestricted = json['is_restricted'] as bool? ?? false,
      externalRef = json['external_ref'] as String? ?? '';

  final String id;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final String sourceKind;
  final String status;
  final String selectionKind;
  final String selectionSpec;
  final bool isRestricted;
  final String externalRef;

  /// File category used by existing study cards. The Rust DTO exposes MIME
  /// type rather than the legacy `kind` field.
  String get kind {
    if (mimeType == 'application/pdf') return 'pdf';
    if (mimeType ==
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return 'docx';
    }
    if (mimeType ==
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      return 'xlsx';
    }
    if (mimeType == 'text/csv') return 'csv';
    if (mimeType == 'text/markdown') return 'md';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('image/')) return 'image';
    return 'text';
  }

  Map<String, dynamic> get selection => {
    'kind': selectionKind,
    'spec': selectionSpec,
  };
}

class StudySourcePreview {
  StudySourcePreview.fromJson(Map<String, dynamic> json)
    : sourceId = json['source_id'] as String,
      filename = json['filename'] as String? ?? '',
      mimeType = json['mime_type'] as String? ?? 'application/octet-stream',
      sizeBytes = (json['size_bytes'] as num? ?? 0).toInt(),
      selectionKind = json['selection_kind'] as String? ?? 'all',
      selectionSpec = json['selection_spec'] as String? ?? '',
      preview = json['preview'] as String? ?? '';

  final String sourceId;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final String selectionKind;
  final String selectionSpec;
  final String preview;
}

/// Caller-readable Reports descriptor returned by the Certifications picker.
class ReportPickerItem {
  const ReportPickerItem({
    required this.project,
    required this.report,
    required this.title,
    required this.isRestricted,
  });

  factory ReportPickerItem.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    final report = json['report'];
    final title = json['title'];
    final restricted = json['is_restricted'];
    if (project is! String ||
        report is! String ||
        title is! String ||
        restricted is! bool) {
      throw const FormatException('Invalid Reports picker item');
    }
    return ReportPickerItem(
      project: project,
      report: report,
      title: title,
      isRestricted: restricted,
    );
  }

  final String project;
  final String report;
  final String title;
  final bool isRestricted;
}

/// Dataset descriptor from `GET /reports/picker?project=…&report=…`.
class ReportDatasetPickerItem {
  const ReportDatasetPickerItem({
    required this.project,
    required this.report,
    required this.datasetId,
    required this.title,
    required this.canView,
    required this.visibility,
  });

  factory ReportDatasetPickerItem.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    final report = json['report'];
    final rawDataset = json['dataset'];
    if (project is! String || report is! String || rawDataset is! Map) {
      throw const FormatException('Invalid Reports dataset picker item');
    }
    final dataset = rawDataset.cast<String, dynamic>();
    final id = dataset['dataset_id'];
    final title = dataset['title'];
    final canView = dataset['can_view'];
    final visibility = dataset['visibility'];
    if (id is! String ||
        title is! String ||
        canView is! bool ||
        visibility is! String) {
      throw const FormatException('Invalid Reports dataset descriptor');
    }
    return ReportDatasetPickerItem(
      project: project,
      report: report,
      datasetId: id,
      title: title,
      canView: canView,
      visibility: visibility,
    );
  }

  final String project;
  final String report;
  final String datasetId;
  final String title;
  final bool canView;
  final String visibility;

  String get externalRef => '$project/$report/$datasetId';
}

class StudyAnalysisEvent {
  const StudyAnalysisEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;

  String? get stage => data['stage'] as String?;
}

/// Study summary or detail returned by the Rust Studies API.
///
/// Detail responses nest the `study` summary and include `sources` and `quota`;
/// create/list responses return the summary directly/in an `items` list.
class Study {
  Study.fromJson(Map<String, dynamic> json)
    : _study = (json['study'] as Map?)?.cast<String, dynamic>() ?? json,
      sources = ((json['sources'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(StudySource.fromJson)
          .toList(),
      _quota = (json['quota'] as Map?)?.cast<String, dynamic>(),
      _hasSourcesField = json.containsKey('sources');

  final Map<String, dynamic> _study;
  final Map<String, dynamic>? _quota;
  final bool _hasSourcesField;
  final List<StudySource> sources;

  String get id => _study['id'] as String;
  String get name => _study['title'] as String? ?? '';
  String get description => _study['description'] as String? ?? '';
  String get status => _study['status'] as String? ?? 'unknown';
  String get sourceOrigin => _study['source_origin'] as String? ?? '';
  String get quizId => _study['quiz_id'] as String? ?? '';

  /// Detail-only source totals. List summaries omit source bytes, so zero is
  /// only a display total when [hasSourceByteTotals] is true.
  int? get activeSizeBytes => _hasSourcesField
      ? sources.fold<int>(0, (sum, source) => sum + source.sizeBytes)
      : null;
  bool get hasSourceByteTotals => _hasSourcesField;

  /// Quota meter values are authoritative only on detail responses. Account
  /// usage includes both committed and currently reserved bytes.
  int? get accountUsedBytes {
    final quota = _quota;
    if (quota == null || !quota.containsKey('used_bytes')) return null;
    return (quota['used_bytes'] as num).toInt() +
        ((quota['reserved_bytes'] as num?)?.toInt() ?? 0);
  }

  int? get accountMaxBytes => (_quota?['max_account_bytes'] as num?)?.toInt();
  int? get maxFileBytes => (_quota?['max_file_bytes'] as num?)?.toInt();
  int? get maxStudyBytes => (_quota?['max_study_bytes'] as num?)?.toInt();
  int? get remainingAccountBytes =>
      (_quota?['remaining_account_bytes'] as num?)?.toInt();
  int? get retainedSizeBytes => null;
  DateTime? get createdAt {
    final value = _study['created_at'];
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt() * 1000,
        isUtc: true,
      );
    }
    return value is String ? DateTime.tryParse(value) : null;
  }
}

/// One source backing a question, either the uploaded study material or a
/// real page supplied during generation.
class QuestionCitation {
  QuestionCitation.fromJson(Map<String, dynamic> json)
    : source = json['source'] as String? ?? 'Study material',
      selection = json['selection'] as String? ?? '';

  final String source;
  final String selection;

  bool get isWeb =>
      source.startsWith('http://') || source.startsWith('https://');
}

class StudyQuestion {
  StudyQuestion.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      prompt = json['prompt'] as String,
      choices = (json['choices'] as List).cast<String>(),
      visual =
          (json['visual'] as Map?)?.cast<String, dynamic>() ??
          const {'kind': 'none'},
      citations =
          (json['citations'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(QuestionCitation.fromJson)
              .toList() ??
          const [];

  final String id;
  final String prompt;
  final List<String> choices;
  final Map<String, dynamic> visual;
  final List<QuestionCitation> citations;
}

class GenerationProgress {
  GenerationProgress.fromJson(Map<String, dynamic> json)
    : status = json['status'] as String? ?? 'idle',
      chunksDone = json['chunks_done'] as int? ?? 0,
      chunksTotal = json['chunks_total'] as int? ?? 0,
      questionsGenerated = json['questions_generated'] as int? ?? 0,
      questionsTarget = json['questions_target'] as int?;

  final String status;
  final int chunksDone;
  final int chunksTotal;
  final int questionsGenerated;
  final int? questionsTarget;
}
