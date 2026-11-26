import 'dart:async';

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
  final saveRequests = <Map<String, String>>[];
  final events = <AttemptActivityEvent>[];
  final eventBatches = <List<AttemptActivityEvent>>[];
  Completer<void>? saveGate;
  Completer<Map<String, dynamic>>? submitGate;

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
    saveRequests.add({
      'questionId': questionId,
      'selectedOptionId': selectedOptionId,
    });
    await saveGate?.future;
    saves[questionId] = selectedOptionId;
  }

  @override
  Future<int> recordActivityEvents({
    required String attemptId,
    required List<AttemptActivityEvent> events,
  }) async {
    eventBatches.add(List.unmodifiable(events));
    this.events.addAll(events);
    return events.length;
  }

  @override
  Future<Map<String, dynamic>> submitAttempt(String attemptId) async {
    submitCalls++;
    final gate = submitGate;
    if (gate != null) return gate.future;
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

  testWidgets('declining authentication allows an explicit start retry', (
    tester,
  ) async {
    final api = _AttemptApi();
    var authenticationCalls = 0;
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
        home: AttemptStartScreen(
          quizId: 'quiz-1',
          api: api,
          authenticate: (_) async => ++authenticationCalls > 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start quiz'));
    await tester.pump();
    expect(api.startCalls, 0);
    expect(authenticationCalls, 1);
    final startButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start quiz'),
    );
    expect(startButton.onPressed, isNotNull);

    await tester.tap(find.text('Start quiz'));
    await tester.pumpAndSettle();
    expect(authenticationCalls, 2);
    expect(api.startCalls, 1);
    expect(find.text('Prompt 1'), findsOneWidget);
  });

  testWidgets('late authentication completion after disposal does not start', (
    tester,
  ) async {
    final api = _AttemptApi();
    final authentication = Completer<bool>();
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
        home: AttemptStartScreen(
          quizId: 'quiz-1',
          api: api,
          authenticate: (_) => authentication.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quiz'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    authentication.complete(true);
    await tester.pump();
    expect(api.startCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late answer-save completion after disposal is harmless', (
    tester,
  ) async {
    final api = _AttemptApi()..saveGate = Completer<void>();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option B').first);
    await tester.pump();
    expect(api.saveRequests, [
      {'questionId': 'question-1', 'selectedOptionId': 'option-b'},
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    api.saveGate!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
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

  testWidgets('answer writes are locked while submit is pending', (
    tester,
  ) async {
    final api = _AttemptApi()..submitGate = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit').last);
    await tester.pump();

    expect(api.submitCalls, 1);
    expect(api.saveRequests, isEmpty);
    await tester.tap(find.text('Option A').last);
    await tester.pump();
    expect(api.saveRequests, isEmpty);

    api.submitGate!.complete(const {'status': 'submitted'});
    await tester.pumpAndSettle();
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

  testWidgets('focus-only absence records one loss, duration and return', (
    tester,
  ) async {
    final api = _AttemptApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(api.events.map((event) => event.eventKind), [
      'focus_lost',
      'away_duration',
      'page_return',
    ]);
    expect(api.events[1].durationMs, greaterThan(0));
    expect(api.events[0].durationMs, 0);
    expect(api.events[2].durationMs, 0);
    expect(api.events.map((event) => event.dedupKey).toSet(), hasLength(3));
  });

  testWidgets('inactive and hidden notifications form one measured episode', (
    tester,
  ) async {
    final api = _AttemptApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    expect(api.events, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(api.events.map((event) => event.eventKind), [
      'focus_lost',
      'page_hidden',
      'away_duration',
      'page_return',
    ]);
    expect(api.eventBatches, hasLength(1));
    expect(api.events[0].durationMs, 0);
    expect(api.events[1].durationMs, 0);
    expect(api.events[2].durationMs, greaterThan(0));
    expect(api.events[3].durationMs, 0);
    expect(api.events.map((event) => event.dedupKey).toSet(), hasLength(4));
  });
}
