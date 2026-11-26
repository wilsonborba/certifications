import 'package:certifications/domain/models/public_question_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = {
    'question_version_id': 'qv-1',
    'origin_quiz_id': 'quiz-1',
    'origin_quiz_version_id': 'quiz-v-1',
    'quiz_title': 'Public quiz',
    'tags': ['math'],
    'language': 'en',
    'origin': 'fixture-origin',
    'prompt': 'What is 2 + 2?',
    'alternatives': ['3', '4'],
  };

  test('catalog page accepts public fields and exact pagination values', () {
    final page = PublicQuestionCatalogPage.fromJson({
      'items': [item],
      'limit': 10,
      'offset': 20,
      'has_more': true,
    });

    expect(page.items.single.questionVersionId, 'qv-1');
    expect(page.items.single.originQuizVersionId, 'quiz-v-1');
    expect(page.items.single.alternatives, ['3', '4']);
    expect(page.limit, 10);
    expect(page.offset, 20);
    expect(page.hasMore, isTrue);
  });

  test('public projection rejects answer and private source fields', () {
    for (final privateField in [
      'answer',
      'correct_choice_index',
      'explanation',
      'citations',
      'source_ids',
    ]) {
      expect(
        () => PublicQuestionCatalogItem.fromJson({
          ...item,
          privateField: 'must not cross the public boundary',
        }),
        throwsFormatException,
      );
    }
  });

  test('catalog page rejects unknown, invalid, or unbounded pagination', () {
    for (final limit in [0, 51, '10']) {
      expect(
        () => PublicQuestionCatalogPage.fromJson({
          'items': [item],
          'limit': limit,
          'offset': 0,
          'has_more': false,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => PublicQuestionCatalogPage.fromJson({
        'items': [item],
        'limit': 10,
        'offset': -1,
        'has_more': false,
      }),
      throwsFormatException,
    );
  });

  test('reuse result parses exact server-owned counts', () {
    final result = PublicQuestionReuseResult.fromJson({
      'quiz_id': 'quiz-2',
      'quiz_version_id': 'quiz-v-2',
      'added_count': 1,
      'already_present_count': 2,
      'total_question_count': 5,
    });

    expect(result.quizVersionId, 'quiz-v-2');
    expect(result.addedCount, 1);
    expect(result.alreadyPresentCount, 2);
    expect(result.totalQuestionCount, 5);
  });
}
