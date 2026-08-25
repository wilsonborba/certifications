import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:accredit/presentation/components/auth/verify_session.dart';
import 'package:http/http.dart';

class QuizContextManager {
  final String baseApi = app_settings.ASODYA_API_URL;

  final String apiEntity = '/apps';

  final String appName = '/certifications';

  final String appVersion = '/v1';

  late final String baseUrl;

  QuizContextManager() {
    baseUrl = "$baseApi$apiEntity$appName$appVersion";
  }

  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Response> getContext(
    String itemName,
    String inputIdentification, {
    bool forceNewGeneration = false,
    int amountQuestion = 10,
  }) async {
    try {
      final csrfToken = readCsrfToken();
      if (csrfToken != null) {
        defaultHeaders['X-CSRF-Token'] = csrfToken;
      }
    } catch (e) {
      debug('Error reading CSRF token: $e');
    }

    final response = await ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse(
        '$baseUrl/context/$itemName/$inputIdentification?force_new_generation=$forceNewGeneration&amount_question=$amountQuestion',
      ),
    );

    return response;
  }
}
