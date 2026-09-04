class StudySource {
  StudySource.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      filename = json['filename'] as String,
      status = json['status'] as String,
      sizeBytes = (json['size_bytes'] as num).toInt(),
      selection = json['selection'] as Map<String, dynamic>?;
  final String id, kind, filename, status;
  final int sizeBytes;
  final Map<String, dynamic>? selection;
}

class Study {
  Study.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      status = json['status'] as String,
      activeSizeBytes = (json['active_size_bytes'] as num? ?? 0).toInt(),
      createdAt = json['created_at'] as String?,
      sources = ((json['sources'] as List? ?? []).cast<Map<String, dynamic>>())
          .map(StudySource.fromJson)
          .toList();
  final String id, name, status;
  final int activeSizeBytes;
  final String? createdAt;
  final List<StudySource> sources;
}

/// One source backing a question, either the uploaded study material or (when
/// the study enabled web search) a real page the model was shown while
/// generating. [isWeb] is true only when [source] looks like an http(s) URL.
class QuestionCitation {
  QuestionCitation.fromJson(Map<String, dynamic> json)
    : source = json['source'] as String? ?? 'Study material',
      selection = json['selection'] as String? ?? '';

  final String source;
  final String selection;

  bool get isWeb => source.startsWith('http://') || source.startsWith('https://');
}

class StudyQuestion {
  StudyQuestion.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      prompt = json['prompt'] as String,
      choices = (json['choices'] as List).cast<String>(),
      visual =
          (json['visual'] as Map?)?.cast<String, dynamic>() ??
          const {'kind': 'none'},
      citations = (json['citations'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(QuestionCitation.fromJson)
              .toList() ??
          const [];
  final String id, prompt;
  final List<String> choices;
  final Map<String, dynamic> visual;
  final List<QuestionCitation> citations;
}

/// Live status of an in-flight question-generation call, polled by the
/// wizard's loading screen so it can show real "N questions generated so
/// far" progress instead of a canned rotating message.
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

  /// The question count the user asked for, or null when unlimited.
  final int? questionsTarget;
}
