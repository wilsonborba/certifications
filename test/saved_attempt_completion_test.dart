import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt_review.dart';
import 'package:certifications/domain/models/certificate_verification.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/presentation/widgets/attempt_review_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  int confirmCalls = 0;
  int issueCalls = 0;
  int verificationCalls = 0;
  final issuedAttemptIds = <String>[];
  bool confirmed = true;
  bool ineligible = false;
  bool retryOnce = false;

  @override
  Future<CertificateHolderIdentity> getMyIdentity() async {
    identityCalls++;
    return CertificateHolderIdentity(
      holderId: confirmed ? 'holder-1' : null,
      displayName: confirmed ? 'Ada Example' : null,
      confirmed: confirmed,
    );
  }

  @override
  Future<CertificateHolderIdentity> confirmMyIdentity(
    String displayName,
  ) async {
    confirmCalls++;
    confirmed = true;
    return CertificateHolderIdentity(
      holderId: 'holder-1',
      displayName: displayName,
      confirmed: true,
    );
  }

  @override
  Future<IssuedCertificate> issueForAttempt(String attemptId) async {
    issueCalls++;
    issuedAttemptIds.add(attemptId);
    if (ineligible) {
      throw const CertificateApiException(403, errorCode: 'private_quiz');
    }
    if (retryOnce && issueCalls == 1) {
      throw const CertificateApiException(503);
    }
    return IssuedCertificate(
      id: 'cert-1',
      verificationCode: 'CODE-1',
      holderPublicId: 'holder-public-1',
      holderName: confirmed ? 'Ada Example' : '',
      quizId: 'quiz-authoritative',
      quizTitle: 'Authoritative quiz',
      attemptId: attemptId,
      scoreCorrect: 1,
      scoreTotal: 3,
      status: 'active',
      revocationReason: '',
      issuedAt: 1760000061,
      pdfUrl: '/certificates/CODE-1/files/pdf',
      imageUrl: '/certificates/CODE-1/files/image',
    );
  }

  @override
  Future<CertificateVerification> verify(String code) async {
    verificationCalls++;
    expect(code, 'CODE-1');
    return const CertificateVerification(
      verificationCode: 'CODE-1',
      status: 'active',
      revocationReason: '',
      holderPublicId: 'holder-public-1',
      holderName: 'Ada Example',
      quizTitle: 'Authoritative quiz',
      scoreCorrect: 1,
      scoreTotal: 3,
      issuedAt: 1760000061,
      activitySummary: CertificateActivitySummary(
        focusLostCount: 0,
        pageHiddenCount: 0,
        pageReturnCount: 0,
        knownAwayMs: 0,
        reconnectCount: 0,
        refreshCount: 0,
        unknownGapCount: 0,
        completeness: 'complete',
        disclaimer: 'Observed browser activity only.',
        events: [],
      ),
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
  setUpAll(() => initializeDateFormatting());

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
      expect(
        find.widgetWithText(FilledButton, 'Issue completion certificate'),
        findsOneWidget,
      );
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

  testWidgets('saved result issues by saved id and opens verification', (
    tester,
  ) async {
    final resultsApi = _ResultsApi('completed');
    final certificateApi = _CertificateApi();
    await tester.pumpWidget(
      _app(
        AttemptResultsScreen(
          attemptId: 'attempt-saved',
          api: resultsApi,
          certificateService: certificateApi,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Issue completion certificate'),
    );
    await tester.pumpAndSettle();

    expect(certificateApi.issueCalls, 1);
    expect(certificateApi.issuedAttemptIds, ['attempt-saved']);
    expect(find.textContaining('CODE-1'), findsOneWidget);
    await tester.tap(find.text('Open verification and downloads'));
    await tester.pumpAndSettle();
    expect(certificateApi.verificationCalls, 1);
    expect(find.text('Certificate verification'), findsNWidgets(2));
    expect(find.text('Ada Example'), findsOneWidget);
  });

  testWidgets('ineligible saved attempt does not offer an issue retry', (
    tester,
  ) async {
    final certificateApi = _CertificateApi()..ineligible = true;
    await tester.pumpWidget(
      _app(
        AttemptResultsScreen(
          attemptId: 'attempt-private',
          api: _ResultsApi('completed'),
          certificateService: certificateApi,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Issue completion certificate'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('This attempt does not meet the certificate requirements.'),
      findsOneWidget,
    );
    expect(find.text('Retry certificate issue'), findsNothing);
    expect(certificateApi.issueCalls, 1);
  });

  testWidgets('retryable issuance failure retries the same saved attempt', (
    tester,
  ) async {
    final certificateApi = _CertificateApi()..retryOnce = true;
    await tester.pumpWidget(
      _app(
        AttemptResultsScreen(
          attemptId: 'attempt-saved',
          api: _ResultsApi('completed'),
          certificateService: certificateApi,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Issue completion certificate'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry certificate issue'));
    await tester.pumpAndSettle();
    expect(certificateApi.issueCalls, 2);
    expect(find.textContaining('CODE-1'), findsOneWidget);
  });
}
