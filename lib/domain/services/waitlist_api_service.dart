import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';

class WaitlistApiException implements Exception {
  const WaitlistApiException(this.statusCode);
  final int statusCode;
}

class WaitlistApiService {
  WaitlistApiService({ApiAdapter? adapter})
    : _adapter =
          adapter ??
          ApiAdapter(defaultHeaders: const {'Accept': 'application/json'});

  final ApiAdapter _adapter;

  Future<bool> joinFreePlanWaitlist() async {
    final response = await _adapter.post(
      Uri.parse(
        '${app_settings.ASODYA_API_URL}/apps/certifications/v1/waitlist',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'plan': 'free'}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WaitlistApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['data'] as Map<String, dynamic>)['already_joined'] == true;
  }
}
