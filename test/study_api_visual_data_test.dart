import 'dart:convert';

import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'loads an authorized Reports page and its immutable template version',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith(
          '/projects/project-a/reports/report-a/datasets/counts',
        )) {
          return http.Response(
            jsonEncode({
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
                {
                  'name': 'count',
                  'label': 'Count',
                  'type': 'integer',
                  'role': 'measure',
                },
              ],
              'filters': [],
              'data_tier': 'real',
              'visibility': 'private',
              'can_view': true,
              'meta': {'tier': 'real', 'freshness_mode': 'live'},
              'rows': [
                {'month': 'Jan', 'count': 3},
              ],
              'offset': 0,
              'limit': 500,
              'total_rows': 1,
              'visual': {
                'template': 'bar-v1',
                'version': 3,
                'mapping': {
                  'x': ['month'],
                  'y': ['count'],
                },
                'options': {'title': 'Monthly counts'},
              },
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/templates')) {
          return http.Response(
            jsonEncode({
              'templates': [
                {
                  'template_id': 'bar-v1',
                  'version': 3,
                  'kind': 'chart',
                  'visual': 'bar',
                  'title': 'Column chart',
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
                },
              ],
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
      const dataset = ReportDatasetPickerItem(
        project: 'project-a',
        report: 'report-a',
        datasetId: 'counts',
        title: 'Monthly counts',
        canView: true,
        visibility: 'private',
      );

      final page = await service.getReportDatasetPage(
        dataset,
        language: 'pt-BR',
      );
      final templates = await service.listReportVisualTemplates(
        language: 'pt-BR',
      );

      expect(requests[0].method, 'GET');
      expect(
        requests[0].url.path,
        endsWith(
          '/apps/reports/v1/projects/project-a/reports/report-a/datasets/counts',
        ),
      );
      expect(requests[0].url.queryParameters, {
        'limit': '1000',
        'offset': '0',
        'lang': 'pt-BR',
      });
      expect(page.rows, [
        {'month': 'Jan', 'count': 3},
      ]);
      expect(page.visual?.template, 'bar-v1');
      expect(page.visual?.version, 3);
      expect(templates.single.templateId, 'bar-v1');
      expect(templates.single.version, 3);
      expect(requests[1].url.path, endsWith('/apps/reports/v1/templates'));
      expect(requests[1].url.queryParameters, {'lang': 'pt-BR'});
    },
  );

  test('does not request data for a dataset marked unreadable', () async {
    final client = MockClient((request) async {
      fail('No request should be made for an unreadable descriptor');
    });
    addTearDown(client.close);
    final service = StudyApiService(
      adapter: ApiAdapter(client: client, csrfTokenProvider: () => null),
    );
    expect(
      () => service.getReportDatasetPage(
        const ReportDatasetPickerItem(
          project: 'project-a',
          report: 'report-a',
          datasetId: 'counts',
          title: 'Monthly counts',
          canView: false,
          visibility: 'restricted',
        ),
      ),
      throwsA(isA<StudyApiException>()),
    );
  });
}
