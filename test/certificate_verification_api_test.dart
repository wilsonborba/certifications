import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
