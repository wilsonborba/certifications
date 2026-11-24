import 'dart:convert';

import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/models/authoring.dart';
import 'package:certifications/domain/services/question_authoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final question = <String, dynamic>{
    'id': 'question-1',
    'version_id': 'version-2',
    'version_num': 2,
    'language': 'en',
    'origin': 'supplied_by_creator',
    'prompt': 'Choose a correct statement',
    'alternatives': [
      {'id': 'a', 'text': 'First'},
      {'id': 'b', 'text': 'Second'},
    ],
    'correct_id': 'a',
    'explanation': 'The first statement is correct.',
    'citation_ref': 'p. 2',
    'visuals': [],
  };

  test('manual create and update use the Rust authoring DTOs', () async {
    final calls = <({String method, String path, Object? body})>[];
    final service = QuestionAuthoringService(
      client: CertificationsApiClient(
        baseUrl: 'https://example.invalid/apps/certifications/v1',
        request:
            ({
              required method,
              required url,
              headers,
              body,
              queryParams,
            }) async {
              calls.add((method: method, path: url.path, body: body));
              return http.Response(jsonEncode(question), 200);
            },
      ),
    );

    final alternatives = const [
      AuthoringAlternative(id: 'a', text: 'First'),
      AuthoringAlternative(id: 'b', text: 'Second'),
    ];
    await service.create(
      studyId: 'study-1',
      language: 'en',
      prompt: 'Choose a correct statement',
      alternatives: alternatives,
      correctId: 'a',
      explanation: 'The first statement is correct.',
      citationRef: 'p. 2',
    );
    await service.update(
      studyId: 'study-1',
      question: AuthoringQuestion.fromJson(question),
      language: 'en',
      prompt: 'Choose a correct statement',
      alternatives: alternatives,
      correctId: 'a',
      explanation: 'Updated explanation.',
      citationRef: 'p. 3',
    );

    expect(calls.map((call) => call.method), ['POST', 'PATCH']);
    expect(calls.map((call) => call.path), [
      '/apps/certifications/v1/studies/study-1/questions',
      '/apps/certifications/v1/studies/study-1/questions/question-1',
    ]);
    expect(calls.first.body, {
      'language': 'en',
      'prompt': 'Choose a correct statement',
      'alternatives': [
        {'id': 'a', 'text': 'First'},
        {'id': 'b', 'text': 'Second'},
      ],
      'correct_id': 'a',
      'explanation': 'The first statement is correct.',
      'citation_ref': 'p. 2',
    });
    expect((calls.first.body as Map).containsKey('origin'), isFalse);
    expect(calls.last.body, {
      'language': 'en',
      'prompt': 'Choose a correct statement',
      'alternatives': [
        {'id': 'a', 'text': 'First'},
        {'id': 'b', 'text': 'Second'},
      ],
      'correct_id': 'a',
      'explanation': 'Updated explanation.',
      'citation_ref': 'p. 3',
    });
  });

  test(
    'CSV preview and confirmation send the same contract with explicit flag',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final service = QuestionAuthoringService(
        client: CertificationsApiClient(
          baseUrl: 'https://example.invalid/apps/certifications/v1',
          request:
              ({
                required method,
                required url,
                headers,
                body,
                queryParams,
              }) async {
                bodies.add(Map<String, dynamic>.from(body as Map));
                final isPreview = bodies.length == 1;
                return http.Response(
                  jsonEncode({
                    'preview_only': isPreview,
                    'imported_count': isPreview ? 0 : 1,
                    'valid_rows': [
                      {
                        'row_number': 2,
                        'language': 'en',
                        'prompt': 'Question?',
                        'correct_id': 'a',
                      },
                    ],
                    'invalid_rows': [],
                    'questions': isPreview ? [] : [question],
                  }),
                  200,
                );
              },
        ),
      );

      const csv =
          'language,prompt,option_a,option_b,option_c,option_d,correct_option,explanation,citation_ref\nen,Question?,One,Two,,,a,Explanation,p.1';
      final preview = await service.previewCsv(
        studyId: 'study-1',
        csvText: csv,
      );
      expect(preview.previewOnly, isTrue);
      expect(preview.validRows.single.rowNumber, 2);
      expect(preview.invalidRows, isEmpty);
      final confirmed = await service.confirmCsv(
        studyId: 'study-1',
        csvText: csv,
      );
      expect(confirmed.previewOnly, isFalse);
      expect(confirmed.importedCount, 1);
      expect(bodies, [
        {'csv_text': csv, 'confirm': false},
        {'csv_text': csv, 'confirm': true},
      ]);
    },
  );

  test(
    'publication sends only Rust fields and parses actual published detail',
    () async {
      Map<String, dynamic>? sentBody;
      final service = QuestionAuthoringService(
        client: CertificationsApiClient(
          baseUrl: 'https://example.invalid/apps/certifications/v1',
          request:
              ({
                required method,
                required url,
                headers,
                body,
                queryParams,
              }) async {
                sentBody = Map<String, dynamic>.from(body as Map);
                return http.Response(
                  jsonEncode({
                    'id': 'quiz-1',
                    'title': 'Review quiz',
                    'question_count': 1,
                    'description': '',
                    'author_name': 'Author',
                    'origin': 'supplied_by_creator',
                    'tags': [],
                    'study_material': [],
                    'questions': [],
                    'performance': {
                      'quiz_id': 'quiz-1',
                      'completed_attempt_count': 0,
                      'distinct_participants': 0,
                      'average_score_pct': null,
                      'typical_duration_sec': null,
                      'basis': 'all_completed_attempts',
                    },
                  }),
                  200,
                );
              },
        ),
      );

      final quiz = await service.publish(
        studyId: 'study-1',
        title: 'Review quiz',
        tags: const ['Cardiology', 'ECG'],
      );
      expect(sentBody, {
        'title': 'Review quiz',
        'tags': ['Cardiology', 'ECG'],
      });
      expect(quiz.id, 'quiz-1');
      expect(quiz.questionCount, 1);
    },
  );

  test(
    'server rejection stays an error and is not converted to success',
    () async {
      final service = QuestionAuthoringService(
        client: CertificationsApiClient(
          baseUrl: 'https://example.invalid/apps/certifications/v1',
          request:
              ({
                required method,
                required url,
                headers,
                body,
                queryParams,
              }) async => http.Response(
                jsonEncode({
                  'error': {'code': 'no_questions'},
                }),
                422,
              ),
        ),
      );
      await expectLater(
        service.publish(studyId: 'study-1', title: 'Quiz', tags: const []),
        throwsA(
          isA<QuestionAuthoringException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'no_questions'),
        ),
      );
    },
  );
}
