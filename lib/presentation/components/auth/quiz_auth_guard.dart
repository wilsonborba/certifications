import 'package:certifications/core/utils/my_nagivation.dart';
import 'package:certifications/domain/services/pending_intent_store.dart';
import 'package:certifications/presentation/components/auth/login_redirect.dart';
import 'package:certifications/presentation/components/auth/verify_session.dart';

/// Browsing is public, taking a quiz is not (#40). Call this right before
/// actually starting/attempting a quiz, whether it was reached via a shared
/// link or by tapping start on a public quiz found while browsing.
///
/// If a session already exists, returns true immediately so the caller can
/// proceed. Otherwise it stashes [intent] so the exact same quiz can be
/// resumed right after login/signup (see the resume check in
/// BaseSyncAuthState._exchangeTokenAndRoute), sends the visitor through the
/// existing urlRedirectionToAuth flow used everywhere else in this app, and
/// returns false: the caller should stop, navigation is leaving the app.
Future<bool> ensureAuthenticatedForQuiz(
  PendingQuizIntent intent, {
  bool isToLogin = true,
}) async {
  final alreadySignedIn = await isThereSession();
  if (alreadySignedIn) return true;

  await PendingIntentStore.instance.saveQuizIntent(intent);
  redirectToUrl(await urlRedirectionToAuth(isToLogin: isToLogin), replace: true);
  return false;
}
