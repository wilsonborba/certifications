import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/core/utils/my_logs.dart';
import 'package:certifications/dal/local/local_source_adapter.dart';

import 'package:certifications/dal/remote/api_adapter.dart';

import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:http/http.dart';

class ApiAsodyaManager {
  String baseUrl = app_settings.ASODYA_API_URL;
  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Response> exchangeAuthExchangeToken(String authExchangeToken) async {
    final response = await ApiAdapter(defaultHeaders: defaultHeaders).post(
      Uri.parse('$baseUrl/apps/api/v1/exchange'),
      body: jsonEncode({'auth_exchange_token': authExchangeToken}),
    );

    return response;
  }

  Future<Response> updateUserInfo(String fullName, String? phoneE164) async {
    try {
      final csrfToken = readCsrfToken();
      if (csrfToken != null) {
        defaultHeaders['X-CSRF-Token'] = csrfToken;
      }
    } catch (e) {
      debug('Error reading CSRF token: $e');
    }

    // split the full name into first and last name
    // if there is no space, use the full name as first name and empty last name
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.last : '';

    // create the request body
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneE164,
    };

    final jsonBody = jsonEncode(body);

    // continue with the request
    final response = await ApiAdapter(
      defaultHeaders: defaultHeaders,
    ).patch(Uri.parse('$baseUrl/user/info/v1'), body: jsonBody);

    return response;
  }
}
