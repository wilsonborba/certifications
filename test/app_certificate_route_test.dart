import 'dart:convert';

import 'package:certifications/app.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/domain/services/client_telemetry_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('the emitted QR URL opens the public verification screen', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'verification_code': 'ASODYA-FIXTURE-CODE',
          'status': 'active',
          'revocation_reason': '',
          'holder_public_id': 'PUBLIC-HOLDER-4',
          'holder_name': 'Ana Example',
          'quiz_title': 'Fixture completion quiz',
          'score_correct': 2,
          'score_total': 5,
          'issued_at': 1760000000,
          'revoked_at': null,
          'activity_summary': {
            'focus_lost_count': 0,
            'page_hidden_count': 0,
            'page_return_count': 0,
            'known_away_ms': 0,
            'reconnect_count': 0,
            'refresh_count': 0,
            'unknown_gap_count': 0,
            'completeness': 'complete',
            'disclaimer': 'Observed browser activity only.',
            'events': <Object>[],
          },
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });
    final telemetryClient = MockClient((_) async => http.Response('', 202));
    ClientTelemetryService.instance.attachClientForTest(
      telemetryClient,
      baseUrl: 'https://telemetry.fixture.invalid',
    );
    final telemetry = ClientTelemetryService.instance;
    final service = CertificateVerificationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Keep the process-wide tracker usable for the next test while closing
      // both clients owned by this fixture.
      telemetry.attachClientForTest(
        MockClient((_) async => http.Response('', 202)),
        baseUrl: 'https://telemetry.fixture.invalid',
      );
      client.close();
      telemetryClient.close();
    });

    await tester.pumpWidget(
      App(
        initialRoute: '/certificates/ASODYA-FIXTURE-CODE',
        certificateService: service,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fixture completion quiz'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(
      requests.single.url.path,
      '/apps/certifications/v1/certificates/ASODYA-FIXTURE-CODE',
    );
  });
}
