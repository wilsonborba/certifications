import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'identity and idempotent issuance use the confirmed Rust API DTOs',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/me/identity') &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'holder_id': 'internal-holder-id',
              'display_name': 'Ana Silva',
              'confirmed': true,
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/me/identity')) {
          return http.Response(
            jsonEncode({
              'holder_id': 'internal-holder-id',
              'display_name': 'Ana Silva',
              'confirmed': true,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'id': 'certificate-internal-id',
            'verification_code': 'ASODYA-CODE123456',
            'holder_public_id': 'holder-public-id',
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

      final current = await service.getMyIdentity();
      final confirmed = await service.confirmMyIdentity('Ana Silva');
      final issued = await service.issueForAttempt('attempt-1');

      expect(current.confirmed, isTrue);
      expect(current.displayName, 'Ana Silva');
      expect(confirmed.holderId, 'internal-holder-id');
      expect(issued.verificationCode, 'ASODYA-CODE123456');
      expect(issued.scoreCorrect, 0); // zero is a factual score, not a verdict
      expect(requests.map((r) => '${r.method} ${r.url.path}'), [
        'GET /apps/certifications/v1/me/identity',
        'PUT /apps/certifications/v1/me/identity',
        'POST /apps/certifications/v1/attempts/attempt-1/certificate',
      ]);
      expect(jsonDecode(requests[1].body), {'display_name': 'Ana Silva'});
    },
  );

  test(
    'verification parses only factual status and activity summary',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/apps/certifications/v1/certificates/CODE-1');
        return http.Response(
          jsonEncode({
            'verification_code': 'CODE-1',
            'status': 'active',
            'revocation_reason': '',
            'holder_public_id': 'public-holder-1',
            'holder_name': 'Ana Example',
            'quiz_title': 'Sample quiz',
            'score_correct': 1,
            'score_total': 3,
            'issued_at': 1760000000,
            'revoked_at': null,
            'activity_summary': {
              'focus_lost_count': 1,
              'page_hidden_count': 1,
              'page_return_count': 1,
              'known_away_ms': 1200,
              'reconnect_count': 0,
              'refresh_count': 0,
              'unknown_gap_count': 1,
              'completeness': 'partial',
              'disclaimer': 'Observed browser activity only.',
              'events': [
                {
                  'id': 'event-1',
                  'event_kind': 'page_hidden',
                  'duration_ms': 0,
                  'occurred_at': 1760000001,
                },
              ],
            },
          }),
          200,
        );
      });
      final service = CertificateVerificationApiService(
        adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
      );

      final result = await service.verify('CODE-1');

      expect(result.status, 'active');
      expect(result.scoreCorrect, 1);
      expect(result.scoreTotal, 3);
      expect(result.activitySummary.completeness, 'partial');
      expect(result.activitySummary.unknownGapCount, 1);
      expect(result.activitySummary.events.single.eventKind, 'page_hidden');
    },
  );

  test('certificate downloads return only server artifact bytes', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/files/pdf')) {
        return http.Response.bytes(
          utf8.encode('%PDF-1.4 fixture'),
          200,
          headers: const {'content-type': 'application/pdf'},
        );
      }
      return http.Response.bytes(
        utf8.encode('<svg></svg>'),
        200,
        headers: const {'content-type': 'image/svg+xml'},
      );
    });
    final service = CertificateVerificationApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final pdf = await service.downloadPdf('CODE-1');
    final image = await service.downloadImage('CODE-1');

    expect(pdf.contentType, 'application/pdf');
    expect(utf8.decode(pdf.bytes), '%PDF-1.4 fixture');
    expect(image.contentType, 'image/svg+xml');
    expect(utf8.decode(image.bytes), '<svg></svg>');
    expect(requests.map((request) => request.url.path), [
      '/apps/certifications/v1/certificates/CODE-1/files/pdf',
      '/apps/certifications/v1/certificates/CODE-1/files/image',
    ]);
    expect(requests.every((request) => request.method == 'GET'), isTrue);
  });
}
