import 'package:certifications/dal/local/local_source_adapter.dart';

/// Persists client-side draft progress for a study: which wizard step the
/// user last left it on, and when it was last touched.
///
/// The backend `Study` model has no field for this (it is a purely local,
/// per-browser convenience), so it is kept in `localStorage` the same way
/// [WaitlistStore] persists its own local-only state, namespaced by study id.
class DraftProgressStore {
  DraftProgressStore._();
  static final DraftProgressStore instance = DraftProgressStore._();

  final LocalSourceAdapter _storage =
      LocalSourceAdapter(namespace: 'certifications.draft_progress');

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

  Future<void> clear(String studyId) async {
    await _storage.delete('$studyId::step');
    await _storage.delete('$studyId::lastOpenedAt');
  }
}
