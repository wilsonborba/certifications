import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt_review.dart';
import 'package:certifications/domain/models/certificate_verification.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/presentation/widgets/attempt_review_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ResultsApi extends AttemptReviewApiService {
  _ResultsApi(this.status);
  final String status;
  final requestedIds = <String>[];

  @override
  Future<AttemptResults> getResults(String attemptId) async {
    requestedIds.add(attemptId);
    return AttemptResults(
      id: attemptId,
      quizId: 'quiz-authoritative',
      quizVersionId: 'version-1',
      status: status,
      scoreCorrect: 1,
      scoreTotal: 3,
      startedAt: 1760000000,
      completedAt: status == 'completed' ? 1760000060 : null,
      stats: const {},
      activitySummary: const {'completeness': 'partial'},
      questions: const [],
    );
  }
}

class _CertificateApi extends CertificateVerificationApiService {
  int identityCalls = 0;

  @override
  Future<CertificateHolderIdentity> getMyIdentity() async {
    identityCalls++;
    return const CertificateHolderIdentity(
      holderId: null,
      displayName: null,
      confirmed: false,
    );
  }
}

Widget _app(Widget child) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: child!,
  ),
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),
    FallbackMaterialLocalizationsDelegate(),
    DefaultWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets(
    'completed result uses GET payload and offers issuance by saved id',
    (tester) async {
      final resultsApi = _ResultsApi('completed');
      final certificateApi = _CertificateApi();
      await tester.pumpWidget(
        _app(
          AttemptResultsScreen(
            attemptId: 'attempt-actual',
            api: resultsApi,
            certificateService: certificateApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(resultsApi.requestedIds, ['attempt-actual']);
      expect(find.text('33.3%'), findsOneWidget);
      expect(find.text('Issue completion certificate'), findsOneWidget);
      expect(certificateApi.identityCalls, 1);
    },
  );

  testWidgets('non-completed attempt results do not offer issuance', (
    tester,
  ) async {
    final resultsApi = _ResultsApi('in_progress');
    final certificateApi = _CertificateApi();
    await tester.pumpWidget(
      _app(
        AttemptResultsScreen(
          attemptId: 'attempt-in-progress',
          api: resultsApi,
          certificateService: certificateApi,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Issue completion certificate'), findsNothing);
    expect(certificateApi.identityCalls, 0);
  });
}
