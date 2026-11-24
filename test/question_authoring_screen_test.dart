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
  }) async => _question();

  @override
  Future<CsvImportResult> previewCsv({
    required String studyId,
    required String csvText,
  }) async => preview;

  @override
  Future<CsvImportResult> confirmCsv({
    required String studyId,
    required String csvText,
  }) async {
    confirms++;
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
