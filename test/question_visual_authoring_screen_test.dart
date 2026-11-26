import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:certifications/domain/models/authoring.dart';
import 'package:certifications/domain/models/public_question_catalog.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/public_question_api_service.dart';
import 'package:certifications/domain/services/question_authoring_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/question_authoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reports_view/reports_view.dart' as reports;

AuthoringQuestion _question({List<QuestionVisual> visuals = const []}) =>
    AuthoringQuestion.fromJson({
      'id': 'question-1',
      'version_id': 'question-version-7',
      'version_num': 7,
      'language': 'en',
      'origin': 'supplied_by_creator',
      'prompt': 'Which month has the highest count?',
      'alternatives': [
        {'id': 'a', 'text': 'January'},
        {'id': 'b', 'text': 'February'},
      ],
      'correct_id': 'b',
      'explanation': 'The report gives the count.',
      'citation_ref': '',
      'visuals': [
        for (final visual in visuals)
          {
            'id': visual.id,
            'mime_type': visual.mimeType,
            'created_at': visual.createdAt,
          },
      ],
    });

class _FakeAuthoring extends QuestionAuthoringService {
  _FakeAuthoring()
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

  final List<AuthoringQuestion> questions = [_question()];
  int prepareCalls = 0;
  int uploadCalls = 0;
  bool loseFirstUploadResponse = false;
  Map<String, Object?>? preparedArguments;
  List<int>? uploadedPng;
  final List<String> uploadedJobIds = [];
  final List<List<int>> uploadedPngAttempts = [];

  @override
  Future<List<AuthoringQuestion>> list(String studyId) async => questions;

  @override
  Future<PreparedQuestionVisualJob> prepareVisualJob({
    required String studyId,
    required AuthoringQuestion question,
    required String templateId,
    required int templateVersion,
    required Map<String, List<String>> mapping,
    required Map<String, dynamic> config,
    required List<Map<String, dynamic>> rows,
  }) async {
    prepareCalls++;
    preparedArguments = {
      'studyId': studyId,
      'questionId': question.id,
      'questionVersionId': question.versionId,
      'templateId': templateId,
      'templateVersion': templateVersion,
      'mapping': mapping,
      'config': config,
      'rows': rows,
    };
    return const PreparedQuestionVisualJob(
      questionId: 'question-1',
      questionVersionId: 'question-version-7',
      jobId: 'render-job-9',
      templateId: 'bar-template',
      templateVersion: 3,
      width: 800,
      height: 480,
      scale: 2,
      expiresAt: 1760000900,
    );
  }

  @override
  Future<QuestionVisual> uploadVisual({
    required String studyId,
    required AuthoringQuestion question,
    required PreparedQuestionVisualJob job,
    required List<int> pngBytes,
  }) async {
    uploadCalls++;
    uploadedPng = List<int>.from(pngBytes);
    uploadedJobIds.add(job.jobId);
    uploadedPngAttempts.add(List<int>.from(pngBytes));
    final visual = const QuestionVisual(
      id: 'vis_render-job-9',
      mimeType: 'image/png',
      createdAt: 1760000000,
    );
    if (!questions.single.visuals.any((existing) => existing.id == visual.id)) {
      questions[0] = _question(visuals: [visual]);
    }
    if (loseFirstUploadResponse) {
      loseFirstUploadResponse = false;
      throw http.ClientException('response lost after durable save');
    }
    return visual;
  }
}

class _FakeStudyApi extends StudyApiService {
  _FakeStudyApi({this.totalRows = 2})
    : super(
        adapter: ApiAdapter(
          client: MockClient((_) async => http.Response('{}', 200)),
          csrfTokenProvider: () => null,
        ),
      );

  final int totalRows;

  static const report = ReportPickerItem(
    project: 'project-a',
    report: 'report-a',
    title: 'Monthly report',
    isRestricted: false,
  );
  static const dataset = ReportDatasetPickerItem(
    project: 'project-a',
    report: 'report-a',
    datasetId: 'counts',
    title: 'Monthly counts',
    canView: true,
    visibility: 'private',
  );

  @override
  Future<List<ReportPickerItem>> listReports() async => const [report];

  @override
  Future<List<ReportDatasetPickerItem>> listReportDatasets(
    ReportPickerItem selected,
  ) async => const [dataset];

  @override
  Future<reports.DatasetPage> getReportDatasetPage(
    ReportDatasetPickerItem selected, {
    String language = 'en',
  }) async => reports.DatasetPage.fromJson({
    'dataset_id': 'counts',
    'title': 'Monthly counts',
    'description': '',
    'fields': [
      {
        'name': 'month',
        'label': 'Month',
        'type': 'string',
        'role': 'dimension',
      },
      {'name': 'count', 'label': 'Count', 'type': 'integer', 'role': 'measure'},
    ],
    'filters': [],
    'data_tier': 'real',
    'visibility': 'private',
    'can_view': true,
    'rows': [
      {'month': 'Jan', 'count': 2},
      {'month': 'Feb', 'count': 5},
    ],
    'offset': 0,
    'limit': 500,
    'total_rows': totalRows,
    'visual': {
      'template': 'bar-template',
      'version': 3,
      'mapping': {
        'x': ['month'],
        'y': ['count'],
      },
      'options': {'title': 'Monthly counts'},
    },
  });

  @override
  Future<List<reports.VisualTemplate>> listReportVisualTemplates({
    String language = 'en',
  }) async => [
    reports.VisualTemplate.fromJson({
      'template_id': 'bar-template',
      'version': 3,
      'kind': 'chart',
      'visual': 'bar',
      'title': 'Monthly counts',
      'slots': [
        {
          'slot_name': 'x',
          'role': 'dimension',
          'is_required': true,
          'min_count': 1,
          'max_count': 1,
          'accepted_types': ['string'],
        },
        {
          'slot_name': 'y',
          'role': 'measure',
          'is_required': true,
          'min_count': 1,
          'max_count': 1,
          'accepted_types': ['integer'],
        },
      ],
      'options': [],
    }),
  ];
}

class _FakePublicQuestions extends PublicQuestionApiService {
  _FakePublicQuestions()
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
    int limit = 20,
    int offset = 0,
  }) async => PublicQuestionCatalogPage(
    items: const [],
    limit: limit,
    offset: offset,
    hasMore: false,
  );
}

void main() {
  testWidgets('renders and durably attaches the selected Reports visual', (
    tester,
  ) async {
    final authoring = _FakeAuthoring();
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        home: QuestionAuthoringScreen(
          studyId: 'study-1',
          studyTitle: 'Visual study',
          onPublished: () {},
          authoringService: authoring,
          publicQuestionService: _FakePublicQuestions(),
          studyApiService: _FakeStudyApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Reports visual'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ReportPickerItem>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly report · project-a/report-a').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<ReportDatasetPickerItem>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly counts · counts').last);
    await tester.pumpAndSettle();

    expect(find.byType(reports.ChartFrame), findsOneWidget);
    expect(find.text('Save visual to question'), findsOneWidget);
    await tester.tap(find.text('Save visual to question'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(authoring.prepareCalls, 1);
    expect(authoring.uploadCalls, 1);
    expect(authoring.preparedArguments, {
      'studyId': 'study-1',
      'questionId': 'question-1',
      'questionVersionId': 'question-version-7',
      'templateId': 'bar-template',
      'templateVersion': 3,
      'mapping': {
        'x': ['month'],
        'y': ['count'],
      },
      'config': {'title': 'Monthly counts'},
      'rows': [
        {'month': 'Jan', 'count': 2},
        {'month': 'Feb', 'count': 5},
      ],
    });
    expect(authoring.uploadedPng, isNotNull);
    expect(authoring.uploadedPng!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(find.text('Saved visuals: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not save a chart from a truncated Reports page', (
    tester,
  ) async {
    final authoring = _FakeAuthoring();
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        home: QuestionAuthoringScreen(
          studyId: 'study-1',
          studyTitle: 'Visual study',
          onPublished: () {},
          authoringService: authoring,
          publicQuestionService: _FakePublicQuestions(),
          studyApiService: _FakeStudyApi(totalRows: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Reports visual'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ReportPickerItem>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly report · project-a/report-a').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<ReportDatasetPickerItem>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly counts · counts').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This Reports dataset has more rows than a question visual can save. Choose a smaller dataset.',
      ),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save visual to question'),
    );
    expect(save.onPressed, isNull);
    expect(authoring.prepareCalls, 0);
    expect(authoring.uploadCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retries an uncertain PNG upload with the same job and bytes', (
    tester,
  ) async {
    final authoring = _FakeAuthoring()..loseFirstUploadResponse = true;
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        home: QuestionAuthoringScreen(
          studyId: 'study-1',
          studyTitle: 'Visual study',
          onPublished: () {},
          authoringService: authoring,
          publicQuestionService: _FakePublicQuestions(),
          studyApiService: _FakeStudyApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Reports visual'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ReportPickerItem>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly report · project-a/report-a').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<ReportDatasetPickerItem>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly counts · counts').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save visual to question'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save this visual. Nothing was confirmed as saved.'),
      findsOneWidget,
    );
    expect(authoring.prepareCalls, 1);
    expect(authoring.uploadCalls, 1);
    expect(authoring.questions.single.visuals, hasLength(1));

    await tester.tap(find.text('Save visual to question'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(authoring.prepareCalls, 1);
    expect(authoring.uploadCalls, 2);
    expect(authoring.uploadedJobIds, ['render-job-9', 'render-job-9']);
    expect(authoring.uploadedPngAttempts, hasLength(2));
    expect(authoring.uploadedPngAttempts[1], authoring.uploadedPngAttempts[0]);
    expect(authoring.questions.single.visuals, hasLength(1));
    expect(find.text('Saved visuals: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
