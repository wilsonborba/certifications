import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Canonical selection strings accepted by certifications_api #35.
class StudySelection {
  static const maxSelectionBytes = 2000;
  static const maxRanges = 64;

  /// Matches the API's text normalization before passage offsets are applied.
  static String normalizeText(String text) => text
      .replaceFirst(RegExp(r'^\uFEFF'), '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  /// Identifies the exact content to which local pre-upload selections apply.
  /// Text follows the same normalization as upload; binary sources use their
  /// original bytes. The digest is metadata only and never stores the source.
  static String contentDigest(List<int> bytes, {required String kind}) {
    final normalizedBytes =
        const {'txt', 'md', 'csv'}.contains(kind.toLowerCase())
        ? utf8.encode(normalizeText(utf8.decode(bytes)))
        : bytes;
    return sha256.convert(normalizedBytes).toString();
  }

  static String? pages(String input, {required int? pageCount}) {
    final ranges = _parseRanges(input, allowSingleton: true);
    if (ranges == null || ranges.isEmpty) return null;
    var selectedPages = 0;
    for (final range in ranges) {
      if (range.$1 < 1 || range.$2 < range.$1) return null;
      if (pageCount != null && range.$2 > pageCount) return null;
      selectedPages += range.$2 - range.$1 + 1;
    }
    if (selectedPages > 100) return null;
    return ranges
        .map((r) => r.$1 == r.$2 ? '${r.$1}' : '${r.$1}-${r.$2}')
        .join(',');
  }

  static String? audio(String input) {
    final spec = input.trim();
    if (!spec.startsWith('ms:')) return null;
    final ranges = _parseRanges(
      spec.substring(3),
      allowSingleton: false,
      mergeAdjacent: true,
    );
    if (ranges == null || ranges.isEmpty) return null;
    for (final range in ranges) {
      if (range.$1 < 0 || range.$2 <= range.$1) return null;
    }
    return 'ms:${ranges.map((r) => '${r.$1}-${r.$2}').join(',')}';
  }

  static String? passage(String input, String normalizedText) {
    final text = normalizeText(normalizedText);
    final spec = input.trim();
    if (utf8.encode(spec).length > maxSelectionBytes) {
      return null;
    }
    final ranges = <(int, int)>[];
    var previousEnd = -1;
    for (final item in spec.split(',')) {
      final part = item.trim();
      if (!part.startsWith('p1:')) return null;
      final range = part.substring(3);
      final match = RegExp(r'^(\d+)-(\d+)$').firstMatch(range);
      if (match == null) return null;
      final start = int.tryParse(match.group(1)!);
      final end = int.tryParse(match.group(2)!);
      if (start == null ||
          end == null ||
          start < 0 ||
          end <= start ||
          start < previousEnd) {
        return null;
      }
      // String.length is the UTF-16 code-unit length used by the API contract.
      if (end > text.length) return null;
      ranges.add((start, end));
      if (ranges.length > maxRanges) return null;
      previousEnd = end;
    }
    if (ranges.isEmpty) return null;
    return ranges.map((r) => 'p1:${r.$1}-${r.$2}').join(',');
  }

  /// Adds a text selection expressed in UTF-16 code-unit offsets and returns
  /// the canonical passage spec. Overlapping selections are combined; separate
  /// selections remain ordered source ranges.
  static String? includePassageRange(
    String currentSpec,
    int start,
    int end,
    String normalizedText,
  ) {
    final text = normalizeText(normalizedText);
    if (start < 0 || end <= start || end > text.length) return null;
    if (!_isUtf16Boundary(text, start) || !_isUtf16Boundary(text, end)) {
      return null;
    }

    final ranges = passageRanges(currentSpec, text) ?? <(int, int)>[];
    ranges.add((start, end));
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final range in ranges) {
      if (merged.isNotEmpty && range.$1 <= merged.last.$2) {
        merged[merged.length - 1] = (
          merged.last.$1,
          range.$2 > merged.last.$2 ? range.$2 : merged.last.$2,
        );
      } else {
        merged.add(range);
      }
    }
    final spec = merged.map((range) => 'p1:${range.$1}-${range.$2}').join(',');
    return passage(spec, text);
  }

  /// Returns validated passage offsets for rendering source highlights.
  static List<(int, int)>? passageRanges(String input, String text) {
    final canonical = passage(input, text);
    if (canonical == null) return null;
    return [
      for (final item in canonical.split(','))
        (
          int.parse(item.substring(3, item.indexOf('-', 3))),
          int.parse(item.substring(item.indexOf('-', 3) + 1)),
        ),
    ];
  }

  static bool _isUtf16Boundary(String text, int offset) {
    if (offset <= 0 || offset >= text.length) return true;
    final previous = text.codeUnitAt(offset - 1);
    final next = text.codeUnitAt(offset);
    return !(previous >= 0xD800 &&
        previous <= 0xDBFF &&
        next >= 0xDC00 &&
        next <= 0xDFFF);
  }

  static List<(int, int)>? _parseRanges(
    String input, {
    required bool allowSingleton,
    bool mergeAdjacent = false,
  }) {
    if (input.isEmpty || utf8.encode(input).length > maxSelectionBytes) {
      return null;
    }
    final result = <(int, int)>[];
    var previousEnd = -1;
    for (final item in input.split(',')) {
      final pattern = allowSingleton
          ? RegExp(r'^(\d+)(?:-(\d+))?$')
          : RegExp(r'^(\d+)-(\d+)$');
      final match = pattern.firstMatch(item);
      if (match == null) return null;
      final start = int.tryParse(match.group(1)!);
      final end = int.tryParse(match.group(2) ?? match.group(1)!);
      if (start == null ||
          end == null ||
          (!allowSingleton && end <= start) ||
          start < previousEnd ||
          (!mergeAdjacent && start == previousEnd)) {
        return null;
      }
      if (mergeAdjacent && result.isNotEmpty && start == previousEnd) {
        result[result.length - 1] = (result.last.$1, end);
      } else {
        result.add((start, end));
      }
      previousEnd = end;
    }
    return result.length <= maxRanges ? result : null;
  }
}
