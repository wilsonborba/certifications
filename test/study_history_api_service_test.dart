import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/study_history.dart';
import 'package:certifications/domain/services/study_history_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'history request carries all exact owner filters and page offset',
    () async {
      late Uri requested;
      final service = StudyHistoryApiService(
        adapter: ApiAdapter(
          client: MockClient((request) async {
            requested = request.url;
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'id': 'study-51',
                    'title': 'Cell biology',
                    'description': '',
                    'source_origin': 'upload',
                    'status': 'active',
                    'quiz_id': 'quiz-51',
                    'expires_at': null,
                    'created_at': 1700000000,
                    'updated_at': 1700000001,
                  },
                ],
                'total': 55,
                'limit': 20,
                'offset': 40,
                'available_tags': [
                  {'slug': 'biology', 'label': 'Biology'},
                ],
              }),
              200,
            );
          }),
        ),
      );

      final page = await service.list(
        const StudyHistoryQuery(
          q: ' biology ',
          createdFrom: 1700000000,
          createdTo: 1700086399,
          status: 'active',
          quizId: 'quiz-51',
          tag: 'biology',
          limit: 20,
          offset: 40,
        ),
      );

      expect(requested.path, '/apps/certifications/v1/studies');
      expect(requested.queryParameters, {
        'q': 'biology',
        'created_from': '1700000000',
        'created_to': '1700086399',
        'status': 'active',
        'quiz_id': 'quiz-51',
        'tag': 'biology',
        'limit': '20',
        'offset': '40',
      });
      expect(page.total, 55);
      expect(page.offset, 40);
      expect(page.items.single.quizId, 'quiz-51');
      expect(page.availableTags.single.slug, 'biology');
    },
  );

  test('history page rejects envelope fallback and malformed DTO fields', () {
    expect(
      () => StudyHistoryPage.fromJson({
        'data': {'items': [], 'total': 0, 'limit': 20, 'offset': 0},
      }),
      throwsFormatException,
    );
    expect(
      () => StudyHistoryPage.fromJson({
        'items': [],
        'total': 0,
        'limit': 20,
        'offset': 0,
        'available_tags': [
          {'slug': 'biology'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('local calendar date bounds cover complete DST-aware days', () {
    final day = DateTime(2026, 11, 25);
    final start = StudyHistoryQuery.startOfLocalDateSeconds(day)!;
    final end = StudyHistoryQuery.endOfLocalDateSeconds(day)!;
    expect(start, DateTime(2026, 11, 25).millisecondsSinceEpoch ~/ 1000);
    expect(end + 1, DateTime(2026, 11, 26).millisecondsSinceEpoch ~/ 1000);
  });
}
