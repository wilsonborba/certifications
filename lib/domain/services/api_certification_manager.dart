import 'dart:convert';

import 'package:accredit/core/settings.dart';

import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:accredit/domain/models/quiz.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/components/auth/verify_session.dart';

import 'package:http/http.dart';

class CertificationManager {
  final String baseApi = app_settings.ASODYA_API_URL;

  final String apiEntity = '/apps';

  final String appName = '/certifications';

  final String appVersion = '/v1';

  late final String baseUrl;

  CertificationManager() {
    baseUrl = "$baseApi$apiEntity$appName$appVersion";
  }

  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Response> applyComplain(
    String text,
    dynamic questionId,
    bool isForPDF,
    dynamic contextId,
    dynamic pdfQuestionId,
  ) async {
    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    debug(
      'Applying complaint to $baseUrl/complaints with headers: $defaultHeaders',
    );

    Map<String, dynamic> body;

    Uri uriPath;

    if (!isForPDF) {
      // it will be on DB Postgres
      uriPath = Uri.parse('$baseUrl/context/complaints');
      body = {'question_id': questionId, 'complaint_text': text};
    } else {
      // is temp on Redis/Valkey
      uriPath = Uri.parse('$baseUrl/pdf/context/complaints');
      body = {
        'document_id': contextId,
        'complaint_text': text,
        'pdf_question_id': pdfQuestionId,
      };
    }

    final jsonBody = jsonEncode(body);
    // continue with the request
    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).post(uriPath, body: jsonBody);

    if (response.statusCode == 201) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug(
          'Next auth nounce updated: $nan from applyQuiz response headers.',
        );
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;
  }

  Future<Response> submitQuiz(
    List<AnswerSelection> payload,
    Duration timeSpent,
    CertificationFormData formData,
    bool isForPDF,
    String contextId,
  ) async {
    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      debug('current hint cookie: $hintCookies');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    final body = {
      'answers': payload.map((e) => e.toJson()).toList(),
      'time_spent_seconds': timeSpent.inSeconds,
      'certification_title': formData.certificationTitle,
      'full_name': formData.fullName,
      'language': formData.language,
      'is_for_pdf': isForPDF,
    };

    if (isForPDF) {
      body['document_id'] = contextId;
    }

    final jsonBody = jsonEncode(body);

    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).post(Uri.parse('$baseUrl/quiz/revision'), body: jsonBody);

    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug(
          'Next auth nounce updated: $nan from submitQuiz response headers.',
        );
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;
  }

  Future<Response> getCertification(String certificationId) async {
    // update the headers with auth nounce

    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    debug(
      'Fetching certification from $baseUrl/quiz/certifications/$certificationId with headers: $defaultHeaders',
    );

    // continue with the request
    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).get(Uri.parse('$baseUrl/quiz/certifications/$certificationId'));

    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug(
          'Next auth nounce updated: $nan from getCertification response headers.',
        );
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;
  }

  Future<Response> getCards() async {
    // update the headers with auth nounce

    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    debug(
      'Fetching cards from $baseUrl/all_items with headers: $defaultHeaders',
    );

    // continue with the request
    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).get(Uri.parse('$baseUrl/all_items'));

    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug('Next auth nounce updated: $nan from getCards response headers.');
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;
  }

  Future<Response> getTopicsFromCard(
    String itemName,
    int page,
    int perPage,
  ) async {
    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    debug(
      'Fetching cards from $baseUrl/topics/$itemName?page=$page&per_page=$perPage with headers: $defaultHeaders',
    );

    // continue with the request

    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).get(Uri.parse('$baseUrl/topics/$itemName?page=$page&per_page=$perPage'));

    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug(
          'Next auth nounce updated: $nan from getTopicsFromCard response headers.',
        );
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;
  }

  // example
  // curl -X 'GET' \
  // 'http://127.0.0.1:8001/search/wikipedia?q=santos&page=1&per_page=20&mode=fulltext&fill_page=true&max_extra_pages=2' \
  // -H 'accept: application/json'//

  Future<Response> searchTopics(
    String itemName,
    String query,
    int page,
    int perPage,
    String mode,
    bool fillPage,
    int maxExtraPages,
  ) async {
    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    debug(
      'Fetching cards from $baseUrl/search/$itemName?q=$query&page=$page&per_page=$perPage&mode=$mode&fill_page=$fillPage&max_extra_pages=$maxExtraPages with headers: $defaultHeaders',
    );

    // continue with the request

    final response = await ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse(
        '$baseUrl/search/$itemName?q=$query&page=$page&per_page=$perPage&mode=$mode&fill_page=$fillPage&max_extra_pages=$maxExtraPages',
      ),
    );

    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug(
          'Next auth nounce updated: $nan from searchTopics response headers.',
        );
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;
  }

  Future<Response> requestNewCards(String url) async {
    // update the headers with auth nounce

    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    debug(
      'Requesting new cards from $baseUrl/request_new with headers: $defaultHeaders',
    );

    // create the request body
    final body = {'url': url};

    // parse to json

    final jsonBody = jsonEncode(body);

    // continue with the request
    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).post(Uri.parse('$baseUrl/topics/solicitate_new'), body: jsonBody);

    if (response.statusCode == 201) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug(
          'Next auth nounce updated: $nan from requestNewCards response headers.',
        );
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;
  }

  Future<Response> createUserToken(
    String provider,
    String name,
    String apiKey,
    bool isDefault,
  ) async {
    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }
    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }

    debug(
      'Requesting new cards from $baseUrl/request_new with headers: $defaultHeaders',
    );

    // create the request body
    final body = {
      'token_name': name,
      'token_value': apiKey,
      "is_default": isDefault,
    };

    // parse to json
    final jsonBody = jsonEncode(body);

    // continue with the request
    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).post(Uri.parse('$baseUrl/tokens/create_token'), body: jsonBody);

    debug('createUserToken body status: ${response.body}');
    if (response.statusCode == 201) {
      final headers = response.headers;
      // get next auth nounce
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug(
          'Next auth nounce updated: $nan from createUserToken response headers.',
        );
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }
    return response;
  }
}
