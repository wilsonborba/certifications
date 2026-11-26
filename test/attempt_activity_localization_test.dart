import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt_review.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:certifications/presentation/widgets/attempt_review_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AttemptResultsApi extends AttemptReviewApiService {
  @override
  Future<AttemptResults> getResults(String attemptId) async =>
      const AttemptResults(
        id: 'attempt-localized',
        quizId: 'quiz-localized',
        quizVersionId: 'version-localized',
        status: 'in_progress',
        scoreCorrect: 0,
        scoreTotal: 0,
        startedAt: 1,
        stats: {},
        activitySummary: {
          'completeness': 'partial_with_interruptions',
          'disclaimer': 'Observed browser activity only.',
          'focus_lost_count': 1,
          'page_hidden_count': 2,
          'page_return_count': 3,
          'known_away_ms': 62000,
          'reconnect_count': 4,
          'refresh_count': null,
          'unknown_gap_count': 6,
        },
        questions: [],
      );
}

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  home: AttemptResultsScreen(
    attemptId: 'attempt-localized',
    api: _AttemptResultsApi(),
  ),
);

void main() {
  for (final testCase in [
    (
      locale: const Locale('en'),
      completeness: 'Record completeness: Partial (with interruptions)',
      labels: [
        'Focus lost',
        'Page hidden',
        'Page returned',
        'Known time away',
        'Reconnects',
        'Refreshes',
        'Unknown gaps',
      ],
      away: '1m 2s',
      unavailable: 'Unavailable',
    ),
    (
      locale: const Locale('pt'),
      completeness: 'Integridade do registro: Parcial (com interrupções)',
      labels: [
        'Perda de foco',
        'Página ocultada',
        'Retorno à página',
        'Tempo conhecido fora da página',
        'Reconexões',
        'Atualizações',
        'Lacunas desconhecidas',
      ],
      away: '1min 2s',
      unavailable: 'Indisponível',
    ),
    (
      locale: const Locale('th'),
      completeness: 'ความครบถ้วนของบันทึก: บางส่วน (มีช่วงขาดตอน)',
      labels: [
        'การสูญเสียโฟกัส',
        'ซ่อนหน้า',
        'กลับมาที่หน้า',
        'เวลาที่ทราบว่าออกจากหน้า',
        'การเชื่อมต่อใหม่',
        'การโหลดใหม่',
        'ช่วงเวลาที่ไม่ทราบ',
      ],
      away: '1 นาที 2 วินาที',
      unavailable: 'ไม่พร้อมใช้งาน',
    ),
  ]) {
    testWidgets('attempt activity is localized in ${testCase.locale}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(testCase.locale));
      await tester.pumpAndSettle();
      final activityTitle = find.text(
        AppLocalizations(testCase.locale).text('attemptActivity'),
      );
      await tester.ensureVisible(activityTitle);
      await tester.tap(activityTitle);
      await tester.pumpAndSettle();

      expect(find.textContaining(testCase.completeness), findsOneWidget);
      expect(
        find.textContaining('Observed browser activity only.'),
        findsOneWidget,
      );
      expect(find.text('partial_with_interruptions'), findsNothing);
      final expectedValues = [
        '1',
        '2',
        '3',
        testCase.away,
        '4',
        testCase.unavailable,
        '6',
      ];
      for (var index = 0; index < testCase.labels.length; index++) {
        final row = find.ancestor(
          of: find.text(testCase.labels[index]),
          matching: find.byType(ListTile),
        );
        expect(row, findsOneWidget, reason: testCase.labels[index]);
        expect(
          find.descendant(of: row, matching: find.text(expectedValues[index])),
          findsOneWidget,
          reason: testCase.labels[index],
        );
      }
      for (final rawKey in [
        'focus_lost_count',
        'page_hidden_count',
        'page_return_count',
        'known_away_ms',
        'reconnect_count',
        'refresh_count',
        'unknown_gap_count',
      ]) {
        expect(find.text(rawKey), findsNothing);
      }
    });
  }
}
