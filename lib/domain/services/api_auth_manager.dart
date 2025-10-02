


import 'dart:convert';

import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:http/http.dart';

class ApiAuthManager {

  String baseUrl = 'http://127.0.0.1:8000';

  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  Future<Response> exchange(String token) {
    return ApiAdapter(defaultHeaders: defaultHeaders).post(
      Uri.parse('$baseUrl/apps/api/v1/exchange'),
      body: jsonEncode({'token': token}),
    );
  }

}