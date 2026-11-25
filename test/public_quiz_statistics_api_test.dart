import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/public_quiz_statistics.dart';
import 'package:certifications/domain/services/public_quiz_statistics_api_service.dart';
import 'package:certifications/presentation/widgets/attempt_review_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('empty public statistics preserve unavailable values', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['accept-language'], 'en');
      expect(
        request.url.path,
        '/apps/certifications/v1/quizzes/quiz-1/statistics',
      );
      return http.Response(
        jsonEncode({
          'quiz_id': 'quiz-1',
          'completed_attempt_count': 0,
          'distinct_participants': 0,
          'average_score_pct': null,
          'average_score_denominator': 0,
          'typical_duration_sec': null,
          'duration_denominator': 0,
          'basis': 'all_completed_attempts',
          'score_distribution_denominator': 0,
          'score_distribution': [],
          'question_provenance': {},
          'score_distribution_report_view': {
            'descriptor': {
              'dataset_id': 'cert:quiz:quiz-1:score-distribution',
              'title': 'Quiz score distribution',
              'description': 'Completed attempt scores by percentage band',
              'equation': null,
              'fields': [
                {'name': 'score_band', 'type': 'string', 'role': 'dimension'},
                {'name': 'attempt_count', 'type': 'integer', 'role': 'measure'},
              ],
              'filters': [],
              'data_tier': 'live',
              'can_view': true,
              'visibility': 'public',
              'meta': {'language': 'en'},
            },
            'rows': [],
            'offset': 0,
            'limit': 3,
            'total_rows': 0,
            'template_definition': _scoreDistributionTemplate('en'),
            'visual': {
              'template': 'cert-score-distribution',
              'version': 1,
              'mapping': {
                'bucket': ['score_band'],
                'attempts': ['attempt_count'],
              },
              'options': {},
            },
          },
        }),
        200,
      );
    });
    final service = PublicQuizStatisticsApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final stats = await service.getForQuiz('quiz-1');

    expect(stats.completedAttemptCount, 0);
    expect(stats.distinctParticipants, 0);
    expect(stats.averageScorePct, isNull);
    expect(stats.typicalDurationSec, isNull);
    expect(stats.hasCompletedAttempts, isFalse);
    expect(stats.basis, 'all_completed_attempts');
    expect(stats.durationDenominator, 0);
    expect(stats.scoreDistributionReportView['total_rows'], 0);
    expect(
      stats.scoreDistributionView?.template.title,
      'Quiz score distribution',
    );
    expect(stats.scoreDistributionView?.page.rows, isEmpty);
  });

  test('public statistics retain the server denominator basis', () async {
    final client = MockClient((request) async {
      expect(request.headers['accept-language'], 'pt-BR');
      return http.Response(
        jsonEncode({
          'quiz_id': 'quiz-2',
          'completed_attempt_count': 3,
          'distinct_participants': 2,
          'average_score_pct': 66.6667,
          'average_score_denominator': 3,
          'typical_duration_sec': 120,
          'duration_denominator': 3,
          'basis': 'all_completed_attempts',
          'score_distribution_denominator': 3,
          'score_distribution': [
            {'score_band': '0-49%', 'attempt_count': 1},
            {'score_band': '50-79%', 'attempt_count': 1},
            {'score_band': '80-100%', 'attempt_count': 1},
          ],
          'question_provenance': {
            'combined': {'attempt_count': 0},
          },
          'score_distribution_report_view': {
            'descriptor': {
              'dataset_id': 'cert:quiz:quiz-2:score-distribution',
              'title': 'Quiz score distribution',
              'fields': [
                {'name': 'score_band', 'type': 'string', 'role': 'dimension'},
                {'name': 'attempt_count', 'type': 'integer', 'role': 'measure'},
              ],
            },
            'rows': [
              {'score_band': '0-49%', 'attempt_count': 1},
              {'score_band': '50-79%', 'attempt_count': 1},
              {'score_band': '80-100%', 'attempt_count': 1},
            ],
            'offset': 0,
            'limit': 3,
            'total_rows': 3,
            'template_definition': _scoreDistributionTemplate('pt'),
            'visual': {
              'template': 'cert-score-distribution',
              'version': 1,
              'mapping': {
                'bucket': ['score_band'],
                'attempts': ['attempt_count'],
              },
              'options': {},
            },
          },
        }),
        200,
      );
    });
    final service = PublicQuizStatisticsApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );

    final stats = await service.getForQuiz('quiz-2', language: 'pt');

    expect(stats.hasCompletedAttempts, isTrue);
    expect(stats.completedAttemptCount, 3);
    expect(stats.distinctParticipants, 2);
    expect(stats.averageScorePct, 66.6667);
    expect(stats.scoreDistributionDenominator, 3);
    expect(stats.scoreDistribution.map((band) => band.count), [1, 1, 1]);
    expect(stats.basis, 'all_completed_attempts');
    expect(stats.scoreDistributionView?.binding.mapping['attempts'], [
      'attempt_count',
    ]);
    final rawView = stats.scoreDistributionReportView;
    final pageRows = rawView['rows'] as List<dynamic>;
    final alteredRows = [
      Map<String, dynamic>.from(pageRows.first as Map)..['attempt_count'] = 2,
      ...pageRows.skip(1),
    ];
    expect(
      ScoreDistributionReportView.tryParse(
        {...rawView, 'rows': alteredRows},
        stats.scoreDistribution,
        stats.scoreDistributionDenominator,
      ),
      isNull,
      reason: 'the chart must fail closed when its rows disagree with the DTO',
    );
    final fractionalRows = [
      Map<String, dynamic>.from(pageRows.first as Map)..['attempt_count'] = 1.9,
      ...pageRows.skip(1),
    ];
    expect(
      ScoreDistributionReportView.tryParse(
        {...rawView, 'rows': fractionalRows},
        stats.scoreDistribution,
        stats.scoreDistributionDenominator,
      ),
      isNull,
      reason: 'fractional counts must not be truncated by the chart binding',
    );
    final negativeRows = [
      Map<String, dynamic>.from(pageRows.first as Map)..['attempt_count'] = -1,
      ...pageRows.skip(1),
    ];
    expect(
      ScoreDistributionReportView.tryParse(
        {...rawView, 'rows': negativeRows},
        stats.scoreDistribution,
        stats.scoreDistributionDenominator,
      ),
      isNull,
    );
    final wrongLanguageLabelRows = [
      Map<String, dynamic>.from(pageRows.first as Map)
        ..['score_band'] = '80–100%',
      ...pageRows.skip(1),
    ];
    expect(
      ScoreDistributionReportView.tryParse(
        {...rawView, 'rows': wrongLanguageLabelRows},
        stats.scoreDistribution,
        stats.scoreDistributionDenominator,
      ),
      isNull,
      reason: 'localized report rows must match the authoritative DTO labels',
    );
    final alteredBinding = Map<String, dynamic>.from(rawView['visual'] as Map)
      ..['mapping'] = {
        'bucket': ['missing_field'],
        'attempts': ['attempt_count'],
      };
    expect(
      ScoreDistributionReportView.tryParse(
        {...rawView, 'visual': alteredBinding},
        stats.scoreDistribution,
        stats.scoreDistributionDenominator,
      ),
      isNull,
      reason:
          'the chart must fail closed when the binding names an unknown field',
    );
    final alteredTemplate = Map<String, dynamic>.from(
      rawView['template_definition'] as Map,
    )..['title'] = 'Distribuição localizada';
    final localizedView = ScoreDistributionReportView.tryParse(
      {...rawView, 'template_definition': alteredTemplate},
      stats.scoreDistribution,
      stats.scoreDistributionDenominator,
    );
    expect(localizedView?.template.title, 'Distribuição localizada');
    expect(
      () => ScoreDistributionBand.fromJson({
        'score_band': '80-100%',
        'attempt_count': double.nan,
      }),
      throwsFormatException,
    );
  });

  testWidgets('statistics refetch when saved interface language loads', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final languages = <String?>[];
    final client = MockClient((request) async {
      languages.add(request.headers['accept-language']);
      return http.Response(
        jsonEncode({
          'quiz_id': 'quiz-3',
          'completed_attempt_count': 1,
          'distinct_participants': 1,
          'average_score_pct': 80,
          'average_score_denominator': 1,
          'typical_duration_sec': 60,
          'duration_denominator': 1,
          'basis': 'all_completed_attempts',
          'score_distribution_denominator': 1,
          'score_distribution': [
            {'score_band': '80-100%', 'attempt_count': 1},
          ],
          'question_provenance': {},
          'score_distribution_report_view': {
            'descriptor': {
              'dataset_id': 'cert:quiz:quiz-3:score-distribution',
              'fields': [
                {'name': 'score_band', 'type': 'string', 'role': 'dimension'},
                {'name': 'attempt_count', 'type': 'integer', 'role': 'measure'},
              ],
            },
            'rows': [
              {'score_band': '80-100%', 'attempt_count': 1},
            ],
            'offset': 0,
            'limit': 3,
            'total_rows': 1,
            'template_definition': _scoreDistributionTemplate('en'),
            'visual': {
              'template': 'cert-score-distribution',
              'version': 1,
              'mapping': {
                'bucket': ['score_band'],
                'attempts': ['attempt_count'],
              },
              'options': {},
            },
          },
        }),
        200,
      );
    });
    final service = PublicQuizStatisticsApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    var locale = const Locale('en');

    Widget app() => MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: child!,
      ),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      home: PublicQuizStatisticsScreen(quizId: 'quiz-3', api: service),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(languages, ['en']);

    locale = const Locale('th');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(languages, ['en', 'th']);
    expect(find.text('Quiz score distribution'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
}

Map<String, dynamic> _scoreDistributionTemplate(String language) => {
  'template_id': 'cert-score-distribution',
  'version': 1,
  'kind': 'chart',
  'visual': 'bar',
  'title': language == 'pt'
      ? 'Distribuição de pontuações'
      : 'Quiz score distribution',
  'slots': [
    {
      'slot_name': 'bucket',
      'role': 'dimension',
      'is_required': true,
      'min_count': 1,
      'max_count': 1,
      'accepted_types': ['string'],
    },
    {
      'slot_name': 'attempts',
      'role': 'measure',
      'is_required': true,
      'min_count': 1,
      'max_count': 2,
      'accepted_types': ['integer', 'float'],
    },
  ],
  'options': [],
};
