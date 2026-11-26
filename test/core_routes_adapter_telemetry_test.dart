import 'dart:convert';
import 'package:certifications/core/routes.dart';
import 'package:certifications/core/tracking_manifest.dart';
import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/services/client_telemetry_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'Area 10 routes resolve to :id manifest screens and sensitive paths',
    () {
      final cases = <(String, CertificationsScreen, String?, bool, String)>[
        ('/', CertificationsScreen.landing, null, false, 'landing'),
        (
          '/v1/catalog?q=rust',
          CertificationsScreen.catalog,
          null,
          false,
          'catalog',
        ),
        (
          '/v1/quizzes/q123',
          CertificationsScreen.quizDetail,
          'q123',
          false,
          'quiz_detail',
        ),
        (
          '/v1/quizzes/q123/statistics',
          CertificationsScreen.publicQuizStatistics,
          'q123',
          false,
          'public_quiz_statistics',
        ),
        (
          '/v1/me/quizzes/private-q/statistics',
          CertificationsScreen.ownedQuizStatistics,
          'private-q',
          true,
          'owned_quiz_statistics',
        ),
        (
          '/v1/dashboard',
          CertificationsScreen.dashboard,
          null,
          true,
          'dashboard',
        ),
        ('/v1/studies', CertificationsScreen.studies, null, true, 'studies'),
        (
          '/v1/studies/new',
          CertificationsScreen.studyNew,
          null,
          true,
          'study_new',
        ),
        (
          '/v1/studies/s42',
          CertificationsScreen.studyDetail,
          's42',
          true,
          'study_detail',
        ),
        (
          '/v1/generations/g9',
          CertificationsScreen.generation,
          'g9',
          true,
          'generation',
        ),
        (
          '/v1/studies/s42/questions',
          CertificationsScreen.studyQuestions,
          's42',
          true,
          'study_questions',
        ),
        (
          '/v1/attempts/a7',
          CertificationsScreen.attempt,
          'a7',
          true,
          'attempt',
        ),
        (
          '/v1/attempts/a7/results',
          CertificationsScreen.attemptResults,
          'a7',
          true,
          'attempt_results',
        ),
        ('/v1/history', CertificationsScreen.history, null, true, 'history'),
        (
          '/v1/certificates/CERT-999',
          CertificationsScreen.certificate,
          'CERT-999',
          false,
          'certificate',
        ),
        (
          '/quizzes/shared/SECRETSHARETOKEN123',
          CertificationsScreen.sharedQuiz,
          'SECRETSHARETOKEN123',
          false,
          'shared_quiz',
        ),
      ];

      for (final (raw, expectedScreen, expectedId, expectedAuth, expectedName)
          in cases) {
        final parsed = CertificationsRoute.parse(Uri.parse(raw));
        expect(parsed.screen, expectedScreen, reason: raw);
        expect(parsed.id, expectedId, reason: raw);
        expect(parsed.requiresAuth, expectedAuth, reason: raw);
        final screen = certificationsScreens.firstWhere(
          (s) => s.route == parsed.routeTemplate,
        );
        expect(screen.name, expectedName, reason: raw);
        expect(screen.matches(Uri.parse(raw).path), isTrue, reason: raw);
      }
    },
  );

  test('public certificate QR URL aliases the existing verification route', () {
    for (final path in [
      '/certificates/ASODYA-FIXTURE-CODE',
      '/v1/certificates/ASODYA-FIXTURE-CODE',
    ]) {
      final route = CertificationsRoute.parse(Uri.parse(path));
      expect(route.screen, CertificationsScreen.certificate, reason: path);
      expect(route.id, 'ASODYA-FIXTURE-CODE', reason: path);
      expect(route.requiresAuth, isFalse, reason: path);
      expect(
        route.routeTemplate,
        '/v1/certificates/:certificate_code',
        reason: path,
      );
    }

    for (final path in [
      '/certificates',
      '/certificates/ASODYA-FIXTURE-CODE/extra',
    ]) {
      final route = CertificationsRoute.parse(Uri.parse(path));
      expect(route.screen, CertificationsScreen.landing, reason: path);
    }
  });

  test('prepared Notes continuation accepts only a study identifier query', () {
    final route = CertificationsRoute.parse(
      Uri.parse('/v1/studies/new?prepared_study_id=study_42'),
    );
    expect(route.screen, CertificationsScreen.studyNew);
    expect(route.requiresAuth, isTrue);
    expect(route.queryParameters['prepared_study_id'], 'study_42');

    final unsafe = CertificationsRoute.parse(
      Uri.parse('/v1/studies/new?prepared_study_id=study%2F42'),
    );
    expect(unsafe.preparedStudyId, isNull);
  });

  test('completed history keeps the authenticated named route and filter', () {
    final route = CertificationsRoute.parse(
      Uri.parse('/v1/history?status=completed'),
    );
    expect(route.screen, CertificationsScreen.history);
    expect(route.requiresAuth, isTrue);
    expect(route.routeTemplate, '/v1/history');
    expect(route.queryParameters['status'], 'completed');
  });

  testWidgets(
    'ScreenTrailObserver records template view and opening Area 10 routes performs no mutation',
    (tester) async {
      final requests = <(String, String)>[];
      final mock = MockClient((req) async {
        requests.add((req.method, req.url.path));
        return http.Response(jsonEncode({'events': []}), 202);
      });
      final telemetry = ClientTelemetryService.instance;
      telemetry.attachClientForTest(mock, baseUrl: 'https://api.asodya.com');

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [ScreenTrailObserver(telemetry.tracker)],
          onGenerateRoute: (settings) {
            final parsed = CertificationsRoute.parse(
              Uri.tryParse(settings.name ?? '/') ?? Uri(path: '/'),
            );
            return MaterialPageRoute(
              settings: RouteSettings(name: parsed.routeTemplate),
              builder: (_) => const SizedBox.shrink(),
            );
          },
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pump();

      // Push concrete Area 10 routes via Navigator and verify ScreenTrailObserver records views
      // without performing any mutating HTTP call.
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      for (final path in [
        '/v1/catalog',
        '/v1/quizzes/q1',
        '/v1/dashboard',
        '/v1/studies',
        '/v1/studies/new',
        '/v1/studies/s1',
        '/v1/generations/g1',
        '/v1/studies/s1/questions',
        '/v1/attempts/a7',
        '/v1/attempts/a7/results',
        '/v1/history',
        '/v1/certificates/C1',
        '/certificates/C2',
        '/quizzes/shared/TOK_SECRET',
      ]) {
        nav.pushNamed(path);
        await tester.pump();
      }

      await telemetry.tracker.flush();
      final eventReqs = requests
          .where((r) => r.$2 == '/apps/api/v1/telemetry/events')
          .toList();
      expect(eventReqs, isNotEmpty);

      final certMutations = requests.where(
        (r) =>
            r.$2.startsWith('/apps/certifications/v1') &&
            const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(r.$1),
      );
      expect(certMutations, isEmpty);
    },
  );

  test(
    'Area 12/13 privacy: sensitive input values and share tokens are absent from telemetry payloads',
    () async {
      final bodies = <String>[];
      final mock = MockClient((req) async {
        bodies.add(req.body);
        return http.Response('', 202);
      });
      final telemetry = ClientTelemetryService.instance;
      telemetry.attachClientForTest(mock, baseUrl: 'https://api.asodya.com');
      final tracker = telemetry.tracker;

      // Sensitive dotted element IDs must strip typed values.
      const sensitiveIds = [
        'study_new.source_text.input',
        'question_review.question_prompt.field',
        'attempt.quiz_responses.answer',
        'support.support_body.text',
        'study_detail.filename.input',
        'quiz_share.private_link.input',
      ];
      for (final id in sensitiveIds) {
        recordCertificationsInput(
          tracker,
          TrailElement(
            id: id,
            path: '/v1/studies/new',
            label: 'Sensitive input',
          ),
          'MY_PRIVATE_SECRET_VALUE',
        );
      }

      // Non-sensitive field keeps typed value.
      recordCertificationsInput(
        tracker,
        const TrailElement(
          id: 'catalog.search_box.input',
          path: '/v1/catalog',
          label: 'Search catalog',
        ),
        'public rust quiz',
      );
      await tracker.flush();

      final eventsPayload = bodies.join('\n');
      expect(eventsPayload.contains('MY_PRIVATE_SECRET_VALUE'), isFalse);
      expect(eventsPayload.contains('public rust quiz'), isTrue);

      // Share token in error route must be replaced with :token template.
      bodies.clear();
      telemetry.reportHandledError(
        title: 'Shared quiz error',
        error: Exception('fail'),
        route: '/quizzes/shared/SECRETSHARETOKEN123',
        errorCode: 'ERR_SHARED',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final errorPayload = bodies.join('\n');
      expect(errorPayload.contains('SECRETSHARETOKEN123'), isFalse);
      expect(errorPayload.contains('/quizzes/shared/:token'), isTrue);
    },
  );

  test(
    'Area 11 & UI-needed CertificationsApiClient covers every method and path',
    () async {
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
      await client.createStudy({'title': 'S'});
      await client.createPreparedStudy({'title': 'P'});
      await client.getStudy('s1');
      await client.patchStudy('s1', {'title': 'S2'});
      await client.deleteStudy('s1');
      await client.getStudyEstimate('s1');
      await client.getStudyTagSuggestions('s1');
      await client.uploadStudySourceMultipart(
        's1',
        bytes: [1, 2],
        filename: 'notes.txt',
        mimeType: 'text/plain',
      );
      await client.getSource('s1', 'src1');
      await client.previewSource('s1', 'src1');
      await client.patchSourceSelection('s1', 'src1', {'selected': true});
      await client.deleteSource('s1', 'src1');
      await client.analyzeStudy('s1');
      await client.getStudyAnalysis('s1');
      await client.startGeneration('s1', {'difficulty': 'easy'});
      await client.getGeneration('g1');
      await client.stopGeneration('g1');
      await client.resumeGeneration('g1');
      await client.listStudyQuestions('s1');
      await client.createStudyQuestion('s1', {'prompt': 'Q'});
      await client.patchStudyQuestion('s1', 'qn1', {'prompt': 'Q2'});
      await client.deleteStudyQuestion('s1', 'qn1');
      await client.importStudyQuestions('s1', {'rows': []});
      await client.publishStudy('s1', {'title': 'Pub'});
      await client.generateQuestionVisual('s1', 'qn1', {'kind': 'chart'});
      await client.getReportsPicker();
      await client.getCatalog(q: 'flutter');
      await client.getCatalogQuestions(q: 'dart');
      await client.getQuiz('q1');
      await client.getQuizStatistics('q1');
      await client.deleteQuiz('q1');
      await client.startAttempt('q1');
      await client.listAttempts();
      await client.getAttempt('a1');
      await client.putAttemptAnswer('a1', 'qn1', {'choice': 'A'});
      await client.postAttemptEvent('a1', {'type': 'focus'});
      await client.submitAttempt('a1');
      await client.getAttemptResults('a1');
      await client.getMyIdentity();
      await client.confirmMyIdentity({'name': 'Ana'});
      await client.issueCertificate('a1');
      await client.verifyCertificate('CODE-1');
      await client.getAdminSettings();
      await client.patchAdminSettings({'max_upload_mb': 10});
      await client.listAdminSchemaVersions('study');
      await client.createAdminSchemaVersion('study', {'fields': []});
      await client.getAdminSchemaVersion('study', '1');
      await client.patchAdminSchemaVersion('study', '1', {'fields': []});
      await client.deleteAdminSchemaVersion('study', '1');
      await client.patchAdminSchemaVersionStatus('study', '1', {
        'status': 'published',
      });
      await client.patchAdminQuizOrigin('q1', {'origin': 'verified'});
      await client.patchAdminHolder('h1', {'name': 'Ana'});
      await client.revokeAdminCertificate('CODE-1', {'reason': 'fraud'});
      await client.getAdminCleanup();
      await client.retryAdminCleanup('c1');
      await client.getAdminStatistics();

      expect(seen, [
        ('GET', '/apps/certifications/v1/studies'),
        ('POST', '/apps/certifications/v1/studies'),
        ('POST', '/apps/certifications/v1/studies/prepared'),
        ('GET', '/apps/certifications/v1/studies/s1'),
        ('PATCH', '/apps/certifications/v1/studies/s1'),
        ('DELETE', '/apps/certifications/v1/studies/s1'),
        ('GET', '/apps/certifications/v1/studies/s1/estimate'),
        ('GET', '/apps/certifications/v1/studies/s1/tags/suggestions'),
        ('POST', '/apps/certifications/v1/studies/s1/sources'),
        ('GET', '/apps/certifications/v1/studies/s1/sources/src1'),
        ('GET', '/apps/certifications/v1/studies/s1/sources/src1/preview'),
        ('PATCH', '/apps/certifications/v1/studies/s1/sources/src1/selection'),
        ('DELETE', '/apps/certifications/v1/studies/s1/sources/src1'),
        ('POST', '/apps/certifications/v1/studies/s1/analysis'),
        ('GET', '/apps/certifications/v1/studies/s1/analysis'),
        ('POST', '/apps/certifications/v1/studies/s1/generations'),
        ('GET', '/apps/certifications/v1/generations/g1'),
        ('POST', '/apps/certifications/v1/generations/g1/stop'),
        ('POST', '/apps/certifications/v1/generations/g1/resume'),
        ('GET', '/apps/certifications/v1/studies/s1/questions'),
        ('POST', '/apps/certifications/v1/studies/s1/questions'),
        ('PATCH', '/apps/certifications/v1/studies/s1/questions/qn1'),
        ('DELETE', '/apps/certifications/v1/studies/s1/questions/qn1'),
        ('POST', '/apps/certifications/v1/studies/s1/questions/import'),
        ('POST', '/apps/certifications/v1/studies/s1/publication'),
        ('POST', '/apps/certifications/v1/studies/s1/questions/qn1/visual'),
        ('GET', '/apps/certifications/v1/reports/picker'),
        ('GET', '/apps/certifications/v1/catalog'),
        ('GET', '/apps/certifications/v1/catalog/questions'),
        ('GET', '/apps/certifications/v1/quizzes/q1'),
        ('GET', '/apps/certifications/v1/quizzes/q1/statistics'),
        ('DELETE', '/apps/certifications/v1/quizzes/q1'),
        ('POST', '/apps/certifications/v1/quizzes/q1/attempts'),
        ('GET', '/apps/certifications/v1/attempts'),
        ('GET', '/apps/certifications/v1/attempts/a1'),
        ('PUT', '/apps/certifications/v1/attempts/a1/answers/qn1'),
        ('POST', '/apps/certifications/v1/attempts/a1/events'),
        ('POST', '/apps/certifications/v1/attempts/a1/submit'),
        ('GET', '/apps/certifications/v1/attempts/a1/results'),
        ('GET', '/apps/certifications/v1/me/identity'),
        ('PUT', '/apps/certifications/v1/me/identity'),
        ('POST', '/apps/certifications/v1/attempts/a1/certificate'),
        ('GET', '/apps/certifications/v1/certificates/CODE-1'),
        ('GET', '/apps/certifications/v1/admin/settings'),
        ('PATCH', '/apps/certifications/v1/admin/settings'),
        ('GET', '/apps/certifications/v1/admin/schemas/study/versions'),
        ('POST', '/apps/certifications/v1/admin/schemas/study/versions'),
        ('GET', '/apps/certifications/v1/admin/schemas/study/versions/1'),
        ('PATCH', '/apps/certifications/v1/admin/schemas/study/versions/1'),
        ('DELETE', '/apps/certifications/v1/admin/schemas/study/versions/1'),
        (
          'PATCH',
          '/apps/certifications/v1/admin/schemas/study/versions/1/status',
        ),
        ('PATCH', '/apps/certifications/v1/admin/quizzes/q1/origin'),
        ('PATCH', '/apps/certifications/v1/admin/holders/h1'),
        (
          'POST',
          '/apps/certifications/v1/admin/certificates/CODE-1/revocation',
        ),
        ('GET', '/apps/certifications/v1/admin/cleanup'),
        ('POST', '/apps/certifications/v1/admin/cleanup/c1/retry'),
        ('GET', '/apps/certifications/v1/admin/statistics'),
      ]);
    },
  );
}
