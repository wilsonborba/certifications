import 'package:certifications/dal/local/local_source_adapter.dart';
import 'package:certifications/domain/models/quiz.dart';

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

  Future<void> clear(String studyId) async {
    await _storage.delete('$studyId::step');
    await _storage.delete('$studyId::lastOpenedAt');
    await _storage.delete('$studyId::visibility');
  }
}
