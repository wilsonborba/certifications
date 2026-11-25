import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study_history.dart';
import 'package:certifications/domain/services/study_history_api_service.dart';
import 'package:certifications/presentation/widgets/completed_quizzes/created_quiz_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _HistoryApi extends StudyHistoryApiService {
  final queries = <StudyHistoryQuery>[];
  bool failFirst = false;
  bool empty = false;

  @override
  Future<StudyHistoryPage> list(StudyHistoryQuery query) async {
    queries.add(query);
    if (failFirst && queries.length == 1) {
      throw StateError('fixture network failure');
    }
    final start = query.offset;
    final length = empty || start >= 55
        ? 0
        : (55 - start).clamp(0, query.limit);
    return StudyHistoryPage.fromJson({
      'items': [
        for (var i = 0; i < length; i++)
          {
            'id': 'study-${start + i + 1}',
            'title': 'Created quiz ${start + i + 1}',
            'description': '',
            'source_origin': 'upload',
            'status': query.status ?? 'active',
            'quiz_id': 'quiz-${start + i + 1}',
            'expires_at': null,
            'created_at': 1700000000 + start + i,
            'updated_at': 1700000000 + start + i,
          },
      ],
      'total': empty ? 0 : 55,
      'limit': query.limit,
      'offset': query.offset,
      'available_tags': [
        {'slug': 'biology', 'label': 'Biology'},
      ],
    });
  }
}

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) => MaterialApp(
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      size: const Size(390, 844),
      textScaler: TextScaler.linear(textScale),
    ),
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
  testWidgets('creation history filters and paginates beyond fifty rows', (
    tester,
  ) async {
    final api = _HistoryApi();
    await tester.pumpWidget(_app(CreatedQuizHistoryScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Created quiz 1'), findsOneWidget);
    expect(find.text('1-20 of 55'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('created-history-advanced-filters')),
    );
    await tester.pumpAndSettle();

    final search = find.widgetWithText(
      TextField,
      'Search study and quiz titles',
    );
    final quizId = find.widgetWithText(TextField, 'Quiz ID');
    await tester.enterText(search, ' Cell Biology ');
    await tester.enterText(quizId, ' quiz-42 ');

    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biology').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Created from: Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Created through: Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(api.queries.last.q, 'Cell Biology');
    expect(api.queries.last.quizId, 'quiz-42');
    expect(api.queries.last.status, 'active');
    expect(api.queries.last.tag, 'biology');
    final today = DateTime.now();
    expect(
      api.queries.last.createdFrom,
      DateTime(today.year, today.month, today.day).millisecondsSinceEpoch ~/
          1000,
    );
    expect(
      api.queries.last.createdTo,
      DateTime(today.year, today.month, today.day + 1).millisecondsSinceEpoch ~/
              1000 -
          1,
    );
    expect(api.queries.last.offset, 0);

    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(api.queries.last.offset, 40);
    expect(find.text('41-55 of 55'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(api.queries.last.offset, 0);
    expect(api.queries.last.q, isNull);
    expect(api.queries.last.quizId, isNull);
    expect(api.queries.last.status, isNull);
    expect(api.queries.last.tag, isNull);
  });

  testWidgets('phone shows the full localized title and keeps search visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        CreatedQuizHistoryScreen(api: _HistoryApi()),
        locale: const Locale('pt'),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('Histórico de questionários criados');
    expect(title, findsOneWidget);
    final titleRect = tester.getRect(title);
    expect(titleRect.left, greaterThanOrEqualTo(0));
    expect(titleRect.right, lessThanOrEqualTo(390));
    expect(
      find.text('Buscar títulos de estudos e questionários'),
      findsOneWidget,
    );
    expect(find.text('ID do questionário'), findsNothing);
    expect(find.text('Created quiz 1'), findsOneWidget);
    expect(find.text('1-20 de 55'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('created-history-advanced-filters')),
    );
    await tester.pumpAndSettle();
    expect(find.text('ID do questionário'), findsOneWidget);
    expect(find.text('Criado a partir de: Escolher data'), findsOneWidget);
    expect(find.text('Aplicar filtros'), findsOneWidget);
    expect(find.text('Limpar filtros'), findsOneWidget);
  });

  testWidgets('history request errors retry and empty results are distinct', (
    tester,
  ) async {
    final api = _HistoryApi()
      ..failFirst = true
      ..empty = true;
    await tester.pumpWidget(_app(CreatedQuizHistoryScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(api.queries.length, 2);
    expect(find.text('You have not created any quizzes yet.'), findsOneWidget);
  });
}
