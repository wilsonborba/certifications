import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createDefaultHttpClient() =>
    BrowserClient()..withCredentials = true;

String? readDefaultCsrfToken() => readCsrfToken();
