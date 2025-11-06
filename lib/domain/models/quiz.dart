// models/quiz_models.dart


class QuestionItem {
  final String id;
  final String question;
  final List<String> options;
  final int? difficulty; // 1..3 (nullable if absent)
  final dynamic pdfQuestionId;

  QuestionItem( {
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
  final List<int?> selectedOptionIndexes; // one per question (null = unanswered)
  final Duration timeSpent;
  QuizResult({required this.selectedOptionIndexes, required this.timeSpent});
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