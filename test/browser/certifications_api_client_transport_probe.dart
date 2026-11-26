import 'dart:async';
import 'dart:convert';

import 'package:certifications/dal/remote/certifications_api_client.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void main() => runApp(const TransportProbeApp());

class TransportProbeApp extends StatefulWidget {
  const TransportProbeApp({super.key});

  @override
  State<TransportProbeApp> createState() => _TransportProbeAppState();
}

class _TransportProbeAppState extends State<TransportProbeApp> {
  String _result = 'RUNNING';

  @override
  void initState() {
    super.initState();
    unawaited(_probe());
  }

  Future<void> _probe() async {
    try {
      // The guarded local fixture sets the CSRF cookie on the app origin.
      // This synthetic session cookie is shared by the two loopback ports.
      web.document.cookie = 'sid=fixture-only; Path=/; SameSite=Lax';
      final apiOrigin = Uri.parse(
        web.window.location.href,
      ).queryParameters['api_origin'];
      if (apiOrigin == null || apiOrigin.isEmpty) {
        throw StateError('Missing browser fixture API origin');
      }
      final baseUrl = '$apiOrigin/apps/certifications/v1';
      final client = CertificationsApiClient(baseUrl: baseUrl);

      String ordinaryResult;
      try {
        final ordinary = await client.createStudyQuestion('study-1', {
          'language': 'en',
          'prompt': 'Credentialed browser transport probe',
          'alternatives': const [
            {'id': 'answer-1', 'text': 'First synthetic answer'},
            {'id': 'answer-2', 'text': 'Second synthetic answer'},
          ],
          'correct_id': 'answer-1',
          'explanation': 'Synthetic fixture explanation.',
          'citation_ref': '',
        });
        final question = jsonDecode(ordinary.body) as Map<String, dynamic>;
        final questionShapeIsValid =
            question['id'] == 'question-1' &&
            question['version_id'] == 'version-1' &&
            question['version_num'] == 1 &&
            question['language'] == 'en' &&
            question['origin'] == 'supplied_by_creator' &&
            question['source_scope'] == '' &&
            question['prompt'] == 'Credentialed browser transport probe' &&
            question['alternatives'] is List &&
            question['correct_id'] == 'answer-1' &&
            question['explanation'] == 'Synthetic fixture explanation.' &&
            question['citation_ref'] == '' &&
            question['visuals'] is List;
        ordinaryResult = '${ordinary.statusCode}; shape=$questionShapeIsValid';
      } catch (error) {
        ordinaryResult = 'error: $error';
      }

      String streamedResult;
      try {
        final streamed = await client.uploadStudySourceMultipart(
          'study-1',
          bytes: utf8.encode('Synthetic browser transport fixture.\n'),
          filename: 'fixture.txt',
          mimeType: 'text/plain',
        );
        final source = jsonDecode(streamed.body) as Map<String, dynamic>;
        final sourceShapeIsValid =
            source['id'] == 'source-1' &&
            source['filename'] == 'fixture.txt' &&
            source['mime_type'] == 'text/plain' &&
            source['size_bytes'] == 37 &&
            source['sha256'] == 'fixture-sha256' &&
            source['fsm_ref'] == 'certifications/fixture/source-1' &&
            source['source_kind'] == 'upload' &&
            source['status'] == 'ready' &&
            source['selection_kind'] == 'all' &&
            source['selection_spec'] == '' &&
            source['is_restricted'] == false &&
            source['external_ref'] == '' &&
            source['created_at'] == 1 &&
            source['updated_at'] == 1;
        streamedResult = '${streamed.statusCode}; shape=$sourceShapeIsValid';
      } catch (error) {
        streamedResult = 'error: $error';
      }

      final passed =
          ordinaryResult == '201; shape=true' &&
          streamedResult == '201; shape=true';
      _finish(
        '${passed ? 'PASS' : 'FAIL'}: ordinary=$ordinaryResult; '
        'streamed=$streamedResult',
      );
    } catch (error) {
      _finish('FAIL: setup error: $error');
    }
  }

  void _finish(String result) {
    if (!mounted) return;
    setState(() => _result = result);
    web.document.title = result.startsWith('PASS')
        ? 'CERT63_BROWSER_PASS'
        : 'CERT63_BROWSER_FAIL';
    web.document.body?.setAttribute('data-cert63-result', result);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(child: Text(_result, textDirection: TextDirection.ltr)),
    ),
  );
}
