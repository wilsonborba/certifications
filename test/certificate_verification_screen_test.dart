import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/presentation/widgets/certificates/certificate_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('renders factual certificate status and online activity only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final issuedAtLocal = DateTime(2025, 10, 9, 12);
    final eventAtLocal = DateTime(2025, 10, 9, 10, 30);
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
          'issued_at': issuedAtLocal.millisecondsSinceEpoch ~/ 1000,
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
                      'occurred_at':
                          eventAtLocal.millisecondsSinceEpoch ~/ 1000,
                    },
                    {
                      'id': 'event-2',
                      'event_kind': 'future_internal_value',
                      'duration_ms': 0,
                      'occurred_at':
                          eventAtLocal
                              .add(const Duration(minutes: 5))
                              .millisecondsSinceEpoch ~/
                          1000,
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
    Future<void> show(
      Locale locale, {
      Key? key,
      Key? appKey,
      double textScale = 1,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          key: appKey,
          locale: locale,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
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
    final issuedAt = issuedAtLocal;
    final issuedDate = DateFormat.yMMMMEEEEd('en').format(issuedAt);
    expect(issuedDate, contains('Thursday'));
    expect(issuedDate, contains('October'));
    expect(issuedDate, contains('2025'));
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
    final eventAt = eventAtLocal;
    final eventDateTime =
        '${DateFormat.yMMMMEEEEd('en').format(eventAt)} '
        '${DateFormat.jm('en').format(eventAt)}';
    expect(eventDateTime, contains('2025'));
    expect(find.text(eventDateTime), findsOneWidget);
    expect(paths, ['/apps/certifications/v1/certificates/CODE-1']);

    await show(const Locale('pt'));
    final portugueseDate = DateFormat.yMMMMEEEEd('pt').format(issuedAt);
    expect(portugueseDate, contains('quinta-feira'));
    expect(portugueseDate, contains('outubro'));
    expect(portugueseDate, contains('2025'));
    expect(find.text(portugueseDate), findsOneWidget);
    expect(
      find.text('Integridade do registro: Parcial (com interrupções)'),
      findsOneWidget,
    );
    final portugueseEventDateTime =
        '${DateFormat.yMMMMEEEEd('pt').format(eventAt)} '
        '${DateFormat.jm('pt').format(eventAt)}';
    expect(portugueseEventDateTime, contains('quinta-feira'));
    expect(portugueseEventDateTime, contains('outubro'));
    expect(portugueseEventDateTime, contains('2025'));
    expect(find.text(portugueseEventDateTime), findsOneWidget);
    expect(find.text('Página ocultada'), findsNWidgets(2));
    expect(find.text('page_hidden'), findsNothing);
    expect(find.text('future_internal_value'), findsNothing);

    await show(const Locale('th'));
    final thaiDate = DateFormat.yMMMMEEEEd('th').format(issuedAt);
    expect(thaiDate, contains('พฤหัสบดี'));
    expect(thaiDate, contains('ตุลาคม'));
    expect(thaiDate, contains('2025'));
    expect(find.text(thaiDate), findsOneWidget);
    final thaiEventDateTime =
        '${DateFormat.yMMMMEEEEd('th').format(eventAt)} '
        '${DateFormat.jm('th').format(eventAt)}';
    expect(thaiEventDateTime, contains('พฤหัสบดี'));
    expect(thaiEventDateTime, contains('ตุลาคม'));
    expect(thaiEventDateTime, contains('2025'));
    expect(find.text(thaiEventDateTime), findsOneWidget);
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

    completeness = 'partial_with_interruptions';
    for (final (width, textScale) in [(390, 1.0), (320, 1.3)]) {
      tester.view.physicalSize = Size(width.toDouble(), 844);
      await show(
        const Locale('en'),
        appKey: ValueKey('activity-app-$width'),
        textScale: textScale,
      );
      final activityTitle = find.text('Recorded browser activity').first;
      await tester.ensureVisible(activityTitle);
      await tester.pumpAndSettle();
      await tester.tap(activityTitle);
      await tester.pumpAndSettle();

      expect(find.text('Observed browser activity only.'), findsOneWidget);
      expect(find.text('0m 1s'), findsOneWidget);
      final context = tester.element(
        find.byType(CertificateVerificationScreen),
      );
      final factLabels = [
        context.tr('certificateFocusLoss'),
        context.tr('certificatePageHidden'),
        context.tr('certificatePageReturns'),
        context.tr('certificateKnownAway'),
        context.tr('certificateReconnects'),
        context.tr('certificateRefreshes'),
        context.tr('certificateUnknownGaps'),
      ];
      final factLeftEdges = [
        for (final label in factLabels)
          tester.getTopLeft(find.text(label).first).dx,
      ];
      final leftEdgeSpread =
          factLeftEdges.reduce((a, b) => a > b ? a : b) -
          factLeftEdges.reduce((a, b) => a < b ? a : b);
      expect(
        leftEdgeSpread,
        lessThanOrEqualTo(1),
        reason:
            'activity fact labels should share a left edge at ${width}px, text scale $textScale',
      );
      expect(tester.takeException(), isNull);
    }
  });
}
