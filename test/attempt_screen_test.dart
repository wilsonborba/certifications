import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt.dart';
import 'package:certifications/domain/services/attempt_api_service.dart';
import 'package:certifications/presentation/widgets/quiz/attempt_screen.dart';
import 'package:certifications/presentation/widgets/quiz/attempt_start_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AttemptApi extends AttemptApiService {
  int getCalls = 0;
  int startCalls = 0;
  int submitCalls = 0;
  bool completed = false;
  final saves = <String, String>{};
  final events = <AttemptActivityEvent>[];

  @override
  Future<AttemptView> getAttempt(String attemptId) async {
    getCalls++;
    return _view(saves);
  }

  @override
  Future<AttemptView> startAttempt(String quizId) async {
    startCalls++;
    return _view(saves);
  }

  @override
  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required String selectedOptionId,
  }) async {
    saves[questionId] = selectedOptionId;
  }

  @override
  Future<int> recordActivityEvents({
    required String attemptId,
    required List<AttemptActivityEvent> events,
  }) async {
    this.events.addAll(events);
    return events.length;
  }

  @override
  Future<Map<String, dynamic>> submitAttempt(String attemptId) async {
    submitCalls++;
    return const {'status': 'submitted'};
  }

  AttemptView _view(Map<String, String> answers) => AttemptView(
    id: 'attempt-1',
    quizId: 'quiz-1',
    quizVersionId: 'version-1',
    status: completed ? 'completed' : 'in_progress',
    startedAt: 1760000000,
    monitoringNotice: 'This page visibility may be recorded.',
    questions: [
      for (var i = 1; i <= 2; i++)
        AttemptQuestion(
          questionId: 'question-$i',
          questionVersionId: 'question-version-$i',
          language: 'en',
          origin: 'creator',
          prompt: 'Prompt $i',
          alternatives: const [
            {'id': 'option-a', 'text': 'Option A'},
            {'id': 'option-b', 'text': 'Option B'},
          ],
          selectedOptionId: answers['question-$i'],
        ),
    ],
  );
}

class _RouteRecorder extends NavigatorObserver {
  String? replacedRouteName;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedRouteName = newRoute?.settings.name;
  }
}

Widget _app(AttemptApiService api, {Key? key, NavigatorObserver? observer}) =>
    MaterialApp(
      key: key,
      navigatorObservers: [if (observer != null) observer],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => settings.name?.endsWith('/results') == true
            ? const Scaffold(body: Text('Authoritative result route'))
            : AttemptScreen(attemptId: 'attempt-1', api: api),
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AttemptScreen(attemptId: 'attempt-1', api: api),
    );

void main() {
  testWidgets('shows the activity notice before any attempt is started', (
    tester,
  ) async {
    final api = _AttemptApi();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackMaterialLocalizationsDelegate(),
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AttemptStartScreen(quizId: 'quiz-1', api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('When you return, the app records'),
      findsOneWidget,
    );
    expect(find.text('Start quiz'), findsOneWidget);
    expect(api.startCalls, 0);
    expect(api.getCalls, 0);
  });

  testWidgets('opening resumes with GET and never starts a second attempt', (
    tester,
  ) async {
    final api = _AttemptApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(api.getCalls, 1);
    expect(api.startCalls, 0);
    expect(find.text('Prompt 1'), findsOneWidget);
    expect(find.textContaining('answer key'), findsNothing);

    await tester.tap(find.text('Option B').first);
    await tester.pumpAndSettle();
    expect(api.saves, {'question-1': 'option-b'});

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Prompt 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(api.getCalls, 2);
    expect(api.startCalls, 0);
    expect(api.saves['question-1'], 'option-b');
  });

  testWidgets(
    'explicit start creates once and opens a refreshable attempt URL',
    (tester) async {
      final api = _AttemptApi();
      final routes = _RouteRecorder();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routes],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackMaterialLocalizationsDelegate(),
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AttemptStartScreen(
            quizId: 'quiz-1',
            api: api,
            authenticate: (_) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start quiz'));
      await tester.pumpAndSettle();

      expect(api.startCalls, 1);
      expect(api.getCalls, 1);
      expect(routes.replacedRouteName, '/v1/attempts/attempt-1');
      expect(find.text('Prompt 1'), findsOneWidget);

      await tester.pumpWidget(_app(api, key: const ValueKey('page-reload')));
      await tester.pumpAndSettle();
      expect(api.startCalls, 1);
      expect(api.getCalls, 2);
      expect(find.text('Prompt 1'), findsOneWidget);
    },
  );

  testWidgets('submit requires confirmation then opens results by saved id', (
    tester,
  ) async {
    final api = _AttemptApi();
    final routes = _RouteRecorder();
    await tester.pumpWidget(_app(api, observer: routes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(api.submitCalls, 0);
    expect(find.text('Submit attempt?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(api.submitCalls, 0);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit').last);
    await tester.pumpAndSettle();

    expect(api.submitCalls, 1);
    expect(routes.replacedRouteName, '/v1/attempts/attempt-1/results');
    expect(find.text('Authoritative result route'), findsOneWidget);
  });

  testWidgets('opening a completed saved attempt resumes to GET results', (
    tester,
  ) async {
    final api = _AttemptApi()..completed = true;
    final routes = _RouteRecorder();
    await tester.pumpWidget(_app(api, observer: routes));
    await tester.pumpAndSettle();

    expect(api.getCalls, 1);
    expect(api.startCalls, 0);
    expect(api.submitCalls, 0);
    expect(routes.replacedRouteName, '/v1/attempts/attempt-1/results');
    expect(find.text('Authoritative result route'), findsOneWidget);
  });

  testWidgets('records a deduplicated hidden and return observation', (
    tester,
  ) async {
    final api = _AttemptApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(api.events, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    final hidden = api.events.where(
      (event) => event.eventKind == 'page_hidden',
    );
    final returned = api.events.where(
      (event) => event.eventKind == 'page_return',
    );
    expect(hidden, hasLength(1));
    expect(returned, hasLength(1));
    expect(returned.single.durationMs, hidden.single.durationMs);
  });
}
