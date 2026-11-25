import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/presentation/components/certificates/certificate_issue_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('previews and explicitly confirms the exact holder name', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'holder_id': null,
            'display_name': null,
            'confirmed': false,
          }),
          200,
        );
      }
      if (request.method == 'PUT') {
        return http.Response(
          jsonEncode({
            'holder_id': 'holder-1',
            'display_name': 'Ana Silva',
            'confirmed': true,
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'id': 'certificate-id',
          'verification_code': 'ASODYA-CODE123456',
          'holder_public_id': 'public-holder-1',
          'holder_name': 'Ana Silva',
          'quiz_id': 'quiz-1',
          'quiz_title': 'Sample quiz',
          'attempt_id': 'attempt-1',
          'score_correct': 0,
          'score_total': 1,
          'status': 'active',
          'revocation_reason': '',
          'issued_at': 1760000000,
          'revoked_at': null,
          'pdf_url': '/certificates/ASODYA-CODE123456/files/pdf',
          'image_url': '/certificates/ASODYA-CODE123456/files/image',
        }),
        200,
      );
    });
    final service = CertificateVerificationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: ListView(
            children: [
              CertificateIssueCard(attemptId: 'attempt-1', service: service),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' Ana   Silva ');
    await tester.pump();
    expect(find.text('Ana Silva'), findsOneWidget);
    await tester.tap(find.text('Preview and confirm name'));
    await tester.pumpAndSettle();
    expect(find.text('Name preview'), findsNWidgets(2));
    expect(find.text('Ana Silva'), findsNWidgets(2));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Preview and confirm name'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ASODYA-CODE123456'), findsOneWidget);
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /apps/certifications/v1/me/identity',
      'PUT /apps/certifications/v1/me/identity',
      'POST /apps/certifications/v1/attempts/attempt-1/certificate',
    ]);
    expect(jsonDecode(requests[1].body), {'display_name': 'Ana Silva'});
  });

  testWidgets('server eligibility errors stop certificate issuance', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'holder_id': 'holder-1',
            'display_name': 'Ana Silva',
            'confirmed': true,
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'error': 'private_quiz',
          'message': 'Private quizzes do not issue certificates',
        }),
        422,
      );
    });
    final service = CertificateVerificationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    await tester.pumpWidget(_issueCardApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Issue completion certificate'));
    await tester.pumpAndSettle();

    expect(
      find.text('This attempt does not meet the certificate requirements.'),
      findsOneWidget,
    );
    expect(find.text('Issue completion certificate'), findsNothing);
  });

  testWidgets('temporary issuance failure offers a retry', (tester) async {
    var issueCalls = 0;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'holder_id': null,
            'display_name': null,
            'confirmed': false,
          }),
          200,
        );
      }
      if (request.method == 'PUT') {
        return http.Response(
          jsonEncode({
            'holder_id': 'holder-1',
            'display_name': 'Ana Silva',
            'confirmed': true,
          }),
          200,
        );
      }
      issueCalls++;
      if (issueCalls == 1) {
        return http.Response(
          jsonEncode({
            'error': 'service_unavailable',
            'message': 'Required service is unavailable',
          }),
          503,
        );
      }
      return http.Response(jsonEncode(_issuedCertificateDto()), 200);
    });
    final service = CertificateVerificationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    await tester.pumpWidget(_issueCardApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ana Silva');
    await tester.tap(find.text('Preview and confirm name'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Preview and confirm name'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('The certificate service is unavailable. Try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry certificate issue'));
    await tester.pumpAndSettle();

    expect(issueCalls, 2);
    expect(find.textContaining('ASODYA-CODE123456'), findsOneWidget);
  });
}

Widget _issueCardApp(CertificateVerificationApiService service) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  home: Scaffold(
    body: ListView(
      children: [
        CertificateIssueCard(attemptId: 'attempt-1', service: service),
      ],
    ),
  ),
);

Map<String, dynamic> _issuedCertificateDto() => {
  'id': 'certificate-id',
  'verification_code': 'ASODYA-CODE123456',
  'holder_public_id': 'holder-1',
  'holder_name': 'Ana Silva',
  'quiz_id': 'quiz-1',
  'quiz_title': 'Sample quiz',
  'attempt_id': 'attempt-1',
  'score_correct': 0,
  'score_total': 1,
  'status': 'active',
  'revocation_reason': '',
  'issued_at': 1760000000,
  'revoked_at': null,
  'pdf_url': '/certificates/ASODYA-CODE123456/files/pdf',
  'image_url': '/certificates/ASODYA-CODE123456/files/image',
};
