// lib/core/utils/my_route_parser.dart
import 'dart:html' as html;
import 'package:accredit/core/utils/my_logs.dart';
import 'package:flutter/widgets.dart';

String getLocationHref() {
  try {
    return html.window.location.href;
  } catch (_) {
    return Uri.base.toString();
  }
}

void redirectLocation(String url) {
  // will open in another tab
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}

void replaceLocation(String url, {bool removeSlash = false}) {
  try {
    final finalUrl = removeSlash ? _stripTrailingSlash(url) : url;
    // Use replace OR assign; but don't pushState afterwards.
    html.window.location.replace(finalUrl);
  } catch (_) {}
}

String _stripTrailingSlash(String url) {
  final uri = Uri.parse(url);

  // Don’t touch bare host (/, /?query, /#hash); browsers expect a slash there.
  if (uri.path.isEmpty || uri.path == '/') return url;

  final newPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
  return uri.replace(path: newPath).toString();
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

  List<String> get segments {
    final uri = _parsedUri();
    return uri.pathSegments;
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
