import 'dart:async';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt_review.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/models/study_history.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/domain/services/study_history_api_service.dart';
import 'package:certifications/presentation/widgets/study_dashboard/on_study_dashboard.dart';
import 'package:certifications/presentation/widgets/completed_quizzes/on_completed_quizzes.dart';
import 'package:certifications/presentation/widgets/attempt_review_screens.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _HistoryApi extends StudyHistoryApiService {
  _HistoryApi(this.loadPage);

  final Future<StudyHistoryPage> Function(StudyHistoryQuery query) loadPage;
  final queries = <StudyHistoryQuery>[];

  @override
  Future<StudyHistoryPage> list(StudyHistoryQuery query) {
    queries.add(query);
    return loadPage(query);
  }
}

class _QuizApi extends QuizApiService {
  @override
  Future<List<Quiz>> listCompleted() async => [];
}

class _UnavailableQuizApi extends QuizApiService {
  @override
  Future<List<Quiz>> listCompleted() async => throw const QuizApiException(404);
}

class _AttemptApi extends AttemptReviewApiService {
  _AttemptApi({this.failOverview = false});

  final bool failOverview;

  @override
  Future<AttemptOverview> getOverview() async {
    if (failOverview) throw const AttemptReviewApiException(503);
    return const AttemptOverview(
      createdQuizCount: 1,
      completedAttemptCount: 2,
      distinctQuizzesAttempted: 1,
      allAttemptMeanScorePct: null,
      allAttemptScoreDenominator: 0,
      latestAttemptPerQuizMeanScorePct: null,
      latestAttemptPerQuizScoreDenominator: 0,
      averageCompletionTimeSeconds: null,
      completionTimeDenominator: 0,
      questionProvenance: {},
    );
  }

  @override
  Future<AttemptHistoryPage> listAttempts(AttemptHistoryQuery query) async =>
      const AttemptHistoryPage(items: [], total: 0, limit: 20, offset: 0);
}

class _StudyApi extends StudyApiService {
  final loadedIds = <String>[];

  @override
  Future<Study> get(String id) async {
    loadedIds.add(id);
    return Study.fromJson({
      'study': {'id': id, 'title': 'Older draft', 'status': 'draft'},
      'sources': [],
    });
  }
}

Map<String, dynamic> _studyJson(String id, String title, int createdAt) => {
  'study': {
    'id': id,
    'title': title,
    'status': 'draft',
    'created_at': createdAt,
  },
  'sources': [],
};

StudyHistoryPage _page({
  required int total,
  required int offset,
  required List<Map<String, dynamic>> items,
  int limit = 20,
}) => StudyHistoryPage.fromJson({
  'items': items,
  'total': total,
  'limit': limit,
  'offset': offset,
  'available_tags': [],
});

StudyHistoryPage _orderedPage(StudyHistoryQuery query) {
  final count = (21 - query.offset).clamp(0, query.limit);
  return _page(
    total: 21,
    offset: query.offset,
    items: [
      for (var index = 0; index < count; index++)
        _studyJson(
          'draft-${query.offset + index}',
          query.offset + index == 20
              ? 'Older draft'
              : 'Newest draft ${query.offset + index + 1}',
          1760000000 - query.offset - index,
        ),
    ],
  );
}

Widget _app({
  required _HistoryApi historyApi,
  required _StudyApi studyApi,
  QuizApiService? quizApi,
  AttemptReviewApiService? attemptApi,
}) {
  final attempts = attemptApi ?? _AttemptApi();
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      FallbackCupertinoLocalizationsDelegate(),
      FallbackMaterialLocalizationsDelegate(),
      DefaultWidgetsLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routes: {'/v1/history': (_) => AttemptHistoryScreen(api: attempts)},
    home: OnStudyDashboardScreen(
      studyApi: studyApi,
      historyApi: historyApi,
      quizApi: quizApi ?? _QuizApi(),
      attemptApi: attempts,
    ),
  );
}

Widget _completedQuizzesApp({
  required _HistoryApi historyApi,
  required QuizApiService quizApi,
}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: OnCompletedQuizzesScreen(api: quizApi, historyApi: historyApi),
);

void main() {
  testWidgets('dashboard loads and resumes a draft from the next page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyApi = _HistoryApi((query) async => _orderedPage(query));
    final studyApi = _StudyApi();
    await DraftProgressStore.instance.clear('draft-20');
    addTearDown(() => DraftProgressStore.instance.clear('draft-20'));
    await tester.pumpWidget(_app(historyApi: historyApi, studyApi: studyApi));
    await tester.pumpAndSettle();

    expect(historyApi.queries.single.limit, 20);
    expect(historyApi.queries.single.offset, 0);
    expect(find.text('Newest draft 1'), findsWidgets);
    expect(find.text('Newest draft 20'), findsOneWidget);

    final next = find.byTooltip('Next');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(historyApi.queries.last.limit, 20);
    expect(historyApi.queries.last.offset, 20);
    expect(find.text('Older draft'), findsWidgets);
    final olderDraftTitle = find.text('Older draft').last;
    await tester.ensureVisible(olderDraftTitle);
    await tester.tap(olderDraftTitle);
    await tester.pumpAndSettle();

    expect(studyApi.loadedIds, ['draft-20']);
  });

  testWidgets('dashboard server search ignores a stale response', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final staleSearch = Completer<StudyHistoryPage>();
    final historyApi = _HistoryApi((query) async {
      if (query.q == 'a') return staleSearch.future;
      if (query.q == 'ab') {
        return _page(
          total: 1,
          offset: 0,
          items: [_studyJson('current-result', 'Current result', 1760000000)],
        );
      }
      return _page(
        total: 1,
        offset: 0,
        items: [_studyJson('initial-result', 'Initial result', 1760000000)],
      );
    });
    await tester.pumpWidget(
      _app(historyApi: historyApi, studyApi: _StudyApi()),
    );
    await tester.pumpAndSettle();

    final search = find.byType(TextField).first;
    await tester.ensureVisible(search);
    await tester.enterText(search, 'a');
    await tester.pump();
    await tester.enterText(search, 'ab');
    await tester.pumpAndSettle();
    expect(historyApi.queries.map((query) => query.q), [null, 'a', 'ab']);
    expect(find.text('Current result'), findsOneWidget);

    staleSearch.complete(
      _page(
        total: 1,
        offset: 0,
        items: [_studyJson('stale-result', 'Stale result', 1760000000)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Current result'), findsOneWidget);
    expect(find.text('Stale result'), findsNothing);
  });

  testWidgets('dashboard retry returns to an honest empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var requests = 0;
    final historyApi = _HistoryApi((query) async {
      requests++;
      if (requests == 1) throw const StudyHistoryApiException(503);
      return _page(total: 0, offset: query.offset, items: []);
    });
    await tester.pumpWidget(
      _app(historyApi: historyApi, studyApi: _StudyApi()),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('No studies yet'), findsOneWidget);
    expect(find.byTooltip('Next'), findsNothing);
  });

  testWidgets('legacy completed-quizzes failure keeps V2 history reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyApi = _HistoryApi(
      (query) async => _page(
        total: 1,
        offset: query.offset,
        items: [_studyJson('v2-history', 'V2 history row', 1760000000)],
      ),
    );
    await tester.pumpWidget(
      _app(
        historyApi: historyApi,
        studyApi: _StudyApi(),
        quizApi: _UnavailableQuizApi(),
        attemptApi: _AttemptApi(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You have no completed quizzes yet.'), findsNothing);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    final completedTile = find.ancestor(
      of: find.text('Completed Quizzes'),
      matching: find.byType(PremiumHoverCard),
    );
    expect(
      find.descendant(of: completedTile, matching: find.text('1')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('View completed quizzes'));
    await tester.pumpAndSettle();
    expect(find.text('Attempt history'), findsOneWidget);
  });

  testWidgets('created-study history has an independent dashboard entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyApi = _HistoryApi(
      (query) async => _page(
        total: 1,
        offset: query.offset,
        items: [_studyJson('v2-history', 'V2 history row', 1760000000)],
      ),
    );
    await tester.pumpWidget(
      _app(
        historyApi: historyApi,
        studyApi: _StudyApi(),
        quizApi: _UnavailableQuizApi(),
        attemptApi: _AttemptApi(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz creation history'));
    await tester.pumpAndSettle();
    expect(find.text('V2 history row'), findsOneWidget);
  });

  testWidgets('legacy error screen retains the V2 history entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyApi = _HistoryApi(
      (query) async => _page(
        total: 1,
        offset: query.offset,
        items: [_studyJson('v2-history', 'V2 history row', 1760000000)],
      ),
    );
    await tester.pumpWidget(
      _completedQuizzesApp(
        historyApi: historyApi,
        quizApi: _UnavailableQuizApi(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Quiz creation history'));
    await tester.pumpAndSettle();
    expect(find.text('V2 history row'), findsOneWidget);
  });

  testWidgets('attempt overview failure leaves completed count unknown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyApi = _HistoryApi(
      (query) async => _page(
        total: 1,
        offset: query.offset,
        items: [_studyJson('study-1', 'Study one', 1760000000)],
      ),
    );
    await tester.pumpWidget(
      _app(
        historyApi: historyApi,
        studyApi: _StudyApi(),
        attemptApi: _AttemptApi(failOverview: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('zero-study dashboard preserves known completed quiz history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final historyApi = _HistoryApi(
      (query) async => _page(total: 0, offset: query.offset, items: []),
    );
    await tester.pumpWidget(
      _app(historyApi: historyApi, studyApi: _StudyApi()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No studies yet'), findsWidgets);
    final completedTile = find.ancestor(
      of: find.text('Completed Quizzes'),
      matching: find.byType(PremiumHoverCard),
    );
    expect(
      find.descendant(of: completedTile, matching: find.text('1')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('View completed quizzes'));
    await tester.pumpAndSettle();
    expect(find.text('Attempt history'), findsOneWidget);
  });
}
