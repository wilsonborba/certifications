import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/presentation/widgets/certificates/certificate_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('renders factual certificate status and online activity only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/files/pdf')) {
        return http.Response.bytes(
          utf8.encode('%PDF fixture'),
          200,
          headers: const {'content-type': 'application/pdf'},
        );
      }
      if (request.url.path.endsWith('/files/image')) {
        return http.Response.bytes(
          utf8.encode('<svg/>'),
          200,
          headers: const {'content-type': 'image/svg+xml'},
        );
      }
      return http.Response(
        jsonEncode({
          'verification_code': 'CODE-1',
          'status': 'active',
          'revocation_reason': '',
          'holder_public_id': 'holder-public-1',
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

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        home: CertificateVerificationScreen(code: 'CODE-1', service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Certificate verification'), findsNWidgets(2));
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Ana Example'), findsOneWidget);
    expect(find.text('Sample quiz'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('CODE-1'), findsOneWidget);
    expect(find.textContaining('cheat'), findsNothing);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Download image'), findsOneWidget);

    await tester.tap(find.text('Recorded browser activity'));
    await tester.pumpAndSettle();
    expect(find.text('Observed browser activity only.'), findsOneWidget);
    expect(find.textContaining('partial'), findsOneWidget);
    expect(find.text('Unknown gaps'), findsOneWidget);
    expect(paths, ['/apps/certifications/v1/certificates/CODE-1']);
  });
}
