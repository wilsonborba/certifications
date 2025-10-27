// models/quiz_models.dart


class QuestionItem {
  final String question;
  final List<String> options;
  final int? difficulty; // 1..3 (nullable if absent)

  QuestionItem({
    required this.question,
    required this.options,
    this.difficulty,
  });
}

class QuizResult {
  final List<int?> selectedOptionIndexes; // one per question (null = unanswered)
  final Duration timeSpent;
  QuizResult({required this.selectedOptionIndexes, required this.timeSpent});
}
