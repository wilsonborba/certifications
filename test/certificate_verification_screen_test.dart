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
    var completeness = 'partial_with_interruptions';
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
            'focus_lost_count': completeness == 'no_events_recorded' ? 0 : 1,
            'page_hidden_count': completeness == 'no_events_recorded' ? 0 : 1,
            'page_return_count': completeness == 'no_events_recorded' ? 0 : 1,
            'known_away_ms': completeness == 'no_events_recorded' ? 0 : 1200,
            'reconnect_count': 0,
            'refresh_count': 0,
            'unknown_gap_count': completeness == 'partial_with_interruptions'
                ? 1
                : 0,
            'completeness': completeness,
            'disclaimer': 'Observed browser activity only.',
            'events': completeness == 'no_events_recorded'
                ? []
                : [
                    {
                      'id': 'event-1',
                      'event_kind': 'page_hidden',
                      'duration_ms': 0,
                      'occurred_at': 1759996400,
                    },
                    {
                      'id': 'event-2',
                      'event_kind': 'future_internal_value',
                      'duration_ms': 0,
                      'occurred_at': 1759996500,
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
    Future<void> show(Locale locale, {Key? key}) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackMaterialLocalizationsDelegate(),
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          home: CertificateVerificationScreen(
            key: key,
            code: 'CODE-1',
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(const Locale('en'));

    expect(find.text('Certificate verification'), findsNWidgets(2));
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Ana Example'), findsOneWidget);
    expect(find.text('Sample quiz'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('CODE-1'), findsOneWidget);
    expect(find.textContaining('cheat'), findsNothing);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Download image'), findsOneWidget);
    final localizations = MaterialLocalizations.of(
      tester.element(find.text('Issued')),
    );
    final issuedAt = DateTime.fromMillisecondsSinceEpoch(
      1760000000 * 1000,
    ).toLocal();
    final issuedDate = localizations.formatFullDate(issuedAt);
    expect(issuedDate, contains('2025'));
    expect(issuedDate, isNot(localizations.formatMediumDate(issuedAt)));
    expect(find.text(issuedDate), findsOneWidget);

    await tester.tap(find.text('Recorded browser activity'));
    await tester.pumpAndSettle();
    expect(find.text('Observed browser activity only.'), findsOneWidget);
    expect(
      find.text('Record completeness: Partial (with interruptions)'),
      findsOneWidget,
    );
    expect(find.text('Page hidden'), findsNWidgets(2));
    expect(find.text('page_hidden'), findsNothing);
    expect(find.text('future_internal_value'), findsNothing);
    expect(find.text('Recorded browser activity'), findsNWidgets(2));
    expect(find.text('Unknown gaps'), findsOneWidget);
    final eventAt = DateTime.fromMillisecondsSinceEpoch(
      1759996400 * 1000,
    ).toLocal();
    final eventDateTime =
        '${localizations.formatFullDate(eventAt)} '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(eventAt))}';
    expect(eventDateTime, isNot(localizations.formatMediumDate(eventAt)));
    expect(find.text(eventDateTime), findsOneWidget);
    expect(paths, ['/apps/certifications/v1/certificates/CODE-1']);

    await show(const Locale('pt'));
    expect(
      find.text('Integridade do registro: Parcial (com interrupções)'),
      findsOneWidget,
    );
    expect(find.text('Página ocultada'), findsNWidgets(2));
    expect(find.text('page_hidden'), findsNothing);
    expect(find.text('future_internal_value'), findsNothing);

    await show(const Locale('th'));
    expect(
      find.text('ความครบถ้วนของบันทึก: บางส่วน (มีช่วงขาดตอน)'),
      findsOneWidget,
    );
    expect(find.text('ซ่อนหน้า'), findsNWidgets(2));
    expect(find.text('page_hidden'), findsNothing);
    expect(find.text('future_internal_value'), findsNothing);

    completeness = 'complete_observed';
    await show(const Locale('en'), key: const ValueKey('complete'));
    await tester.tap(find.text('Recorded browser activity').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Record completeness: Complete (observed)'),
      findsOneWidget,
    );

    completeness = 'no_events_recorded';
    await show(const Locale('en'), key: const ValueKey('no-events'));
    await tester.tap(find.text('Recorded browser activity').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Record completeness: No events recorded'),
      findsOneWidget,
    );

    completeness = 'future_completeness_value';
    await show(const Locale('en'), key: const ValueKey('unknown'));
    await tester.tap(find.text('Recorded browser activity').first);
    await tester.pumpAndSettle();
    expect(find.text('Record completeness: Unknown'), findsOneWidget);
    expect(find.text('future_completeness_value'), findsNothing);
  });
}
