import 'dart:convert';
import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/quiz.dart';

class QuizApiException implements Exception {
  const QuizApiException(this.statusCode);
  final int statusCode;
}

/// Thrown by [QuizApiService.delete] when the backend refuses to delete a
/// public quiz that already has third-party attempts recorded against it
/// (HTTP 403), so leaderboard history stays intact.
class QuizDeleteForbiddenException implements Exception {
  const QuizDeleteForbiddenException();
}

class QuizApiService {
  QuizApiService({ApiAdapter? adapter})
    : _adapter =
          adapter ??
          ApiAdapter(defaultHeaders: const {'Accept': 'application/json'});
  final ApiAdapter _adapter;

  String get _base =>
      '${app_settings.ASODYA_API_URL}/apps/certifications/v1/quizzes';

  Future<Quiz> getCompleted(String quizId) async =>
      Quiz.fromJson(_data(await _adapter.get(Uri.parse('$_base/completed/$quizId'))));

  /// Persists a freshly finished quiz as a [Quiz] record. [quizData] carries
  /// the full question set (prompt/choices/visual plus the now-known
  /// correct_index/explanation for each), so a future shared-link visitor can
  /// be graded against the exact same quiz.
  Future<Quiz> createCompleted({
    required String title,
    String? description,
    required QuizVisibility visibility,
    required int totalQuestions,
    required Map<String, dynamic> quizData,
  }) async {
    final response = await _adapter.post(
      Uri.parse('$_base/completed'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'visibility': visibility.apiValue,
        'total_questions': totalQuestions,
        'quiz_data': quizData,
      }),
    );
    return Quiz.fromJson(_data(response));
  }

  /// Grades a shared-link visitor's answers against the answer key kept
  /// server-side, without consuming a use of the share link.
  Future<QuizGradeResult> gradeSharedAnswers(
    String token,
    Map<String, int> answers,
  ) async {
    final response = await _adapter.post(
      Uri.parse('$_base/shared/$token/grade'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'answers': [
          for (final entry in answers.entries)
            {'question_id': entry.key, 'choice_index': entry.value},
        ],
      }),
    );
    return QuizGradeResult.fromJson(_data(response));
  }

  String sharedDiagramUrl(String token, String questionId) =>
      '$_base/shared/$token/questions/$questionId/visual';

  /// Lists every completed quiz owned by the authenticated user via the real
  /// `GET /quizzes/completed` endpoint (already filters by owner server
  /// side), replacing the old workaround of deriving a quiz id from the
  /// studies list and treating a study id as a quiz id.
  Future<List<Quiz>> listCompleted() async {
    final response = await _adapter.get(Uri.parse('$_base/completed'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuizApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Quiz.fromJson)
        .toList();
  }

  Future<Quiz> updateVisibility(String quizId, QuizVisibility visibility) async =>
      Quiz.fromJson(
        _data(
          await _adapter.patch(
            Uri.parse('$_base/completed/$quizId/visibility'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'visibility': visibility.apiValue}),
          ),
        ),
      );

  /// Creates (or regenerates) a share link. [expiresInHours] must be within
  /// 1..8760 per the backend contract; pass [maxUses] (e.g. 1 for a
  /// single-use link) or leave it null for unlimited uses within the window.
  Future<QuizShare> createShare(
    String quizId, {
    int expiresInHours = 24,
    int? maxUses,
  }) async {
    final response = await _adapter.post(
      Uri.parse('$_base/completed/$quizId/share'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'expires_in_hours': expiresInHours,
        'max_uses': maxUses,
      }),
    );
    return QuizShare.fromJson(
      _data(response),
      fallbackBaseUrl: app_settings.ASODYA_API_URL,
    );
  }

  /// Deletes a completed quiz. Throws [QuizDeleteForbiddenException] when the
  /// backend returns 403 (public quiz with active third-party attempts).
  Future<void> delete(String quizId) async {
    final response = await _adapter.delete(Uri.parse('$_base/completed/$quizId'));
    if (response.statusCode == 403) throw const QuizDeleteForbiddenException();
    if (response.statusCode != 204 &&
        (response.statusCode < 200 || response.statusCode >= 300)) {
      throw QuizApiException(response.statusCode);
    }
  }

  /// Leaderboard ordered by the backend: score desc, time spent asc,
  /// completion time asc. Rank is derived from that order.
  Future<List<LeaderboardEntry>> getLeaderboard(String quizId) async {
    final response = await _adapter.get(
      Uri.parse('$_base/completed/$quizId/leaderboard'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuizApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (payload['data'] as List).cast<Map<String, dynamic>>();
    return [
      for (var i = 0; i < rows.length; i++)
        LeaderboardEntry.fromJson(rows[i], i + 1),
    ];
  }

  /// Anonymous-friendly read of a quiz behind a share token.
  Future<Map<String, dynamic>> getShared(String token) async =>
      _data(await _adapter.get(Uri.parse('$_base/shared/$token')));

  /// Records an attempt against a share token.
  Future<void> submitSharedAttempt(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final response = await _adapter.post(
      Uri.parse('$_base/shared/$token/attempt'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuizApiException(response.statusCode);
    }
  }

  Map<String, dynamic> _data(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuizApiException(response.statusCode);
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }
}
