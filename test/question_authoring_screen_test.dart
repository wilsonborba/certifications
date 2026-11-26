import 'dart:async';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/models/authoring.dart';
import 'package:certifications/domain/models/public_question_catalog.dart';
import 'package:certifications/domain/services/public_question_api_service.dart';
import 'package:certifications/domain/services/question_authoring_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/question_authoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AuthoringQuestion _question() => AuthoringQuestion.fromJson({
  'id': 'q1',
  'version_id': 'qv1',
  'version_num': 1,
  'language': 'en',
  'origin': 'generated_with_cortex',
  'prompt': 'Which option is correct?',
  'alternatives': [
    {'id': 'a', 'text': 'Correct option'},
    {'id': 'b', 'text': 'Other option'},
  ],
  'correct_id': 'a',
  'explanation': 'The first option is correct.',
  'citation_ref': 'p. 1',
  'visuals': [],
});

class _FakeQuestionAuthoringService extends QuestionAuthoringService {
  _FakeQuestionAuthoringService()
    : super(
        client: CertificationsApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
          request:
              ({
                required method,
                required url,
                headers,
                body,
                queryParams,
              }) async => http.Response('{}', 200),
        ),
      );

  int confirms = 0;
  int publishes = 0;
  List<AuthoringAlternative>? updatedAlternatives;
  String? updatedCorrectId;
  String? updatedExplanation;
  Completer<CsvImportResult>? previewCompleter;
  String? previewCsvText;
  String? confirmedCsvText;
  List<AuthoringQuestion> questions = [_question()];
  CsvImportResult preview = CsvImportResult.fromJson({
    'preview_only': true,
    'imported_count': 0,
    'valid_rows': [
      {
        'row_number': 2,
        'language': 'en',
        'prompt': 'Valid row',
        'correct_id': 'a',
      },
    ],
    'invalid_rows': [
      {'row_number': 3, 'error': 'invalid_prompt'},
    ],
    'questions': [],
  });

  @override
  Future<List<AuthoringQuestion>> list(String studyId) async => questions;

  @override
  Future<AuthoringQuestion> create({
    required String studyId,
    required String language,
    required String prompt,
    required List<AuthoringAlternative> alternatives,
    required String correctId,
    required String explanation,
    String citationRef = '',
  }) async => _question();

  @override
  Future<AuthoringQuestion> update({
    required String studyId,
    required AuthoringQuestion question,
    required String language,
    required String prompt,
    required List<AuthoringAlternative> alternatives,
    required String correctId,
    required String explanation,
    required String citationRef,
  }) async {
    updatedAlternatives = alternatives;
    updatedCorrectId = correctId;
    updatedExplanation = explanation;
    return _question();
  }

  @override
  Future<CsvImportResult> previewCsv({
    required String studyId,
    required String csvText,
  }) async {
    previewCsvText = csvText;
    return previewCompleter?.future ?? preview;
  }

  @override
  Future<CsvImportResult> confirmCsv({
    required String studyId,
    required String csvText,
  }) async {
    confirms++;
    confirmedCsvText = csvText;
    return CsvImportResult.fromJson({
      'preview_only': false,
      'imported_count': 1,
      'valid_rows': [],
      'invalid_rows': [],
      'questions': [_question().toJsonForTest()],
    });
  }

  @override
  Future<PublishedQuiz> publish({
    required String studyId,
    required String title,
    required List<String> tags,
  }) async {
    publishes++;
    return PublishedQuiz.fromJson({
      'id': 'quiz1',
      'title': title,
      'question_count': 1,
    });
  }
}

extension on AuthoringQuestion {
  Map<String, dynamic> toJsonForTest() => {
    'id': id,
    'version_id': versionId,
    'version_num': versionNumber,
    'language': language,
    'origin': origin,
    'prompt': prompt,
    'alternatives': alternatives.map((item) => item.toJson()).toList(),
    'correct_id': correctId,
    'explanation': explanation,
    'citation_ref': citationRef,
    'visuals': [],
  };
}

class _FakePublicQuestionService extends PublicQuestionApiService {
  _FakePublicQuestionService()
    : super(
        client: CertificationsApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
          request:
              ({
                required method,
                required url,
                headers,
                body,
                queryParams,
              }) async => http.Response('{}', 200),
        ),
      );

  @override
  Future<PublicQuestionCatalogPage> search({
    String? query,
    String? language,
    String? origin,
    required int limit,
    required int offset,
  }) async => const PublicQuestionCatalogPage(
    items: [],
    limit: 20,
    offset: 0,
    hasMore: false,
  );

  @override
  Future<PublicQuestionReuseResult> reuseSelected({
    required String studyId,
    required List<String> questionVersionIds,
  }) async => const PublicQuestionReuseResult(
    quizId: 'quiz1',
    quizVersionId: 'version1',
    addedCount: 0,
    alreadyPresentCount: 0,
    totalQuestionCount: 1,
  );
}

Widget _app({required Widget home}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('review shows correct choice and explanation before publish', (
    tester,
  ) async {
    final service = _FakeQuestionAuthoringService();
    await tester.pumpWidget(
      _app(
        home: QuestionAuthoringScreen(
          studyId: 'study1',
          studyTitle: 'Study title',
          onPublished: () {},
          authoringService: service,
          publicQuestionService: _FakePublicQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Which option is correct?'), findsOneWidget);
    expect(find.text('A. Correct option'), findsOneWidget);
    expect(find.text('The first option is correct.'), findsOneWidget);
  });

  testWidgets('editing a question preserves all existing alternative IDs', (
    tester,
  ) async {
    final service = _FakeQuestionAuthoringService();
    final alternatives = [
      {'id': 'answer1', 'text': 'First'},
      {'id': 'answer2', 'text': 'Second'},
      {'id': 'answer3', 'text': 'Third'},
      {'id': 'answer4', 'text': 'Fourth'},
      {'id': 'answer5', 'text': 'Fifth'},
    ];
    service.questions = [
      AuthoringQuestion.fromJson({
        'id': 'q-five',
        'version_id': 'qv-five',
        'version_num': 1,
        'language': 'en',
        'origin': 'supplied_by_creator',
        'prompt': 'Five choices?',
        'alternatives': alternatives,
        'correct_id': 'answer5',
        'explanation': 'Original explanation',
        'citation_ref': '',
        'visuals': [],
      }),
    ];
    await tester.pumpWidget(
      _app(
        home: QuestionAuthoringScreen(
          studyId: 'study1',
          studyTitle: 'Study title',
          onPublished: () {},
          authoringService: service,
          publicQuestionService: _FakePublicQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit question'));
    await tester.pumpAndSettle();
    // Prompt, five preserved alternatives, explanation, and supporting source.
    expect(find.byType(TextField), findsNWidgets(8));
    expect(find.text('ANSWER5'), findsOneWidget);

    final explanation = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Explanation',
    );
    await tester.enterText(explanation, 'Revised explanation');
    await tester.tap(find.text('Save question'));
    await tester.pumpAndSettle();

    expect(
      service.updatedAlternatives
          ?.map((alternative) => (alternative.id, alternative.text))
          .toList(),
      [
        ('answer1', 'First'),
        ('answer2', 'Second'),
        ('answer3', 'Third'),
        ('answer4', 'Fourth'),
        ('answer5', 'Fifth'),
      ],
    );
    expect(service.updatedCorrectId, 'answer5');
    expect(service.updatedExplanation, 'Revised explanation');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing CSV during preview discards the stale result', (
    tester,
  ) async {
    final service = _FakeQuestionAuthoringService()
      ..preview = CsvImportResult.fromJson({
        'preview_only': true,
        'imported_count': 0,
        'valid_rows': [
          {
            'row_number': 2,
            'language': 'en',
            'prompt': 'Valid row',
            'correct_id': 'a',
          },
        ],
        'invalid_rows': [],
        'questions': [],
      })
      ..previewCompleter = Completer<CsvImportResult>();
    await tester.pumpWidget(
      _app(
        home: QuestionAuthoringScreen(
          studyId: 'study1',
          studyTitle: 'Study title',
          onPublished: () {},
          authoringService: service,
          publicQuestionService: _FakePublicQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import CSV'));
    await tester.pumpAndSettle();
    final csvField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.style?.fontFamily == 'monospace',
    );
    expect(csvField, findsOneWidget);
    final previewText = tester.widget<TextField>(csvField).controller!.text;

    final previewButton = find.text('Preview');
    expect(previewButton, findsOneWidget);
    await tester.tap(previewButton);
    await tester.pump();
    expect(service.previewCsvText, previewText);
    await tester.enterText(
      csvField,
      '$previewText\n# edited after preview started',
    );
    service.previewCompleter!.complete(service.preview);
    await tester.pump();
    await tester.pump();

    expect(find.text('Valid rows: 1'), findsNothing);
    final confirmButton = find.widgetWithText(
      FilledButton,
      'Import valid rows',
    );
    expect(confirmButton, findsOneWidget);
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
    expect(service.confirms, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty public search shows no-results text, not a range', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        home: QuestionAuthoringScreen(
          studyId: 'study1',
          studyTitle: 'Study title',
          onPublished: () {},
          authoringService: _FakeQuestionAuthoringService(),
          publicQuestionService: _FakePublicQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final searchIcon = find.byIcon(Icons.search);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getRect(searchIcon).bottom, lessThanOrEqualTo(600));
    await tester.tap(searchIcon);
    await tester.pumpAndSettle();

    expect(find.text('No public questions found.'), findsOneWidget);
    expect(find.text('1–0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid CSV rows stay visible and block confirmation', (
    tester,
  ) async {
    final service = _FakeQuestionAuthoringService();
    await tester.pumpWidget(
      _app(
        home: QuestionAuthoringScreen(
          studyId: 'study1',
          studyTitle: 'Study title',
          onPublished: () {},
          authoringService: service,
          publicQuestionService: _FakePublicQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    expect(find.text('Valid rows: 1'), findsOneWidget);
    expect(find.text('Invalid rows: 1'), findsOneWidget);
    expect(find.text('Row 3 is invalid'), findsOneWidget);
    expect(service.confirms, 0);
  });

  testWidgets('publishing requires a separate final confirmation', (
    tester,
  ) async {
    final service = _FakeQuestionAuthoringService();
    var publishedCallback = false;
    await tester.pumpWidget(
      _app(
        home: QuestionAuthoringScreen(
          studyId: 'study1',
          studyTitle: 'Study title',
          onPublished: () => publishedCallback = true,
          authoringService: service,
          publicQuestionService: _FakePublicQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Publish quiz'),
      find.byType(Scrollable).first,
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish quiz'));
    await tester.pumpAndSettle();
    expect(find.textContaining('public and final'), findsOneWidget);
    expect(service.publishes, 0);

    await tester.tap(find.text('Publish now'));
    await tester.pumpAndSettle();
    expect(service.publishes, 1);
    expect(publishedCallback, isTrue);
  });
}
