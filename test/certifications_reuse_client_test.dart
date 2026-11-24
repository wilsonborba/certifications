import 'dart:convert';

import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('public question search uses the explicit #49 query contract', () async {
    late http.Request seen;
    final client = CertificationsApiClient(
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({
            'items': [
              {
                'question_version_id': 'version-1',
                'question_id': 'question-1',
                'quiz_title': 'Public quiz',
                'tags': ['language'],
                'language': 'en',
                'origin': 'creator',
                'prompt': 'Which language is this?',
                'alternatives': ['Dart', 'Rust'],
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
    );

    final response = await client.searchPublicQuestions(
      q: 'language',
      language: 'en',
      origin: 'creator',
      limit: 10,
      offset: 20,
    );

    expect(response.statusCode, 200);
    expect(seen.method, 'GET');
    expect(seen.url.path, '/apps/certifications/v1/catalog/questions');
    expect(seen.url.queryParameters, {
      'q': 'language',
      'language': 'en',
      'origin': 'creator',
      'limit': '10',
      'offset': '20',
    });
  });

  test('reuse sends only explicit immutable version IDs', () async {
    late http.Request seen;
    final client = CertificationsApiClient(
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({
            'quiz_id': 'quiz-1',
            'quiz_version_id': 'quiz-version-2',
            'added_count': 1,
            'already_present_count': 1,
            'total_question_count': 4,
          }),
          200,
        );
      }),
      baseUrl: 'https://api.example/apps/certifications/v1',
    );

    final response = await client.reuseStudyQuestions('study-1', [
      'version-1',
      'version-2',
    ]);

    expect(response.statusCode, 200);
    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/apps/certifications/v1/studies/study-1/questions/reuse',
    );
    expect(jsonDecode(seen.body), {
      'question_version_ids': ['version-1', 'version-2'],
    });
  });

  test('public search and reuse enforce the documented page bounds', () async {
    final client = CertificationsApiClient(
      request:
          ({required method, required url, headers, body, queryParams}) async =>
              http.Response('{}', 200),
      baseUrl: 'https://api.example/apps/certifications/v1',
    );

    expect(
      () => client.searchPublicQuestions(limit: 51, offset: 0),
      throwsArgumentError,
    );
    expect(
      () => client.searchPublicQuestions(limit: 10, offset: -1),
      throwsArgumentError,
    );
    expect(
      () => client.reuseStudyQuestions('study-1', const []),
      throwsArgumentError,
    );
    expect(
      () => client.reuseStudyQuestions(
        'study-1',
        List.generate(51, (index) => 'version-$index'),
      ),
      throwsArgumentError,
    );
  });
}
