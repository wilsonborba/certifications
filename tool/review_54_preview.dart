import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _study = <String, dynamic>{
  'id': 'review-study',
  'title': 'Sample study',
  'description': '',
  'source_origin': 'manual',
  'status': 'draft',
  'quiz_id': 'review-quiz',
  'expires_at': null,
  'created_at': 1760000000,
  'updated_at': 1760000000,
};

class _FixtureClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    if (request.method == 'POST' && path.endsWith('/studies')) {
      final body = jsonDecode((request as http.Request).body);
      if (body is! Map || body['title'] != 'Sample study') {
        throw StateError('Unexpected study create body: $body');
      }
      return _response(_study, 201);
    }
    if (request.method == 'GET' && path.endsWith('/studies/review-study')) {
      return _response({
        'study': _study,
        'sources': [],
        'quota': {
          'used_bytes': 1024,
          'reserved_bytes': 0,
          'max_file_bytes': 5000000,
          'max_study_bytes': 15000000,
          'max_account_bytes': 25000000,
          'remaining_account_bytes': 24998976,
        },
      }, 200);
    }
    throw StateError(
      'Unexpected API request ${request.method} ${request.url.path}',
    );
  }
}

_FixtureClient _fixtureClient() => _FixtureClient();

http.StreamedResponse _response(Object body, int statusCode) {
  final response = http.Response(
    jsonEncode({'data': body}),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
  return http.StreamedResponse(
    Stream.value(response.bodyBytes),
    statusCode,
    headers: response.headers,
    request: http.Request('GET', Uri.parse('http://fixture.invalid')),
  );
}

void main() {
  final query = Uri.base.queryParameters;
  final locale = Locale(query['locale'] ?? 'en');
  final isDark = query['mode'] == 'dark';
  final draft = QuizWizardData()
    ..name = 'Sample study'
    ..currentStep = 1
    ..addFile(
      AttachedFile(
        bytes: utf8.encode(
          'Study source preview\n\nThis sample is shown from the live Certifications source screen.\nNarrow selection is not sent until its API contract is ready.',
        ),
        name: 'sample-notes.txt',
        kind: 'txt',
        totalLines: 4,
      ),
    );
  final service = StudyApiService(
    adapter: ApiAdapter(
      client: _fixtureClient(),
      csrfTokenProvider: () => null,
    ),
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      home: OnQuizWizardScreen(
        onGenerate: () {},
        initialStep: 1,
        initialName: 'Sample study',
        apiService: service,
        draft: draft,
      ),
    ),
  );
}
