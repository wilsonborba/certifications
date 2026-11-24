import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
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
  bool _reportAttached = false;

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
    if (request.method == 'GET' && path.endsWith('/reports/picker')) {
      if (request.url.queryParameters.isEmpty) {
        return _response({
          'items': [
            {
              'project': 'sample-project',
              'report': 'monthly-metrics',
              'title': 'Monthly metrics',
              'is_restricted': false,
            },
          ],
        }, 200);
      }
      if (request.url.queryParameters['project'] != 'sample-project' ||
          request.url.queryParameters['report'] != 'monthly-metrics') {
        throw StateError('Unexpected report picker query: ${request.url}');
      }
      return _response({
        'items': [
          {
            'project': 'sample-project',
            'report': 'monthly-metrics',
            'dataset': {
              'dataset_id': 'counts',
              'title': 'Monthly counts',
              'can_view': true,
              'visibility': 'public',
            },
          },
        ],
      }, 200);
    }
    if (request.method == 'POST' && path.endsWith('/studies/review-study/sources')) {
      final body = jsonDecode((request as http.Request).body);
      if (body is! Map ||
          body['kind'] != 'report' ||
          body['external_ref'] != 'sample-project/monthly-metrics/counts' ||
          body['is_restricted'] != false ||
          body.containsKey('fsm_ref')) {
        throw StateError('Unexpected report attachment body: $body');
      }
      _reportAttached = true;
      return _response({
        'id': 'sample-report-source',
        'filename': 'Monthly counts',
        'mime_type': 'text/plain',
        'size_bytes': 128,
        'sha256': 'fixture-report-sha256',
        'fsm_ref': '',
        'source_kind': 'report',
        'status': 'ready',
        'selection_kind': 'all',
        'selection_spec': '',
        'is_restricted': false,
        'external_ref': 'sample-project/monthly-metrics/counts',
      }, 201);
    }
    if (request.method == 'GET' && path.endsWith('/studies/review-study')) {
      return _response({
        'study': _study,
        'sources': _reportAttached
            ? [
                {
                  'id': 'sample-report-source',
                  'filename': 'Monthly counts',
                  'mime_type': 'text/plain',
                  'size_bytes': 128,
                  'sha256': 'fixture-report-sha256',
                  'source_kind': 'report',
                  'status': 'ready',
                  'selection_kind': 'all',
                  'selection_spec': '',
                  'is_restricted': false,
                  'external_ref': 'sample-project/monthly-metrics/counts',
                },
              ]
            : [],
        'quota': {
          'used_bytes': _reportAttached ? 1152 : 1024,
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

List<int> _samplePdf() => base64Decode(
  'JVBERi0xLjQKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9LaWRzIFszIDAgUiA2IDAgUl0gL0NvdW50IDIgPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCA1OTUgODQyXSAvUmVzb3VyY2VzIDw8IC9Gb250IDw8IC9GMSA0IDAgUiA+PiA+PiAvQ29udGVudHMgNSAwIFIgPj4KZW5kb2JqCjQgMCBvYmoKPDwgL1R5cGUgL0ZvbnQgL1N1YnR5cGUgL1R5cGUxIC9CYXNlRm9udCAvSGVsdmV0aWNhID4+CmVuZG9iago1IDAgb2JqCjw8IC9MZW5ndGggNjMgPj4Kc3RyZWFtCkJUIC9GMSAyMCBUZiAzNiA3ODAgVGQgKFN5bnRoZXRpYyBzdHVkeSBtYXRlcmlhbCwgcGFnZSAxKSBUaiBFVAplbmRzdHJlYW0KZW5kb2JqCjYgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCA1OTUgODQyXSAvUmVzb3VyY2VzIDw8IC9Gb250IDw8IC9GMSA0IDAgUiA+PiA+PiAvQ29udGVudHMgNyAwIFIgPj4KZW5kb2JqCjcgMCBvYmoKPDwgL0xlbmd0aCA2MyA+PgpzdHJlYW0KQlQgL0YxIDIwIFRmIDM2IDc4MCBUZCAoU3ludGhldGljIHN0dWR5IG1hdGVyaWFsLCBwYWdlIDIpIFRqIEVUCmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDgKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDA5IDAwMDAwIG4gCjAwMDAwMDAwNTggMDAwMDAgbiAKMDAwMDAwMDEyMSAwMDAwMCBuIAowMDAwMDAwMjQ3IDAwMDAwIG4gCjAwMDAwMDAzMTcgMDAwMDAgbiAKMDAwMDAwMDQzMCAwMDAwMCBuIAowMDAwMDAwNTU2IDAwMDAwIG4gCnRyYWlsZXIKPDwgL1NpemUgOCAvUm9vdCAxIDAgUiA+PgpzdGFydHhyZWYKNjY5CiUlRU9GCg==',
);

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
          'Study source preview\n\nUTF-16 offsets preserve emoji such as 😀.\nThe selected passage is validated and saved with the source.',
        ),
        name: 'sample-notes.txt',
        kind: 'txt',
        totalLines: 4,
        isWholeDocument: false,
        selectionKind: 'passages',
        selectionSpec: 'p1:0-25',
      ),
    )
    ..addFile(
      AttachedFile(
        bytes: _samplePdf(),
        name: 'sample-reading.pdf',
        kind: 'pdf',
        totalPages: 2,
        isWholeDocument: false,
        selectionKind: 'pages',
        selectionSpec: '1-2',
      ),
    )
    ..setExistingSources([
      StudySource.fromJson({
        'id': 'prepared-note-source',
        'filename': 'prepared-note.txt',
        'mime_type': 'text/plain',
        'size_bytes': 128,
        'sha256': 'fixture-sha256',
        'source_kind': 'upload',
        'status': 'ready',
        'selection_kind': 'passages',
        'selection_spec': 'p1:0-25',
      }),
    ]);
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
