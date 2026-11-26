import 'package:http/http.dart' as http;

import 'default_http_transport_stub.dart'
    if (dart.library.html) 'default_http_transport_web.dart'
    as platform;

http.Client createDefaultHttpClient() => platform.createDefaultHttpClient();

String? readDefaultCsrfToken() => platform.readDefaultCsrfToken();
