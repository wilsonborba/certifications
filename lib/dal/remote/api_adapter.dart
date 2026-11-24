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

  ApiAdapter({this.defaultHeaders = const {}, http.Client? client})
    : _client = client ?? _buildClient();

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
    final csrfToken = readCsrfToken();
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
    final csrfToken = readCsrfToken();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      fullHeaders.putIfAbsent('X-CSRF-Token', () => csrfToken);
      fullHeaders.putIfAbsent('X-CSRFToken', () => csrfToken);
    }
    fullHeaders.removeWhere((k, _) => k.toLowerCase() == 'content-type');

    final resolvedUrl = (queryParams == null || queryParams.isEmpty)
        ? url
        : url.replace(queryParameters: _stringQueryParams(queryParams));

    if (onProgress != null) {
      return _postMultipartWithProgress(
        resolvedUrl,
        headers: fullHeaders,
        fields: fields,
        files: files,
        onProgress: onProgress,
      );
    }

    final req = http.MultipartRequest('POST', resolvedUrl);
    req.headers.addAll(fullHeaders);

    if (fields != null && fields.isNotEmpty) req.fields.addAll(fields);

    if (files != null) {
      for (final f in files) {
        req.files.add(
          http.MultipartFile.fromBytes(
            f.field,
            f.bytes,
            filename: f.filename,
            contentType: f.contentType,
          ),
        );
      }
    }

    // IMPORTANT: send with the SAME credentialed client
    final streamed = await _client.send(req);
    return http.Response.fromStream(streamed);
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
      if (entry.key.toLowerCase() == 'content-type') continue;
      request.setRequestHeader(entry.key, entry.value);
    }
    request.upload.onprogress = ((web.ProgressEvent event) {
      if (event.lengthComputable && event.total > 0) {
        onProgress((event.loaded / event.total).clamp(0.0, 1.0));
      }
    }).toJS;
    request.onload = ((web.ProgressEvent _) {
      if (result.isCompleted) return;
      final responseHeaders = <String, String>{};
      for (final line in request.getAllResponseHeaders().split(
        RegExp(r'\r?\n'),
      )) {
        final separator = line.indexOf(':');
        if (separator <= 0) continue;
        responseHeaders[line.substring(0, separator).trim().toLowerCase()] =
            line.substring(separator + 1).trim();
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
