import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('one injected client handles ordinary and streamed requests', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 201);
    });
    final api = CertificationsApiClient(
      client: client,
      baseUrl: 'https://api.example/apps/certifications/v1',
    );

    final ordinary = await api.createStudyQuestion('study-1', {
      'prompt': 'Question',
    });
    final streamed = await api.uploadStudySourceMultipart(
      'study-1',
      bytes: [83, 111, 117, 114, 99, 101, 32, 116, 101, 120, 116, 46, 10],
      filename: 'source.txt',
      mimeType: 'text/plain',
    );

    expect(ordinary.statusCode, 201);
    expect(streamed.statusCode, 201);
    expect(requests, hasLength(2));
    expect(
      requests[0].url.path,
      '/apps/certifications/v1/studies/study-1/questions',
    );
    expect(requests[0].headers['content-type'], 'application/json');
    expect(
      requests[1].url.path,
      '/apps/certifications/v1/studies/study-1/sources',
    );
    expect(
      requests[1].headers['content-type'],
      startsWith('multipart/form-data;'),
    );
    expect(requests[1].body, contains('name="file"; filename="source.txt"'));
    expect(requests[1].body, contains('content-type: text/plain'));
    expect(requests[1].body, contains('Source text.\n'));
  });

  test(
    'an injected request function and stream client both remain active',
    () async {
      var requestCalls = 0;
      final streamedRequests = <http.Request>[];
      final streamClient = MockClient((request) async {
        streamedRequests.add(request);
        return http.Response('{}', 202);
      });
      final api = CertificationsApiClient(
        client: streamClient,
        request:
            ({
              required method,
              required url,
              headers,
              body,
              queryParams,
            }) async {
              requestCalls++;
              expect(method, 'GET');
              expect(url.path, '/apps/certifications/v1/studies/study-1');
              return http.Response('{}', 200);
            },
        baseUrl: 'https://api.example/apps/certifications/v1',
      );

      final ordinary = await api.getStudy('study-1');
      final streamed = await api.uploadStudySourceMultipart(
        'study-1',
        bytes: [83, 111, 117, 114, 99, 101, 32, 116, 101, 120, 116, 46, 10],
        filename: 'source.txt',
        mimeType: 'text/plain',
      );

      expect(ordinary.statusCode, 200);
      expect(streamed.statusCode, 202);
      expect(requestCalls, 1);
      expect(streamedRequests, hasLength(1));
      expect(
        streamedRequests.single.url.path,
        '/apps/certifications/v1/studies/study-1/sources',
      );
    },
  );
}
