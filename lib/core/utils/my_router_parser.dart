// lib/core/utils/my_route_parser.dart
import 'dart:html' as html;
import 'package:flutter/widgets.dart';

String getLocationHref() {
  try {
    return html.window.location.href;
  } catch (_) {
    return Uri.base.toString();
  }
}

void replaceLocation(String url) {
  try {
    html.window.location.replace(url);
  } catch (_) {}
}

void updatePathWeb(String path) {
  try {
    final currentHref = html.window.location.href;
    final newUrl = Uri.parse(currentHref).replace(path: path).toString();
    html.window.history.pushState(null, '', newUrl);
  } catch (_) {}
}

class MyRouteParser {
  final RouteSettings settings;

  const MyRouteParser({required this.settings});

  String get path {
    final uri = _parsedUri();
    return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
  }

  Uri _parsedUri() {
    try {
      final name = settings.name;
      if (name != null && name.isNotEmpty) {
        return Uri.parse(name);
      }
    } catch (_) {}

    final href = getLocationHref();
    try {
      return Uri.parse(href);
    } catch (_) {
      return Uri.base;
    }
  }

  String? parsedParams(String paramsKey) {
    final uri = _parsedUri();
    return uri.queryParameters[paramsKey];
  }
}
