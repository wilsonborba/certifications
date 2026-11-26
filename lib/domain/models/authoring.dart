class AuthoringAlternative {
  const AuthoringAlternative({required this.id, required this.text});

  factory AuthoringAlternative.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    if (id is! String || text is! String) {
      throw const FormatException('Invalid question alternative');
    }
    return AuthoringAlternative(id: id, text: text);
  }

  final String id;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

class AuthoringQuestion {
  AuthoringQuestion.fromJson(Map<String, dynamic> json)
    : id = _requiredString(json, 'id'),
      versionId = _requiredString(json, 'version_id'),
      versionNumber = _requiredInt(json, 'version_num'),
      language = _requiredString(json, 'language'),
      origin = _requiredString(json, 'origin'),
      sourceScope = _optionalString(json, 'source_scope'),
      prompt = _requiredString(json, 'prompt'),
      alternatives = _alternatives(json['alternatives']),
      correctId = _requiredString(json, 'correct_id'),
      explanation = _requiredString(json, 'explanation'),
      citationRef = _optionalString(json, 'citation_ref'),
      visuals = ((json['visuals'] as List?) ?? const [])
          .map(
            (value) =>
                QuestionVisual.fromJson((value as Map).cast<String, dynamic>()),
          )
          .toList(growable: false);

  final String id;
  final String versionId;
  final int versionNumber;
  final String language;
  final String origin;
  final String sourceScope;
  final String prompt;
  final List<AuthoringAlternative> alternatives;
  final String correctId;
  final String explanation;
  final String citationRef;
  final List<QuestionVisual> visuals;

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) throw FormatException('Missing question field: $key');
    return value;
  }

  static String _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return '';
    if (value is! String) throw FormatException('Invalid question field: $key');
    return value;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('Missing question field: $key');
    return value;
  }

  static List<AuthoringAlternative> _alternatives(Object? value) {
    if (value is! List) throw const FormatException('Invalid alternatives');
    return value
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid alternative object');
          }
          return AuthoringAlternative.fromJson(item);
        })
        .toList(growable: false);
  }

  Map<String, dynamic> toUpdateJson({
    required String language,
    required String prompt,
    required List<AuthoringAlternative> alternatives,
    required String correctId,
    required String explanation,
    required String citationRef,
  }) => {
    'language': language,
    'prompt': prompt,
    'alternatives': alternatives.map((item) => item.toJson()).toList(),
    'correct_id': correctId,
    'explanation': explanation,
    'citation_ref': citationRef,
  };
}

/// A durable image attached to the current immutable question version.
class QuestionVisual {
  const QuestionVisual({
    required this.id,
    required this.mimeType,
    required this.createdAt,
  });

  factory QuestionVisual.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final mimeType = json['mime_type'];
    final createdAt = json['created_at'];
    if (id is! String ||
        id.isEmpty ||
        mimeType is! String ||
        mimeType != 'image/png' ||
        createdAt is! int) {
      throw const FormatException('Invalid question visual metadata');
    }
    return QuestionVisual(id: id, mimeType: mimeType, createdAt: createdAt);
  }

  final String id;
  final String mimeType;
  final int createdAt;
}

/// The owner-scoped preparation result for the two-step visual upload flow.
class PreparedQuestionVisualJob {
  const PreparedQuestionVisualJob({
    required this.questionId,
    required this.questionVersionId,
    required this.jobId,
    required this.templateId,
    required this.templateVersion,
    required this.width,
    required this.height,
    required this.scale,
    required this.expiresAt,
  });

  factory PreparedQuestionVisualJob.fromJson(Map<String, dynamic> json) {
    final questionId = json['question_id'];
    final versionId = json['question_version_id'];
    final renderJob = json['render_job'];
    if (questionId is! String ||
        questionId.isEmpty ||
        versionId is! String ||
        versionId.isEmpty ||
        renderJob is! Map) {
      throw const FormatException('Invalid prepared question visual job');
    }
    final job = renderJob.cast<String, dynamic>();
    final id = job['job_id'];
    final templateId = job['template_id'];
    final templateVersion = job['template_version'];
    final width = job['width'];
    final height = job['height'];
    final scale = job['scale'];
    final expiresAt = job['expires_at'];
    if (id is! String ||
        id.isEmpty ||
        templateId is! String ||
        templateId.isEmpty ||
        templateVersion is! int ||
        templateVersion < 1 ||
        width is! int ||
        width < 200 ||
        width > 2400 ||
        height is! int ||
        height < 200 ||
        height > 2400 ||
        scale is! int ||
        scale < 1 ||
        scale > 3 ||
        expiresAt is! int ||
        width * scale > 4096 ||
        height * scale > 4096) {
      throw const FormatException('Invalid prepared Reports render job');
    }
    return PreparedQuestionVisualJob(
      questionId: questionId,
      questionVersionId: versionId,
      jobId: id,
      templateId: templateId,
      templateVersion: templateVersion,
      width: width,
      height: height,
      scale: scale,
      expiresAt: expiresAt,
    );
  }

  final String questionId;
  final String questionVersionId;
  final String jobId;
  final String templateId;
  final int templateVersion;
  final int width;
  final int height;
  final int scale;
  final int expiresAt;
}

class CsvPreviewRow {
  const CsvPreviewRow({
    required this.rowNumber,
    required this.language,
    required this.prompt,
    required this.correctId,
  });

  factory CsvPreviewRow.fromJson(Map<String, dynamic> json) {
    final number = json['row_number'];
    if (number is! int) throw const FormatException('Invalid CSV row number');
    return CsvPreviewRow(
      rowNumber: number,
      language: AuthoringQuestion._requiredString(json, 'language'),
      prompt: AuthoringQuestion._requiredString(json, 'prompt'),
      correctId: AuthoringQuestion._requiredString(json, 'correct_id'),
    );
  }

  final int rowNumber;
  final String language;
  final String prompt;
  final String correctId;
}

class CsvInvalidRow {
  const CsvInvalidRow({required this.rowNumber, required this.error});

  factory CsvInvalidRow.fromJson(Map<String, dynamic> json) {
    final number = json['row_number'];
    if (number is! int) throw const FormatException('Invalid CSV row number');
    return CsvInvalidRow(
      rowNumber: number,
      error: AuthoringQuestion._requiredString(json, 'error'),
    );
  }

  final int rowNumber;
  final String error;
}

class CsvImportResult {
  CsvImportResult.fromJson(Map<String, dynamic> json)
    : previewOnly = _bool(json, 'preview_only'),
      importedCount = _int(json, 'imported_count'),
      validRows = _rows<CsvPreviewRow>(
        json,
        'valid_rows',
        CsvPreviewRow.fromJson,
      ),
      invalidRows = _rows<CsvInvalidRow>(
        json,
        'invalid_rows',
        CsvInvalidRow.fromJson,
      ),
      questions = _rows<AuthoringQuestion>(
        json,
        'questions',
        AuthoringQuestion.fromJson,
      );

  final bool previewOnly;
  final int importedCount;
  final List<CsvPreviewRow> validRows;
  final List<CsvInvalidRow> invalidRows;
  final List<AuthoringQuestion> questions;

  static bool _bool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) throw FormatException('Invalid CSV field: $key');
    return value;
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('Invalid CSV field: $key');
    return value;
  }

  static List<T> _rows<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final value = json[key];
    if (value is! List) throw FormatException('Invalid CSV field: $key');
    return value
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw FormatException('Invalid CSV row in $key');
          }
          return parse(item);
        })
        .toList(growable: false);
  }
}

class PublishedQuiz {
  PublishedQuiz.fromJson(Map<String, dynamic> json)
    : id = AuthoringQuestion._requiredString(json, 'id'),
      title = AuthoringQuestion._requiredString(json, 'title'),
      questionCount = AuthoringQuestion._requiredInt(json, 'question_count');

  final String id;
  final String title;
  final int questionCount;
}
