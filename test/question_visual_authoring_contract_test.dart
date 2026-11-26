import 'dart:convert';

import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/models/authoring.dart';
import 'package:certifications/domain/services/question_authoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final questionJson = <String, dynamic>{
    'id': 'question-1',
    'version_id': 'question-version-7',
    'version_num': 7,
    'language': 'en',
    'origin': 'supplied_by_creator',
    'prompt': 'Which value is largest?',
    'alternatives': [
      {'id': 'a', 'text': '1'},
      {'id': 'b', 'text': '2'},
    ],
    'correct_id': 'b',
    'explanation': '',
    'citation_ref': '',
    'visuals': [],
  };

  test('prepares and uploads through the version-bound visual API', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/visual_jobs')) {
        return http.Response(
          jsonEncode({
            'question_id': 'question-1',
            'question_version_id': 'question-version-7',
            'render_job': {
              'job_id': 'render-123',
              'status': 'pending',
              'template_id': 'bar-v1',
              'template_version': 3,
              'mapping': {
                'x': ['month'],
                'y': ['count'],
              },
              'config': {'title': 'Monthly counts'},
              'rows': [
                {'month': 'Jan', 'count': 3},
              ],
              'width': 800,
              'height': 480,
              'scale': 2,
              'expires_at': 1760000900,
            },
          }),
          201,
        );
      }
      if (request.url.path.endsWith('/visuals')) {
        return http.Response(
          jsonEncode({
            'id': 'vis_render-123',
            'fsm_ref': 'private-ref',
            'mime_type': 'image/png',
            'created_at': 1760000000,
          }),
          201,
        );
      }
      return http.Response('unexpected request', 404);
    });
    addTearDown(client.close);
    final service = QuestionAuthoringService(
      client: CertificationsApiClient(
        client: client,
        baseUrl: 'https://api.example.invalid/apps/certifications/v1',
      ),
    );
    final question = AuthoringQuestion.fromJson(questionJson);
    final prepared = await service.prepareVisualJob(
      studyId: 'study-1',
      question: question,
      templateId: 'bar-v1',
      templateVersion: 3,
      mapping: const {
        'x': ['month'],
        'y': ['count'],
      },
      config: const {'title': 'Monthly counts'},
      rows: const [
        {'month': 'Jan', 'count': 3},
      ],
    );

    expect(prepared.questionVersionId, question.versionId);
    expect(prepared.jobId, 'render-123');
    expect(prepared.width * prepared.scale, 1600);
    expect(
      requests.first.url.path,
      endsWith('/studies/study-1/questions/question-1/visual_jobs'),
    );
    expect(jsonDecode(requests.first.body), {
      'template_id': 'bar-v1',
      'template_version': 3,
      'mapping': {
        'x': ['month'],
        'y': ['count'],
      },
      'config': {'title': 'Monthly counts'},
      'rows': [
        {'month': 'Jan', 'count': 3},
      ],
      'width': 800,
      'height': 480,
      'scale': 2,
      'ttl_seconds': 900,
    });

    final pngBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII=',
    );
    final visual = await service.uploadVisual(
      studyId: 'study-1',
      question: question,
      job: prepared,
      pngBytes: pngBytes,
    );
    expect(visual.id, 'vis_render-123');
    expect(visual.mimeType, 'image/png');
    expect(
      requests.last.url.path,
      endsWith('/studies/study-1/questions/question-1/visuals'),
    );
    expect(jsonDecode(requests.last.body), {
      'question_version_id': 'question-version-7',
      'render_job_id': 'render-123',
      'expected_width': 800,
      'expected_height': 480,
      'expected_scale': 2,
      'png_base64': base64Encode(pngBytes),
    });
  });

  test(
    'rejects a prepared job bound to another immutable question version',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'question_id': 'question-1',
            'question_version_id': 'old-version',
            'render_job': {
              'job_id': 'render-123',
              'template_id': 'bar-v1',
              'template_version': 3,
              'width': 800,
              'height': 480,
              'scale': 2,
              'expires_at': 1760000900,
            },
          }),
          201,
        ),
      );
      addTearDown(client.close);
      final service = QuestionAuthoringService(
        client: CertificationsApiClient(
          client: client,
          baseUrl: 'https://api.example.invalid/apps/certifications/v1',
        ),
      );
      expect(
        () => service.prepareVisualJob(
          studyId: 'study-1',
          question: AuthoringQuestion.fromJson(questionJson),
          templateId: 'bar-v1',
          templateVersion: 3,
          mapping: const {},
          config: const {},
          rows: const [],
        ),
        throwsFormatException,
      );
    },
  );
}
