import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt_review.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:certifications/presentation/widgets/attempt_review_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _HistoryApi extends AttemptReviewApiService {
  int calls = 0;
  final queries = <AttemptHistoryQuery>[];
  bool failFirst = false;
  List<AttemptHistoryItem> items = const [];

  @override
  Future<AttemptHistoryPage> listAttempts(AttemptHistoryQuery query) async {
    calls++;
    queries.add(query);
    if (failFirst && calls == 1) throw StateError('fixture network failure');
    return AttemptHistoryPage(
      items: items,
      total: items.length,
      limit: 20,
      offset: 0,
    );
  }
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: child!,
  ),
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets(
    'completed history filter comes from typed route state and can clear',
    (tester) async {
      final api = _HistoryApi();
      await tester.pumpWidget(
        _app(
          AttemptHistoryScreen(
            api: api,
            initialStatus: AttemptHistoryStatus.fromQueryValue('completed'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.queries.single.status, AttemptHistoryStatus.completed);
      final completedFilter = find.byType(FilterChip);
      expect(tester.widget<FilterChip>(completedFilter).selected, isTrue);
      await tester.tap(completedFilter);
      await tester.pumpAndSettle();
      expect(api.queries.last.status, isNull);
      expect(tester.widget<FilterChip>(completedFilter).selected, isFalse);
      expect(AttemptHistoryStatus.fromQueryValue('unknown'), isNull);
    },
  );

  testWidgets(
    'history shows only producer supplied repeat metadata by locale',
    (tester) async {
      final rows = [
        AttemptHistoryItem(
          id: 'repeat',
          quizId: 'quiz',
          quizTitle: 'Repeated quiz',
          quizOrigin: 'fixture',
          quizVersionId: 'v1',
          status: 'completed',
          attemptSequence: 2,
          scoreCorrect: 75,
          scoreTotal: 100,
          previousAttemptScorePct: 50,
          scoreChangePercentagePoints: 25,
          startedAt: 1760000000,
        ),
        AttemptHistoryItem(
          id: 'zero-repeat',
          quizId: 'zero-quiz',
          quizTitle: 'Zero score retry',
          quizOrigin: 'fixture',
          quizVersionId: 'v1',
          status: 'completed',
          attemptSequence: 2,
          scoreCorrect: 0,
          scoreTotal: 100,
          previousAttemptScorePct: 0,
          scoreChangePercentagePoints: 0,
          startedAt: 1760000000,
        ),
        AttemptHistoryItem(
          id: 'first',
          quizId: 'first-quiz',
          quizTitle: 'First attempt',
          quizOrigin: 'fixture',
          quizVersionId: 'v1',
          status: 'completed',
          attemptSequence: 1,
          scoreCorrect: 90,
          scoreTotal: 100,
          startedAt: 1760000000,
        ),
        const AttemptHistoryItem(
          id: 'missing',
          quizId: 'missing-quiz',
          quizTitle: 'Metadata unavailable',
          quizOrigin: 'fixture',
          quizVersionId: 'v1',
          status: 'completed',
          startedAt: 1760000000,
        ),
      ];
      final cases = [
        (
          locale: const Locale('en'),
          sequenceLabel: 'Attempt ',
          sequence: 'Attempt 2',
          firstSequence: 'Attempt 1',
          previous: 'Previous score: 50.0%',
          change: 'Change from previous: 25.0 percentage points',
          zeroPrevious: 'Previous score: 0.0%',
          zeroChange: 'Change from previous: 0.0 percentage points',
          scoreRepeat: '75.0%',
          scoreZero: '0.0%',
          previousLabel: 'Previous score:',
          changeLabel: 'Change from previous:',
        ),
        (
          locale: const Locale('pt'),
          sequenceLabel: 'Tentativa ',
          sequence: 'Tentativa 2',
          firstSequence: 'Tentativa 1',
          previous: 'Pontuação anterior: 50,0%',
          change: 'Variação em relação à anterior: 25,0 pontos percentuais',
          zeroPrevious: 'Pontuação anterior: 0,0%',
          zeroChange: 'Variação em relação à anterior: 0,0 pontos percentuais',
          scoreRepeat: '75,0%',
          scoreZero: '0,0%',
          previousLabel: 'Pontuação anterior:',
          changeLabel: 'Variação em relação à anterior:',
        ),
        (
          locale: const Locale('th'),
          sequenceLabel: 'ครั้งที่ ',
          sequence: 'ครั้งที่ 2',
          firstSequence: 'ครั้งที่ 1',
          previous: 'คะแนนครั้งก่อน: 50.0%',
          change: 'เปลี่ยนแปลงจากครั้งก่อน: 25.0 จุดเปอร์เซ็นต์',
          zeroPrevious: 'คะแนนครั้งก่อน: 0.0%',
          zeroChange: 'เปลี่ยนแปลงจากครั้งก่อน: 0.0 จุดเปอร์เซ็นต์',
          scoreRepeat: '75.0%',
          scoreZero: '0.0%',
          previousLabel: 'คะแนนครั้งก่อน:',
          changeLabel: 'เปลี่ยนแปลงจากครั้งก่อน:',
        ),
      ];

      for (final testCase in cases) {
        final api = _HistoryApi()..items = [rows[0], rows[1]];
        await tester.pumpWidget(
          _app(AttemptHistoryScreen(api: api), locale: testCase.locale),
        );
        await tester.pumpAndSettle();

        expect(find.text(testCase.sequence), findsNWidgets(2));
        expect(find.text(testCase.previous), findsOneWidget);
        expect(find.text(testCase.change), findsOneWidget);
        expect(find.text(testCase.scoreZero), findsOneWidget);
        expect(find.text(testCase.zeroPrevious), findsOneWidget);
        expect(find.text(testCase.zeroChange), findsOneWidget);
        expect(find.text(testCase.scoreRepeat), findsOneWidget);
        expect(find.text('Zero score retry'), findsOneWidget);
        final missingApi = _HistoryApi()..items = [rows[2], rows[3]];
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          _app(
            AttemptHistoryScreen(
              api: missingApi,
              key: ValueKey('missing-${testCase.locale.languageCode}'),
            ),
            locale: testCase.locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('First attempt'), findsOneWidget);
        expect(find.text(testCase.firstSequence), findsOneWidget);
        final firstAttemptRow = find.ancestor(
          of: find.text('First attempt'),
          matching: find.byType(ListTile),
        );
        expect(
          find.descendant(
            of: firstAttemptRow,
            matching: find.textContaining(testCase.previousLabel),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: firstAttemptRow,
            matching: find.textContaining(testCase.changeLabel),
          ),
          findsNothing,
        );
        expect(find.text('Metadata unavailable'), findsOneWidget);
        final missingMetadataRow = find.ancestor(
          of: find.text('Metadata unavailable'),
          matching: find.byType(ListTile),
        );
        for (final label in [
          testCase.sequenceLabel,
          testCase.previousLabel,
          testCase.changeLabel,
        ]) {
          expect(
            find.descendant(
              of: missingMetadataRow,
              matching: find.textContaining(label),
            ),
            findsNothing,
          );
        }
      }
    },
  );

  testWidgets('history uses calendar dates and inclusive local-day bounds', (
    tester,
  ) async {
    final api = _HistoryApi();
    await tester.pumpWidget(_app(AttemptHistoryScreen(api: api)));
    await tester.pumpAndSettle();

    expect(api.queries.single.status, isNull);
    expect(find.text('Unix timestamp'), findsNothing);
    expect(find.text('Choose date'), findsNWidgets(2));
    await tester.tap(find.text('Choose date').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    expect(
      api.queries.last.startedFrom,
      DateTime(today.year, today.month, today.day).millisecondsSinceEpoch ~/
          1000,
    );
    expect(
      api.queries.last.startedTo,
      DateTime(today.year, today.month, today.day + 1).millisecondsSinceEpoch ~/
              1000 -
          1,
    );
  });

  testWidgets('history request error can be retried', (tester) async {
    final api = _HistoryApi()..failFirst = true;
    await tester.pumpWidget(_app(AttemptHistoryScreen(api: api)));
    await tester.pumpAndSettle();
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(api.calls, 2);
    expect(find.text('No attempts match these filters.'), findsOneWidget);
  });
}
