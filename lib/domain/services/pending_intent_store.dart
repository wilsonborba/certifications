import 'package:certifications/dal/local/local_source_adapter.dart';

/// Describes a quiz an anonymous visitor was trying to take (via a shared
/// link, or by tapping start on a public quiz while browsing) when they were
/// redirected through login/signup, so the app can resume exactly that
/// action once they are authenticated instead of dropping them on the
/// generic logged-in home screen.
///
/// At least one of [shareToken] or [quizId] is always set: a shared-link
/// visit carries a token, browsing a public quiz by id carries a quiz id.
class PendingQuizIntent {
  const PendingQuizIntent({this.shareToken, this.quizId, this.quizTitle})
    : assert(shareToken != null || quizId != null);

  final String? shareToken;
  final String? quizId;
  final String? quizTitle;

  Map<String, dynamic> toJson() => {
    'share_token': shareToken,
    'quiz_id': quizId,
    'quiz_title': quizTitle,
  };

  static PendingQuizIntent? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final shareToken = json['share_token'] as String?;
    final quizId = json['quiz_id'] as String?;
    if ((shareToken == null || shareToken.isEmpty) && (quizId == null || quizId.isEmpty)) {
      return null;
    }
    return PendingQuizIntent(
      shareToken: (shareToken != null && shareToken.isNotEmpty) ? shareToken : null,
      quizId: (quizId != null && quizId.isNotEmpty) ? quizId : null,
      quizTitle: json['quiz_title'] as String?,
    );
  }
}

/// Persists the one pending quiz intent an anonymous visitor had before
/// being redirected through login/signup (#40), so it can be resumed right
/// after authentication. Namespaced the same way [DraftProgressStore] and
/// `WaitlistStore` persist their own local-only state.
class PendingIntentStore {
  PendingIntentStore._();
  static final PendingIntentStore instance = PendingIntentStore._();

  final LocalSourceAdapter _storage =
      LocalSourceAdapter(namespace: 'certifications.pending_intent');
  static const _key = 'quiz_intent';

  Future<void> saveQuizIntent(PendingQuizIntent intent) async {
    await _storage.upsert(_key, intent.toJson());
  }

  /// Reads and clears the pending intent, if any. "Consume" rather than
  /// "get" since it should only ever be resumed once, right after the auth
  /// flow that was waiting on it completes.
  Future<PendingQuizIntent?> consumeQuizIntent() async {
    final raw = await _storage.read<Map<String, dynamic>>(_key);
    if (raw == null) return null;
    await _storage.delete(_key);
    return PendingQuizIntent.fromJson(raw);
  }
}
