// models/quiz_models.dart

class QuestionItem {
  final String id;
  final String question;
  final List<String> options;
  final int? difficulty; // 1..3 (nullable if absent)
  final dynamic pdfQuestionId;

  QuestionItem({
    required this.id,
    required this.question,
    required this.options,
    this.pdfQuestionId,
    this.difficulty,
  });

  @override
  String toString() {
    return 'QuestionItem(id: $id, question: $question, options: $options, difficulty: $difficulty)';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    'difficulty': difficulty,
    'pdf_question_id': pdfQuestionId,
  };
}

class QuizResult {
  final List<int?>
  selectedOptionIndexes; // one per question (null = unanswered)
  final Duration timeSpent;
  QuizResult({required this.selectedOptionIndexes, required this.timeSpent});
}

/// Visibility of a completed quiz: only the owner can see a `private` one,
/// while a `public` one is listed in the community catalog and can gather
/// third-party attempts and a leaderboard.
enum QuizVisibility {
  private,
  public;

  static QuizVisibility parse(String? value) =>
      value == 'public' ? QuizVisibility.public : QuizVisibility.private;

  String get apiValue => name;
}

/// A completed quiz, matching the backend's `completed_quizzes` shape.
class Quiz {
  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.visibility,
    required this.status,
    required this.totalQuestions,
    required this.totalAttempts,
    required this.thirdPartyAttempts,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    id: json['id'] as String,
    title: (json['title'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    visibility: QuizVisibility.parse(json['visibility'] as String?),
    status: (json['status'] as String?) ?? 'completed',
    totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
    totalAttempts: (json['total_attempts'] as num?)?.toInt() ?? 0,
    thirdPartyAttempts: (json['third_party_attempts'] as num?)?.toInt() ?? 0,
    createdAt: (json['created_at'] as String?) ?? '',
  );

  final String id;
  final String title;
  final String description;
  final QuizVisibility visibility;
  final String status;
  final int totalQuestions;
  final int totalAttempts;
  final int thirdPartyAttempts;
  final String createdAt;

  /// A public quiz that already has third-party attempts must be kept for
  /// leaderboard history: the backend refuses deletion with a 403.
  bool get isDeleteProtected =>
      visibility == QuizVisibility.public && thirdPartyAttempts > 0;

  Quiz copyWith({QuizVisibility? visibility}) => Quiz(
    id: id,
    title: title,
    description: description,
    visibility: visibility ?? this.visibility,
    status: status,
    totalQuestions: totalQuestions,
    totalAttempts: totalAttempts,
    thirdPartyAttempts: thirdPartyAttempts,
    createdAt: createdAt,
  );
}

/// A single row of a quiz's leaderboard.
class LeaderboardEntry {
  LeaderboardEntry({
    required this.rank,
    required this.userName,
    required this.score,
    required this.timeSpentSeconds,
    required this.completedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) =>
      LeaderboardEntry(
        rank: rank,
        userName:
            (json['user_name'] as String?) ??
            (json['username'] as String?) ??
            (json['display_name'] as String?) ??
            '-',
        score: (json['score'] as num?)?.toDouble() ?? 0,
        timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt() ?? 0,
        completedAt: (json['completed_at'] as String?) ?? '',
      );

  final int rank;
  final String userName;
  final double score;
  final int timeSpentSeconds;
  final String completedAt;
}

/// Response of creating (or regenerating) a share link for a completed quiz.
class QuizShare {
  QuizShare({
    required this.token,
    required this.url,
    this.expiresAt,
    this.maxUses,
  });

  factory QuizShare.fromJson(Map<String, dynamic> json, {required String fallbackBaseUrl}) {
    final token = json['token'] as String? ?? '';
    final url = (json['url'] as String?) ?? '$fallbackBaseUrl/quizzes/shared/$token';
    return QuizShare(
      token: token,
      url: url,
      expiresAt: json['expires_at'] as String?,
      maxUses: (json['max_uses'] as num?)?.toInt(),
    );
  }

  final String token;
  final String url;
  final String? expiresAt;
  final int? maxUses;
}

/// One graded question, as returned by the grading endpoints
/// (`POST /studies/{id}/questions/submit` and
/// `POST /quizzes/shared/{token}/grade`). The correct answer only ever
/// reaches the client through this response, after it has already committed
/// to a choice.
class QuestionGradeDetail {
  QuestionGradeDetail.fromJson(Map<String, dynamic> json)
    : questionId = json['question_id'] as String,
      chosenIndex = (json['chosen_index'] as num).toInt(),
      correctIndex = (json['correct_index'] as num?)?.toInt(),
      isCorrect = json['is_correct'] as bool? ?? false,
      explanation = json['explanation'] as String?;

  final String questionId;
  final int chosenIndex;
  final int? correctIndex;
  final bool isCorrect;
  final String? explanation;
}

/// Result of grading a full set of answers: overall score plus a per-question
/// breakdown, shared by both grading endpoints.
class QuizGradeResult {
  QuizGradeResult.fromJson(Map<String, dynamic> json)
    : score = (json['score'] as num).toDouble(),
      correctCount = (json['correct_count'] as num).toInt(),
      wrongCount = (json['wrong_count'] as num).toInt(),
      totalQuestions = (json['total_questions'] as num).toInt(),
      results = ((json['results'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
          .map(QuestionGradeDetail.fromJson)
          .toList();

  final double score;
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final List<QuestionGradeDetail> results;

  QuestionGradeDetail? detailFor(String questionId) {
    for (final result in results) {
      if (result.questionId == questionId) return result;
    }
    return null;
  }
}

class AnswerSelection {
  final String questionId;
  final int? selectedIndex;
  final String? selectedText;

  const AnswerSelection({
    required this.questionId,
    required this.selectedIndex,
    required this.selectedText,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'selectedIndex': selectedIndex,
    'selectedText': selectedText,
  };
}
