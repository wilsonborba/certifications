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

  @override
  Future<AttemptHistoryPage> listAttempts(AttemptHistoryQuery query) async {
    calls++;
    queries.add(query);
    if (failFirst && calls == 1) throw StateError('fixture network failure');
    return AttemptHistoryPage(items: const [], total: 0, limit: 20, offset: 0);
  }
}

Widget _app(Widget child) => MaterialApp(
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
  testWidgets('history uses calendar dates and inclusive local-day bounds', (
    tester,
  ) async {
    final api = _HistoryApi();
    await tester.pumpWidget(_app(AttemptHistoryScreen(api: api)));
    await tester.pumpAndSettle();

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
