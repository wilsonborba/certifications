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
  Size size = const Size(390, 844),
  EdgeInsets viewInsets = EdgeInsets.zero,
}) => MaterialApp(
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      size: size,
      viewInsets: viewInsets,
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

Finder _fieldWithValue(String value) => find.byWidgetPredicate(
  (widget) => widget is EditableText && widget.controller.text.trim() == value,
  description: 'EditableText with value "$value"',
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
    final createdFrom = find.text('Created from: Choose date');
    await tester.ensureVisible(createdFrom);
    await tester.tap(createdFrom);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final createdThrough = find.text('Created through: Choose date');
    await tester.ensureVisible(createdThrough);
    await tester.tap(createdThrough);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final apply = find.text('Apply filters');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
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

    final clear = find.text('Clear filters');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(api.queries.last.offset, 0);
    expect(api.queries.last.q, isNull);
    expect(api.queries.last.quizId, isNull);
    expect(api.queries.last.status, isNull);
    expect(api.queries.last.tag, isNull);
  });

  testWidgets(
    'collapsing active phone filters preserves values and clear resets',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _HistoryApi();
      await tester.pumpWidget(_app(CreatedQuizHistoryScreen(api: api)));
      await tester.pumpAndSettle();

      final filters = find.byKey(
        const ValueKey('created-history-advanced-filters'),
      );
      await tester.tap(filters);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Cell Biology');
      await tester.enterText(find.byType(TextField).last, 'quiz-42');
      await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String?>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Biology').last);
      await tester.pumpAndSettle();

      await tester.tap(filters);
      await tester.pumpAndSettle();
      await tester.tap(filters);
      await tester.pumpAndSettle();
      expect(_fieldWithValue('Cell Biology'), findsOneWidget);
      expect(_fieldWithValue('quiz-42'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('study-history-status-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('study-history-tag-biology')),
        findsOneWidget,
      );

      final clear = find.text('Clear filters');
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .map((field) => field.controller!.text),
        everyElement(isEmpty),
      );
      expect(
        find.byKey(const ValueKey('study-history-status-null')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('study-history-tag-null')),
        findsOneWidget,
      );
      expect(api.queries.last.q, isNull);
      expect(api.queries.last.quizId, isNull);
      expect(api.queries.last.status, isNull);
      expect(api.queries.last.tag, isNull);
    },
  );

  testWidgets('phone shows the full localized title and keeps search visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

    final filters = find.byKey(
      const ValueKey('created-history-advanced-filters'),
    );
    await tester.ensureVisible(filters);
    await tester.tap(filters);
    await tester.pumpAndSettle();
    expect(find.text('ID do questionário'), findsOneWidget);
    expect(find.text('Criado a partir de: Escolher data'), findsOneWidget);
    expect(find.text('Aplicar filtros'), findsOneWidget);
    expect(find.text('Limpar filtros'), findsOneWidget);
  });

  testWidgets('short phone with keyboard keeps filters and paging reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _HistoryApi();
    await tester.pumpWidget(
      _app(
        CreatedQuizHistoryScreen(api: api),
        locale: const Locale('pt'),
        textScale: 1.3,
        size: const Size(390, 600),
        viewInsets: const EdgeInsets.only(bottom: 220),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Histórico de questionários criados'), findsOneWidget);
    expect(
      find.text('Buscar títulos de estudos e questionários'),
      findsOneWidget,
    );
    expect(find.text('1-20 de 55'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'initial short-height layout',
    );

    final filters = find.byKey(
      const ValueKey('created-history-advanced-filters'),
    );
    await tester.ensureVisible(filters);
    await tester.tap(filters);
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'expanded short-height layout',
    );
    final apply = find.widgetWithText(FilledButton, 'Aplicar filtros');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    final clear = find.widgetWithText(TextButton, 'Limpar filtros');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(api.queries.last.q, isNull);
    expect(api.queries.last.quizId, isNull);
    expect(api.queries.last.status, isNull);
    expect(api.queries.last.tag, isNull);

    await tester.ensureVisible(filters);
    await tester.tap(filters);
    await tester.pumpAndSettle();
    final pageRange = find.text('1-20 de 55');
    expect(pageRange, findsOneWidget);
    await tester.ensureVisible(pageRange);
    final pageRangeRect = tester.getRect(pageRange);
    expect(pageRangeRect.top, greaterThanOrEqualTo(0));
    expect(pageRangeRect.bottom, lessThanOrEqualTo(380));
    expect(find.byTooltip('Próxima'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard inset transition keeps active filter state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final screen = CreatedQuizHistoryScreen(api: _HistoryApi());
    Widget app(EdgeInsets insets) => _app(
      screen,
      locale: const Locale('pt'),
      textScale: 1.3,
      size: const Size(390, 600),
      viewInsets: insets,
    );

    await tester.pumpWidget(app(EdgeInsets.zero));
    await tester.pumpAndSettle();
    final filters = find.byKey(
      const ValueKey('created-history-advanced-filters'),
    );
    await tester.tap(filters);
    await tester.pumpAndSettle();
    final quizId = find.widgetWithText(TextField, 'ID do questionário');
    await tester.ensureVisible(quizId);
    await tester.showKeyboard(quizId);
    await tester.enterText(quizId, 'quiz-keep-focus');
    final quizIdEditable = find.descendant(
      of: quizId,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(quizIdEditable).focusNode.hasFocus,
      isTrue,
    );

    await tester.pumpWidget(app(const EdgeInsets.only(bottom: 220)));
    await tester.pumpAndSettle();
    final retainedQuizId = find.widgetWithText(TextField, 'ID do questionário');
    expect(retainedQuizId, findsOneWidget);
    expect(_fieldWithValue('quiz-keep-focus'), findsOneWidget);
    final retainedEditable = find.descendant(
      of: retainedQuizId,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(retainedEditable).focusNode.hasFocus,
      isTrue,
    );
    final apply = find.widgetWithText(FilledButton, 'Aplicar filtros');
    await tester.ensureVisible(apply);
    expect(apply, findsOneWidget);
    final clear = find.widgetWithText(TextButton, 'Limpar filtros');
    await tester.ensureVisible(clear);
    expect(clear, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(app(EdgeInsets.zero));
    await tester.pumpAndSettle();
    expect(find.text('ID do questionário'), findsOneWidget);
    expect(_fieldWithValue('quiz-keep-focus'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 844);
    final fullHeightScreen = CreatedQuizHistoryScreen(api: _HistoryApi());
    Widget fullHeightApp(EdgeInsets insets) => _app(
      fullHeightScreen,
      locale: const Locale('pt'),
      textScale: 1.3,
      size: const Size(390, 844),
      viewInsets: insets,
    );
    await tester.pumpWidget(fullHeightApp(EdgeInsets.zero));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('created-history-advanced-filters')),
    );
    await tester.pumpAndSettle();
    final fullHeightQuizId = find.widgetWithText(
      TextField,
      'ID do questionário',
    );
    await tester.ensureVisible(fullHeightQuizId);
    await tester.showKeyboard(fullHeightQuizId);
    await tester.enterText(fullHeightQuizId, 'quiz-844-focus');
    final fullHeightEditable = find.descendant(
      of: fullHeightQuizId,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(fullHeightEditable).focusNode.hasFocus,
      isTrue,
    );

    await tester.pumpWidget(fullHeightApp(const EdgeInsets.only(bottom: 300)));
    await tester.pumpAndSettle();
    final retainedFullHeightQuizId = find.widgetWithText(
      TextField,
      'ID do questionário',
    );
    expect(retainedFullHeightQuizId, findsOneWidget);
    expect(_fieldWithValue('quiz-844-focus'), findsOneWidget);
    final retainedFullHeightEditable = find.descendant(
      of: retainedFullHeightQuizId,
      matching: find.byType(EditableText),
    );
    expect(
      tester
          .widget<EditableText>(retainedFullHeightEditable)
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Aplicar filtros'),
    );
    await tester.ensureVisible(
      find.widgetWithText(TextButton, 'Limpar filtros'),
    );
    expect(tester.takeException(), isNull);
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
