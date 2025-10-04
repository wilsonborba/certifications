


import 'dart:convert';

import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:http/http.dart';




class ApiAuthManager {

  String baseUrl = app_settings.ASODYA_API_URL;
  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  Future<Response> exchange(String token) async {
    final response = await  ApiAdapter(defaultHeaders: defaultHeaders).post(
      Uri.parse('$baseUrl/apps/api/v1/exchange'),
      body: jsonEncode({'token': token}),
    );


    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug('Next auth nounce updated: $nan from exchange response headers.');
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;

  }

  saveNextAuthNounce(String nan) async {
    final LocalSourceAdapter localSourceAdapter = LocalSourceAdapter(namespace: 'ath');
    await localSourceAdapter.upsert('n-a-n', nan);
    debug('next auth nounce saved: $nan');
  }

}