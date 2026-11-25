import 'dart:convert';

import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/services/public_question_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('search sends bounded filters and parses the public page', () async {
    late http.Request request;
    final service = PublicQuestionApiService(
      client: CertificationsApiClient(
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'question_version_id': 'qv-1',
                  'origin_quiz_id': 'quiz-1',
                  'origin_quiz_version_id': 'quiz-v1',
                  'quiz_title': 'Public quiz',
                  'tags': ['science'],
                  'language': 'en',
                  'origin': 'fixture-origin',
                  'prompt': 'Question',
                  'alternatives': ['A', 'B'],
                },
              ],
              'limit': 10,
              'offset': 20,
              'has_more': false,
            }),
            200,
          );
        }),
        baseUrl: 'https://api.example/apps/certifications/v1',
      ),
    );

    final page = await service.search(
      query: 'science',
      language: 'en',
      origin: 'fixture-origin',
      limit: 10,
      offset: 20,
    );

    expect(request.method, 'GET');
    expect(request.url.path, '/apps/certifications/v1/catalog/questions');
    expect(request.url.queryParameters, {
      'q': 'science',
      'language': 'en',
      'origin': 'fixture-origin',
      'limit': '10',
      'offset': '20',
    });
    expect(page.items.single.questionVersionId, 'qv-1');
    expect(page.hasMore, isFalse);
  });

  test(
    'reuse sends only selected version IDs and parses server totals',
    () async {
      late http.Request request;
      final service = PublicQuestionApiService(
        client: CertificationsApiClient(
          client: MockClient((value) async {
            request = value;
            return http.Response(
              jsonEncode({
                'quiz_id': 'quiz-2',
                'quiz_version_id': 'quiz-v2',
                'added_count': 1,
                'already_present_count': 1,
                'total_question_count': 4,
              }),
              200,
            );
          }),
          baseUrl: 'https://api.example/apps/certifications/v1',
        ),
      );

      final result = await service.reuseSelected(
        studyId: 'study-1',
        questionVersionIds: ['qv-1', 'qv-2'],
      );

      expect(request.method, 'POST');
      expect(
        request.url.path,
        '/apps/certifications/v1/studies/study-1/questions/reuse',
      );
      expect(jsonDecode(request.body), {
        'question_version_ids': ['qv-1', 'qv-2'],
      });
      expect(result.addedCount, 1);
      expect(result.alreadyPresentCount, 1);
      expect(result.totalQuestionCount, 4);
    },
  );

  test('reuse rejects duplicates and empty immutable IDs before request', () {
    final service = PublicQuestionApiService(
      client: CertificationsApiClient(
        request:
            ({
              required method,
              required url,
              headers,
              body,
              queryParams,
            }) async => http.Response('{}', 200),
        baseUrl: 'https://api.example/apps/certifications/v1',
      ),
    );

    expect(
      () => service.reuseSelected(studyId: 'study-1', questionVersionIds: []),
      throwsArgumentError,
    );
    expect(
      () => service.reuseSelected(
        studyId: 'study-1',
        questionVersionIds: ['qv-1', 'qv-1'],
      ),
      throwsArgumentError,
    );
    expect(
      () => service.reuseSelected(studyId: 'study-1', questionVersionIds: ['']),
      throwsArgumentError,
    );
  });
}
