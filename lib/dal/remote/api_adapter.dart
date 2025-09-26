import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:http_parser/http_parser.dart';

class ApiAdapter {
  final Map<String, String> defaultHeaders;

  ApiAdapter({this.defaultHeaders = const {}});

  /// Unified method to make any HTTP request
  Future<http.Response> request({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    Map<String, dynamic>? queryParams,
    Encoding? encoding,
  }) async {
    final fullHeaders = {...defaultHeaders, if (headers != null) ...headers};

    final resolvedUrl = queryParams != null ? url.replace(queryParameters: queryParams) : url;

    final client = http.Client();
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await client.get(resolvedUrl, headers: fullHeaders);
        case 'POST':
          return await client.post(resolvedUrl, headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
        case 'PUT':
          return await client.put(resolvedUrl, headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
        case 'PATCH':
          return await client.patch(resolvedUrl, headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
        case 'DELETE':
          return await client.delete(resolvedUrl, headers: fullHeaders, body: _encodeBody(body), encoding: encoding);
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } finally {
      client.close();
    }
  }

  /// Helper for automatic JSON encoding
  dynamic _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  /// Shortcuts (like Python's requests)
  Future<http.Response> get(Uri url, {Map<String, String>? headers, Map<String, dynamic>? queryParams}) =>
      request(method: 'GET', url: url, headers: headers, queryParams: queryParams);

  Future<http.Response> post(Uri url, {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'POST', url: url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> put(Uri url, {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'PUT', url: url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> patch(Uri url, {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'PATCH', url: url, headers: headers, body: body, encoding: encoding);

  Future<http.Response> delete(Uri url, {Map<String, String>? headers, dynamic body, Encoding? encoding}) =>
      request(method: 'DELETE', url: url, headers: headers, body: body, encoding: encoding);
}


class MultipartFileData {
  final String field;           // ex: 'file'
  final List<int> bytes;        // conteúdo do arquivo
  final String filename;        // ex: 'documento.pdf'
  final MediaType? contentType; // ex: MediaType('application', 'pdf')

  const MultipartFileData({
    required this.field,
    required this.bytes,
    required this.filename,
    this.contentType,
  });
}

extension ApiAdapterMultipart on ApiAdapter {
  /// POST multipart/form-data (com query params).
  /// Retorna http.Response para manter mesma ergonomia do adapter.
  Future<http.Response> postMultipart({
    required Uri url,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<MultipartFileData>? files,
  }) async {
    final fullHeaders = {...defaultHeaders, if (headers != null) ...headers};

    // NÃO fixe 'Content-Type': o http.MultipartRequest define o boundary.
    fullHeaders.removeWhere((k, _) => k.toLowerCase() == 'content-type');

    final resolvedUrl =
        queryParams != null ? url.replace(queryParameters: queryParams) : url;

    final req = http.MultipartRequest('POST', resolvedUrl);
    req.headers.addAll(fullHeaders);

    if (fields != null && fields.isNotEmpty) {
      req.fields.addAll(fields);
    }

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

    final streamed = await req.send();
    return http.Response.fromStream(streamed);
  }
}