import 'dart:convert';
import 'package:certifications/core/routes.dart';
import 'package:certifications/core/tracking_manifest.dart';
import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/services/client_telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Area 10 routes parse cleanly and never mutate on GET/open', () {
    final cases = <(String, CertificationsScreen, String?, bool)>[
      ('/', CertificationsScreen.landing, null, false),
      ('/v1/catalog?q=rust', CertificationsScreen.catalog, null, false),
      ('/v1/quizzes/q123', CertificationsScreen.quizDetail, 'q123', false),
      ('/v1/dashboard', CertificationsScreen.dashboard, null, true),
      ('/v1/studies', CertificationsScreen.studies, null, true),
      ('/v1/studies/new', CertificationsScreen.studyNew, null, true),
      ('/v1/studies/s42', CertificationsScreen.studyDetail, 's42', true),
      ('/v1/generations/g9', CertificationsScreen.generation, 'g9', true),
      ('/v1/studies/s42/questions', CertificationsScreen.studyQuestions, 's42', true),
      ('/v1/attempts/a7', CertificationsScreen.attempt, 'a7', true),
      ('/v1/attempts/a7/results', CertificationsScreen.attemptResults, 'a7', true),
      ('/v1/history', CertificationsScreen.history, null, true),
      ('/v1/certificates/CERT-999', CertificationsScreen.certificate, 'CERT-999', false),
    ];

    for (final (raw, expectedScreen, expectedId, expectedAuth) in cases) {
      final parsed = CertificationsRoute.parse(Uri.parse(raw));
      expect(parsed.screen, expectedScreen, reason: raw);
      expect(parsed.id, expectedId, reason: raw);
      expect(parsed.requiresAuth, expectedAuth, reason: raw);
      expect(parsed.mutatesOnOpen, isFalse, reason: raw);
      expect(certificationsScreens.any((s) => s.route == parsed.routeTemplate), isTrue, reason: raw);
    }
  });

  test('Area 11 CertificationsApiClient targets /apps/certifications/v1 paths', () async {
    final seen = <(String, String)>[];
    final mock = MockClient((req) async {
      seen.add((req.method, req.url.path));
      return http.Response(jsonEncode({'ok': true}), 200);
    });
    final client = CertificationsApiClient(
      client: mock,
      baseUrl: 'https://api.asodya.com/apps/certifications/v1',
    );

    await client.listStudies(page: 1, limit: 20);
    await client.getStudy('s1');
    await client.startGeneration('s1', {'difficulty': 'easy'});
    await client.getCatalog(q: 'flutter');
    await client.startAttempt('q1');
    await client.putAttemptAnswer('a1', 'qn1', {'choice': 'A'});
    await client.submitAttempt('a1');
    await client.getAttemptResults('a1');
    await client.issueCertificate('a1');
    await client.verifyCertificate('CODE-1');

    expect(seen, [
      ('GET', '/apps/certifications/v1/studies'),
      ('GET', '/apps/certifications/v1/studies/s1'),
      ('POST', '/apps/certifications/v1/studies/s1/generations'),
      ('GET', '/apps/certifications/v1/catalog'),
      ('POST', '/apps/certifications/v1/quizzes/q1/attempts'),
      ('PUT', '/apps/certifications/v1/attempts/a1/answers/qn1'),
      ('POST', '/apps/certifications/v1/attempts/a1/submit'),
      ('GET', '/apps/certifications/v1/attempts/a1/results'),
      ('POST', '/apps/certifications/v1/attempts/a1/certificate'),
      ('GET', '/apps/certifications/v1/certificates/CODE-1'),
    ]);
  });

  test('Area 12/13 sensitive field manifest and screen_trail error endpoint', () async {
    expect(isSensitiveTelemetryField('source_text'), isTrue);
    expect(isSensitiveTelemetryField('question_fields'), isTrue);
    expect(isSensitiveTelemetryField('quiz_responses'), isTrue);
    expect(isSensitiveTelemetryField('support_body'), isTrue);
    expect(isSensitiveTelemetryField('filename'), isTrue);
    expect(isSensitiveTelemetryField('private_link'), isTrue);
    expect(isSensitiveTelemetryField('catalog_search_btn'), isFalse);

    final postedUris = <Uri>[];
    final mock = MockClient((req) async {
      postedUris.add(req.url);
      return http.Response('', 202);
    });
    final telemetry = ClientTelemetryService.instance;
    telemetry.attachClientForTest(mock, baseUrl: 'https://api.asodya.com');
    telemetry.reportHandledError(
      title: 'Test Error',
      error: Exception('boom'),
      route: '/v1/studies',
      errorCode: 'TEST_ERR',
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(postedUris.any((u) => u.path == '/apps/api/v1/telemetry/errors'), isTrue);
  });
}
