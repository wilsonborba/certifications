import 'dart:convert';

/// Canonical selection strings accepted by certifications_api #35.
class StudySelection {
  static const maxSelectionBytes = 2000;
  static const maxRanges = 64;

  /// Matches the API's text normalization before passage offsets are applied.
  static String normalizeText(String text) => text
      .replaceFirst(RegExp(r'^\uFEFF'), '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

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
