import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/quiz_wizard_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Reports source card renders across locale, theme, and widths', (
    tester,
  ) async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode({'items': []}), 200),
    );
    addTearDown(client.close);
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    for (final locale in AppLocalizations.supportedLocales) {
      for (final mode in ThemeMode.values.where(
        (value) => value != ThemeMode.system,
      )) {
        for (final size in [const Size(390, 844), const Size(1300, 860)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: mode,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                FallbackMaterialLocalizationsDelegate(),
                DefaultWidgetsLocalizations.delegate,
              ],
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Step2SourceView(
                    wizardData: QuizWizardData(),
                    isDesktop: size.width > 768,
                    onPrepareSources: () async => 'study-visual-fixture',
                    studyApi: service,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(AppLocalizations(locale).text('reportsSourceLabel')),
            findsOneWidget,
          );
          final firstException = tester.takeException();
          if (firstException != null) {
            expect(
              firstException.toString(),
              contains(
                'locale, ${locale.languageCode}, is not supported by all',
              ),
              reason: '${locale.languageCode}/$mode/$size',
            );
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${locale.languageCode}/$mode/$size',
          );
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('study source step attaches one readable Reports dataset', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET' &&
          request.url.path.endsWith('/reports/picker')) {
        if (request.url.queryParameters.isEmpty) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'project': 'project-1',
                  'report': 'report-1',
                  'title': 'Monthly report',
                  'is_restricted': false,
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'items': [
              {
                'project': 'project-1',
                'report': 'report-1',
                'dataset': {
                  'dataset_id': 'dataset-1',
                  'title': 'Monthly counts',
                  'can_view': true,
                  'visibility': 'public',
                },
              },
            ],
          }),
          200,
        );
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith('/studies/study-1/sources')) {
        return http.Response(
          jsonEncode({
            'id': 'report-source-1',
            'filename': 'Monthly counts',
            'mime_type': 'text/plain',
            'size_bytes': 42,
            'sha256': 'sourcehash',
            'fsm_ref': '',
            'source_kind': 'report',
            'status': 'ready',
            'selection_kind': 'all',
            'selection_spec': '',
            'is_restricted': false,
            'external_ref': 'project-1/report-1/dataset-1',
          }),
          201,
        );
      }
      if (request.method == 'GET' &&
          request.url.path.endsWith('/studies/study-1')) {
        return http.Response(
          jsonEncode({
            'study': {
              'id': 'study-1',
              'title': 'Source fixture',
              'status': 'draft',
            },
            'sources': [
              {
                'id': 'report-source-1',
                'filename': 'Monthly counts',
                'mime_type': 'text/plain',
                'size_bytes': 42,
                'sha256': 'sourcehash',
                'source_kind': 'report',
                'status': 'ready',
                'selection_kind': 'all',
                'selection_spec': '',
                'is_restricted': false,
                'external_ref': 'project-1/report-1/dataset-1',
              },
            ],
            'quota': {
              'used_bytes': 42,
              'reserved_bytes': 0,
              'max_file_bytes': 1000,
              'max_study_bytes': 2000,
              'max_account_bytes': 3000,
            },
          }),
          200,
        );
      }
      return http.Response('unexpected request', 404);
    });
    addTearDown(client.close);
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    final wizardData = QuizWizardData();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: Step2SourceView(
              wizardData: wizardData,
              isDesktop: false,
              onPrepareSources: () async => 'study-1',
              studyApi: service,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly report · project-1/report-1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly counts · dataset-1').last);
    await tester.pumpAndSettle();
    final addButton = find.text('Add dataset');
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(requests.map((request) => request.method), [
      'GET',
      'GET',
      'POST',
      'GET',
    ]);
    expect(requests[1].url.queryParameters, {
      'project': 'project-1',
      'report': 'report-1',
    });
    expect(jsonDecode(requests[2].body), {
      'kind': 'report',
      'filename': 'Monthly counts',
      'external_ref': 'project-1/report-1/dataset-1',
      'is_restricted': false,
    });
    expect(wizardData.existingSources.single.sourceKind, 'report');
    expect(wizardData.existingSources.single.selectionKind, 'all');
    expect(wizardData.accountUsedBytes, 42);
    expect(tester.takeException(), isNull);
  });
}
