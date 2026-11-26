import 'dart:convert';

import 'package:certifications/dal/local/local_source_adapter.dart';
import 'package:certifications/domain/models/quiz.dart';

class DraftSourceSelection {
  const DraftSourceSelection({
    required this.contentDigest,
    required this.kind,
    required this.spec,
  });

  final String contentDigest;
  final String kind;
  final String spec;
}

/// Persists client-side draft progress for a study: which wizard step the
/// user last left it on, when it was last touched, and the visibility choice
/// made in the wizard's Step 4.
///
/// The backend `Study` model has no field for any of this (it is a purely
/// local, per-browser convenience), so it is kept in `localStorage` the same
/// way [WaitlistStore] persists its own local-only state, namespaced by
/// study id.
class DraftProgressStore {
  DraftProgressStore._();
  static final DraftProgressStore instance = DraftProgressStore._();

  final LocalSourceAdapter _storage = LocalSourceAdapter(
    namespace: 'certifications.draft_progress',
  );

  static const _sourceSelectionsKey = 'sourceSelections';
  static const _sourceSelectionsVersion = 1;
  static const _maxSourceSelectionEntries = 64;
  static const _maxSourceSelectionRecordBytes = 160 * 1024;
  static const _selectionKinds = {'pages', 'passages', 'intervals'};

  Future<int?> getStep(String studyId) async {
    final value = await _storage.read<num>('$studyId::step');
    return value?.toInt();
  }

  Future<void> saveStep(String studyId, int step) async {
    await _storage.upsert('$studyId::step', step);
    await touch(studyId);
  }

  /// Records "now" as the last time this study's draft was opened/edited.
  /// Used to pick the most recently worked-on draft for the resume hero card.
  Future<void> touch(String studyId) async {
    await _storage.upsert(
      '$studyId::lastOpenedAt',
      DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> getLastOpenedAt(String studyId) async {
    final raw = await _storage.read<String>('$studyId::lastOpenedAt');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Persists the visibility chosen in the wizard's Step 4, so it can be
  /// recovered later when the quiz taken from this study is finished and
  /// saved via `POST /quizzes/completed`.
  Future<void> saveVisibility(String studyId, QuizVisibility visibility) async {
    await _storage.upsert('$studyId::visibility', visibility.apiValue);
  }

  /// Reads back the visibility saved by [saveVisibility], defaulting to
  /// private (matching the backend's own default) when nothing was saved.
  Future<QuizVisibility> getVisibility(String studyId) async {
    final raw = await _storage.read<String>('$studyId::visibility');
    return QuizVisibility.parse(raw);
  }

  Future<void> saveGenerationJobId(String studyId, String jobId) async {
    await _storage.upsert('$studyId::generationJobId', jobId);
  }

  Future<String?> getGenerationJobId(String studyId) async =>
      _storage.read<String>('$studyId::generationJobId');

  Future<void> clearGenerationJobId(String studyId) async {
    await _storage.delete('$studyId::generationJobId');
  }

  Future<void> saveGenerationIdempotencyKey(String studyId, String key) async {
    await _storage.upsert('$studyId::generationIdempotencyKey', key);
  }

  Future<String?> getGenerationIdempotencyKey(String studyId) async =>
      _storage.read<String>('$studyId::generationIdempotencyKey');

  Future<void> clearGenerationIdempotencyKey(String studyId) async {
    await _storage.delete('$studyId::generationIdempotencyKey');
  }

  /// Stores only bounded selection metadata for files not yet uploaded. The
  /// content digest prevents applying old ranges to a different reselected
  /// file; source bytes and extracted text are never persisted here.
  Future<void> saveSourceSelections(
    String studyId,
    Iterable<DraftSourceSelection> selections,
  ) async {
    final entries = selections.toList(growable: false);
    if (entries.length > _maxSourceSelectionEntries ||
        entries.any(
          (entry) =>
              !_isDigest(entry.contentDigest) ||
              !_selectionKinds.contains(entry.kind) ||
              entry.spec.isEmpty ||
              utf8.encode(entry.spec).length > 2000,
        ) ||
        entries.map((entry) => entry.contentDigest).toSet().length !=
            entries.length) {
      await _storage.delete('$studyId::$_sourceSelectionsKey');
      return;
    }

    final record = {
      'version': _sourceSelectionsVersion,
      'entries': [
        for (final entry in entries)
          {
            'digest': entry.contentDigest,
            'kind': entry.kind,
            'spec': entry.spec,
          },
      ],
    };
    if (utf8.encode(jsonEncode(record)).length >
        _maxSourceSelectionRecordBytes) {
      await _storage.delete('$studyId::$_sourceSelectionsKey');
      return;
    }
    await _storage.upsert('$studyId::$_sourceSelectionsKey', record);
  }

  /// Invalid, oversized, or unsupported records are discarded as a whole so
  /// stale ranges can never be guessed onto a newly selected file.
  Future<List<DraftSourceSelection>> getSourceSelections(String studyId) async {
    final storageKey = '$studyId::$_sourceSelectionsKey';
    try {
      final record = await _storage.read<Map<String, dynamic>>(storageKey);
      if (record == null) return const [];
      if (record['version'] != _sourceSelectionsVersion ||
          record['entries'] is! List) {
        await _storage.delete(storageKey);
        return const [];
      }
      final rawEntries = record['entries'] as List<dynamic>;
      if (rawEntries.length > _maxSourceSelectionEntries ||
          utf8.encode(jsonEncode(record)).length >
              _maxSourceSelectionRecordBytes) {
        await _storage.delete(storageKey);
        return const [];
      }

      final entries = <DraftSourceSelection>[];
      final seenDigests = <String>{};
      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map<String, dynamic>) {
          await _storage.delete(storageKey);
          return const [];
        }
        final digest = rawEntry['digest'];
        final kind = rawEntry['kind'];
        final spec = rawEntry['spec'];
        if (digest is! String ||
            !_isDigest(digest) ||
            !seenDigests.add(digest) ||
            kind is! String ||
            !_selectionKinds.contains(kind) ||
            spec is! String ||
            spec.isEmpty ||
            utf8.encode(spec).length > 2000) {
          await _storage.delete(storageKey);
          return const [];
        }
        entries.add(
          DraftSourceSelection(contentDigest: digest, kind: kind, spec: spec),
        );
      }
      return entries;
    } catch (_) {
      await _storage.delete(storageKey);
      return const [];
    }
  }

  bool _isDigest(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

  Future<void> clear(String studyId) async {
    await _storage.delete('$studyId::step');
    await _storage.delete('$studyId::lastOpenedAt');
    await _storage.delete('$studyId::visibility');
    await _storage.delete('$studyId::generationJobId');
    await _storage.delete('$studyId::generationIdempotencyKey');
    await _storage.delete('$studyId::$_sourceSelectionsKey');
  }
}
