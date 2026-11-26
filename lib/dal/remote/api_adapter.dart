import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:certifications/presentation/components/auth/verify_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart'; // web-only app is fine
import 'package:http_parser/http_parser.dart';
import 'package:web/web.dart' as web;

class ApiAdapter {
  final Map<String, String> defaultHeaders;
  final http.Client _client;
  final String? Function() csrfTokenProvider;

  ApiAdapter({
    this.defaultHeaders = const {},
    http.Client? client,
    this.csrfTokenProvider = readCsrfToken,
  }) : _client = client ?? _buildClient();

  static http.Client _buildClient() {
    final c = BrowserClient();
    c.withCredentials = true; // <-- critical for cookies on XHR/fetch
    return c;
  }

  Map<String, String> _stringQueryParams(Map<String, dynamic> qp) {
    final out = <String, String>{};
    qp.forEach((k, v) {
      if (v == null) return;

      if (v is Iterable) {
        out[k] = v
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join(',');
        return;
      }

      out[k] = v.toString();
    });
    return out;
  }

  Future<http.Response> request({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParams,
    Encoding? encoding,
  }) async {
    final fullHeaders = {...defaultHeaders, if (headers != null) ...headers};
    final csrfToken = csrfTokenProvider();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      fullHeaders.putIfAbsent('X-CSRF-Token', () => csrfToken);
      fullHeaders.putIfAbsent('X-CSRFToken', () => csrfToken);
    }
    final resolvedUrl = (queryParams == null || queryParams.isEmpty)
        ? url
        : url.replace(queryParameters: _stringQueryParams(queryParams));

    // USE the credentialed client you built above
    switch (method.toUpperCase()) {
      case 'GET':
        return _client.get(resolvedUrl, headers: fullHeaders);
      case 'POST':
        return _client.post(
          resolvedUrl,
          headers: fullHeaders,
          body: _encodeBody(body),
          encoding: encoding,
        );
      case 'PUT':
        return _client.put(
          resolvedUrl,
          headers: fullHeaders,
          body: _encodeBody(body),
          encoding: encoding,
        );
      case 'PATCH':
        return _client.patch(
          resolvedUrl,
          headers: fullHeaders,
          body: _encodeBody(body),
          encoding: encoding,
        );
      case 'DELETE':
        return _client.delete(
          resolvedUrl,
          headers: fullHeaders,
          body: _encodeBody(body),
          encoding: encoding,
        );
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }

  dynamic _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) => request(
    method: 'GET',
    url: url,
    headers: headers,
    queryParams: queryParams,
  );

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) => request(
    method: 'POST',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  /// Sends a JSON upload through XHR so the browser can report actual bytes
  /// transmitted. Injected clients keep the same request contract for tests.
  Future<http.Response> postJsonWithProgress({
    required Uri url,
    required Map<String, dynamic> body,
    void Function(double progress)? onProgress,
  }) async {
    final headers = {
      ...defaultHeaders,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final csrfToken = csrfTokenProvider();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      headers.putIfAbsent('X-CSRF-Token', () => csrfToken);
      headers.putIfAbsent('X-CSRFToken', () => csrfToken);
    }
    final encoded = jsonEncode(body);
    if (_client is! BrowserClient || onProgress == null) {
      return _client.post(url, headers: headers, body: encoded);
    }

    final xhr = web.XMLHttpRequest()
      ..open('POST', url.toString())
      ..withCredentials = true;
    for (final entry in headers.entries) {
      xhr.setRequestHeader(entry.key, entry.value);
    }
    final completer = Completer<http.Response>();
    xhr.upload.onprogress = ((web.ProgressEvent event) {
      if (event.lengthComputable) {
        onProgress((event.loaded / event.total).clamp(0.0, 1.0));
      }
    }).toJS;
    xhr.onload = ((web.Event _) {
      final responseHeaders = <String, String>{};
      for (final line in xhr.getAllResponseHeaders().split('\r\n')) {
        final separator = line.indexOf(':');
        if (separator > 0) {
          responseHeaders[line.substring(0, separator).trim().toLowerCase()] =
              line.substring(separator + 1).trim();
        }
      }
      onProgress(1);
      completer.complete(
        http.Response(
          xhr.responseText,
          xhr.status,
          headers: responseHeaders,
          request: http.Request('POST', url),
        ),
      );
    }).toJS;
    xhr.onerror = ((web.Event _) {
      completer.completeError(
        http.ClientException('Upload request failed', url),
      );
    }).toJS;
    xhr.onabort = ((web.Event _) {
      completer.completeError(
        http.ClientException('Upload request aborted', url),
      );
    }).toJS;
    xhr.send(encoded.toJS);
    return completer.future;
  }

  Future<http.Response> postEventStream({
    required Uri url,
    required void Function(String event, String data) onEvent,
    Future<void>? abortTrigger,
  }) => _eventStream(
    method: 'POST',
    url: url,
    onEvent: onEvent,
    abortTrigger: abortTrigger,
  );

  Future<http.Response> getEventStream({
    required Uri url,
    required void Function(String event, String data) onEvent,
  }) => _eventStream(method: 'GET', url: url, onEvent: onEvent);

  Future<http.Response> _eventStream({
    required String method,
    required Uri url,
    required void Function(String event, String data) onEvent,
    Future<void>? abortTrigger,
  }) async {
    final headers = {...defaultHeaders, 'Accept': 'text/event-stream'};
    final csrfToken = csrfTokenProvider();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      headers.putIfAbsent('X-CSRF-Token', () => csrfToken);
      headers.putIfAbsent('X-CSRFToken', () => csrfToken);
    }
    final request = abortTrigger == null
        ? http.Request(method, url)
        : http.AbortableRequest(method, url, abortTrigger: abortTrigger);
    request.headers.addAll(headers);
    final streamed = await _client.send(request);
    final captured = StringBuffer();
    var eventName = 'message';
    final eventData = <String>[];

    void dispatch() {
      if (eventData.isNotEmpty &&
          streamed.statusCode >= 200 &&
          streamed.statusCode < 300) {
        onEvent(eventName, eventData.join('\n'));
      }
      eventName = 'message';
      eventData.clear();
    }

    await for (final line
        in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      captured.writeln(line);
      if (line.isEmpty) {
        dispatch();
      } else if (!line.startsWith(':')) {
        final separator = line.indexOf(':');
        final field = separator < 0 ? line : line.substring(0, separator);
        final value = separator < 0
            ? ''
            : line.substring(separator + 1).replaceFirst(RegExp(r'^ '), '');
        if (field == 'event') eventName = value;
        if (field == 'data') eventData.add(value);
      }
    }
    dispatch();
    return http.Response(
      captured.toString(),
      streamed.statusCode,
      headers: streamed.headers,
      request: request,
    );
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) => request(
    method: 'PUT',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) => request(
    method: 'PATCH',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Encoding? encoding,
  }) => request(
    method: 'DELETE',
    url: url,
    headers: headers,
    body: body,
    encoding: encoding,
  );
}

class MultipartFileData {
  final String field;
  final List<int> bytes;
  final String filename;
  final MediaType? contentType;

  const MultipartFileData({
    required this.field,
    required this.bytes,
    required this.filename,
    this.contentType,
  });
}

extension ApiAdapterMultipart on ApiAdapter {
  Future<http.Response> postMultipart({
    required Uri url,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<MultipartFileData>? files,
    void Function(double progress)? onProgress,
  }) async {
    final fullHeaders = {...defaultHeaders, if (headers != null) ...headers};
    final csrfToken = csrfTokenProvider();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      fullHeaders.putIfAbsent('X-CSRF-Token', () => csrfToken);
      fullHeaders.putIfAbsent('X-CSRFToken', () => csrfToken);
    }
    fullHeaders.removeWhere((k, _) => k.toLowerCase() == 'content-type');
    final resolvedUrl = (queryParams == null || queryParams.isEmpty)
        ? url
        : url.replace(queryParameters: _stringQueryParams(queryParams));
    if (onProgress != null && _client is BrowserClient) {
      return _postMultipartWithProgress(
        resolvedUrl,
        headers: fullHeaders,
        fields: fields,
        files: files,
        onProgress: onProgress,
      );
    }

    final request = http.MultipartRequest('POST', resolvedUrl)
      ..headers.addAll(fullHeaders);
    if (fields != null && fields.isNotEmpty) request.fields.addAll(fields);
    for (final file in files ?? const <MultipartFileData>[]) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.filename,
          contentType: file.contentType,
        ),
      );
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    onProgress?.call(1);
    return response;
  }

  Future<http.Response> _postMultipartWithProgress(
    Uri url, {
    required Map<String, String> headers,
    Map<String, String>? fields,
    List<MultipartFileData>? files,
    required void Function(double progress) onProgress,
  }) {
    final form = web.FormData();
    fields?.forEach((name, value) => form.append(name, value.toJS));
    for (final file in files ?? const <MultipartFileData>[]) {
      final blob = web.Blob(
        [Uint8List.fromList(file.bytes).toJS].toJS,
        web.BlobPropertyBag(
          type: file.contentType?.toString() ?? 'application/octet-stream',
        ),
      );
      form.append(file.field, blob, file.filename);
    }
    final request = web.XMLHttpRequest();
    final result = Completer<http.Response>();
    request.open('POST', url.toString());
    request.withCredentials = true;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != 'content-type') {
        request.setRequestHeader(entry.key, entry.value);
      }
    }
    request.upload.onprogress = ((web.ProgressEvent event) {
      if (event.lengthComputable && event.total > 0) {
        onProgress((event.loaded / event.total).clamp(0.0, 1.0));
      }
    }).toJS;
    request.onload = ((web.ProgressEvent _) {
      if (result.isCompleted) return;
      onProgress(1);
      final responseHeaders = <String, String>{};
      for (final line in request.getAllResponseHeaders().split(
        RegExp(r'\r?\n'),
      )) {
        final separator = line.indexOf(':');
        if (separator > 0) {
          responseHeaders[line.substring(0, separator).trim().toLowerCase()] =
              line.substring(separator + 1).trim();
        }
      }
      result.complete(
        http.Response(
          request.responseText,
          request.status,
          headers: responseHeaders,
        ),
      );
    }).toJS;
    request.onerror = ((web.Event _) {
      if (!result.isCompleted) {
        result.completeError(StateError('The upload request failed.'));
      }
    }).toJS;
    request.onabort = ((web.Event _) {
      if (!result.isCompleted) {
        result.completeError(StateError('The upload request was cancelled.'));
      }
    }).toJS;
    request.send(form);
    return result.future;
  }
}
