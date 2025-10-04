// api_adapter.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart'; // web-only app is fine
import 'package:http_parser/http_parser.dart';

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

  Future<http.Response> request({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParams,
    Encoding? encoding,
  }) async {
    final fullHeaders = {...defaultHeaders, if (headers != null) ...headers};
    final resolvedUrl =
        queryParams != null ? url.replace(queryParameters: queryParams) : url;

    // USE the credentialed client you built above
    switch (method.toUpperCase()) {
      case 'GET':
        return _client.get(resolvedUrl, headers: fullHeaders);
      case 'POST':
        return _client.post(resolvedUrl,
            headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
      case 'PUT':
        return _client.put(resolvedUrl,
            headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
      case 'PATCH':
        return _client.patch(resolvedUrl,
            headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
      case 'DELETE':
        return _client.delete(resolvedUrl,
            headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }

  dynamic _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  Future<http.Response> get(Uri url,
          {Map<String, String>? headers, Map<String, dynamic>? queryParams}) =>
      request(method: 'GET', url: url, headers: headers, queryParams: queryParams);

  Future<http.Response> post(Uri url,
          {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'POST', url: url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> put(Uri url,
          {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'PUT', url: url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> patch(Uri url,
          {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'PATCH', url: url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> delete(Uri url,
          {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'DELETE', url: url, headers: headers, body: body, encoding: encoding);
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
  }) async {
    final fullHeaders = {...defaultHeaders, if (headers != null) ...headers};
    fullHeaders.removeWhere((k, _) => k.toLowerCase() == 'content-type');

    final resolvedUrl =
        queryParams != null ? url.replace(queryParameters: queryParams) : url;

    final req = http.MultipartRequest('POST', resolvedUrl);
    req.headers.addAll(fullHeaders);

    if (fields != null && fields.isNotEmpty) req.fields.addAll(fields);

    if (files != null) {
      for (final f in files) {
        req.files.add(http.MultipartFile.fromBytes(
          f.field,
          f.bytes,
          filename: f.filename,
          contentType: f.contentType,
        ));
      }
    }

    // IMPORTANT: send with the SAME credentialed client
    final streamed = await _client.send(req);
    return http.Response.fromStream(streamed);
  }
}
