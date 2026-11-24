/// Public projection returned by Certifications API #49. This DTO deliberately
/// has no answer, explanation, citation, or private source fields.
class PublicQuestionCatalogItem {
  const PublicQuestionCatalogItem({
    required this.questionVersionId,
    required this.originQuizId,
    required this.originQuizVersionId,
    required this.quizTitle,
    required this.tags,
    required this.language,
    required this.origin,
    required this.prompt,
    required this.alternatives,
  });

  factory PublicQuestionCatalogItem.fromJson(Map<String, dynamic> json) {
    const privateFields = {
      'answer',
      'answer_key',
      'correct_choice_index',
      'explanation',
      'citations',
      'source_ids',
      'source_content',
    };
    if (json.keys.any(privateFields.contains)) {
      throw const FormatException(
        'Public question response contains private fields',
      );
    }
    return PublicQuestionCatalogItem(
      questionVersionId: _requiredString(json, 'question_version_id'),
      originQuizId: _requiredString(json, 'origin_quiz_id'),
      originQuizVersionId: _requiredString(json, 'origin_quiz_version_id'),
      quizTitle: _requiredString(json, 'quiz_title'),
      tags: _requiredStringList(json, 'tags'),
      language: _requiredString(json, 'language'),
      origin: _requiredString(json, 'origin'),
      prompt: _requiredString(json, 'prompt'),
      alternatives: _requiredStringList(json, 'alternatives'),
    );
  }

  final String questionVersionId;
  final String originQuizId;
  final String originQuizVersionId;
  final String quizTitle;
  final List<String> tags;
  final String language;
  final String origin;
  final String prompt;
  final List<String> alternatives;

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Expected non-empty $key');
    }
    return value;
  }

  static List<String> _requiredStringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Expected string list $key');
    }
    return List.unmodifiable(value.cast<String>());
  }
}

class PublicQuestionCatalogPage {
  const PublicQuestionCatalogPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory PublicQuestionCatalogPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final limit = json['limit'];
    final offset = json['offset'];
    final hasMore = json['has_more'];
    if (rawItems is! List ||
        limit is! int ||
        limit < 1 ||
        limit > 50 ||
        offset is! int ||
        offset < 0 ||
        hasMore is! bool) {
      throw const FormatException('Invalid public question page response');
    }
    return PublicQuestionCatalogPage(
      items: List.unmodifiable(
        rawItems.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid public question item');
          }
          return PublicQuestionCatalogItem.fromJson(item);
        }),
      ),
      limit: limit,
      offset: offset,
      hasMore: hasMore,
    );
  }

  final List<PublicQuestionCatalogItem> items;
  final int limit;
  final int offset;
  final bool hasMore;
}

class PublicQuestionReuseResult {
  const PublicQuestionReuseResult({
    required this.quizId,
    required this.quizVersionId,
    required this.addedCount,
    required this.alreadyPresentCount,
    required this.totalQuestionCount,
  });

  factory PublicQuestionReuseResult.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw FormatException('Expected non-negative $key');
      }
      return value;
    }

    return PublicQuestionReuseResult(
      quizId: _requiredString(json, 'quiz_id'),
      quizVersionId: _requiredString(json, 'quiz_version_id'),
      addedCount: count('added_count'),
      alreadyPresentCount: count('already_present_count'),
      totalQuestionCount: count('total_question_count'),
    );
  }

  final String quizId;
  final String quizVersionId;
  final int addedCount;
  final int alreadyPresentCount;
  final int totalQuestionCount;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Expected non-empty $key');
  }
  return value;
}
