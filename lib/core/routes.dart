/// Accepted Certifications v2 frontend screen routes (Area 10).
enum CertificationsScreen {
  landing,
  catalog,
  quizDetail,
  publicQuizStatistics,
  dashboard,
  studies,
  studyNew,
  studyDetail,
  generation,
  studyQuestions,
  attempt,
  attemptResults,
  history,
  certificate,
  syncAuth,
  plans,
  sharedQuiz,
}

class CertificationsRoute {
  final CertificationsScreen screen;
  final String routeTemplate;
  final String? id;
  final Map<String, String> queryParameters;

  const CertificationsRoute({
    required this.screen,
    required this.routeTemplate,
    this.id,
    this.queryParameters = const {},
  });

  bool get requiresAuth => switch (screen) {
    CertificationsScreen.dashboard ||
    CertificationsScreen.studies ||
    CertificationsScreen.studyNew ||
    CertificationsScreen.studyDetail ||
    CertificationsScreen.generation ||
    CertificationsScreen.studyQuestions ||
    CertificationsScreen.attempt ||
    CertificationsScreen.attemptResults ||
    CertificationsScreen.history => true,
    _ => false,
  };

  static CertificationsRoute parse(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final qp = uri.queryParameters;

    if (segs.isEmpty) {
      return CertificationsRoute(
        screen: CertificationsScreen.landing,
        routeTemplate: '/',
        queryParameters: qp,
      );
    }

    if (segs.length == 1 && segs[0] == 'sync') {
      return CertificationsRoute(
        screen: CertificationsScreen.syncAuth,
        routeTemplate: '/sync',
        queryParameters: qp,
      );
    }
    if (segs.length == 1 && segs[0] == 'plans') {
      return CertificationsRoute(
        screen: CertificationsScreen.plans,
        routeTemplate: '/plans',
        queryParameters: qp,
      );
    }
    if (segs.length >= 3 && segs[0] == 'quizzes' && segs[1] == 'shared') {
      return CertificationsRoute(
        screen: CertificationsScreen.sharedQuiz,
        routeTemplate: '/quizzes/shared/:token',
        id: segs[2],
        queryParameters: qp,
      );
    }

    if (segs[0] == 'v1') {
      if (segs.length == 2) {
        switch (segs[1]) {
          case 'catalog':
            return CertificationsRoute(
              screen: CertificationsScreen.catalog,
              routeTemplate: '/v1/catalog',
              queryParameters: qp,
            );
          case 'dashboard':
            return CertificationsRoute(
              screen: CertificationsScreen.dashboard,
              routeTemplate: '/v1/dashboard',
              queryParameters: qp,
            );
          case 'studies':
            return CertificationsRoute(
              screen: CertificationsScreen.studies,
              routeTemplate: '/v1/studies',
              queryParameters: qp,
            );
          case 'history':
            return CertificationsRoute(
              screen: CertificationsScreen.history,
              routeTemplate: '/v1/history',
              queryParameters: qp,
            );
        }
      } else if (segs.length == 3) {
        final resource = segs[1];
        final param = segs[2];
        switch (resource) {
          case 'quizzes':
            return CertificationsRoute(
              screen: CertificationsScreen.quizDetail,
              routeTemplate: '/v1/quizzes/:quiz_id',
              id: param,
              queryParameters: qp,
            );
          case 'studies':
            if (param == 'new') {
              return CertificationsRoute(
                screen: CertificationsScreen.studyNew,
                routeTemplate: '/v1/studies/new',
                queryParameters: qp,
              );
            }
            return CertificationsRoute(
              screen: CertificationsScreen.studyDetail,
              routeTemplate: '/v1/studies/:study_id',
              id: param,
              queryParameters: qp,
            );
          case 'generations':
            return CertificationsRoute(
              screen: CertificationsScreen.generation,
              routeTemplate: '/v1/generations/:generation_id',
              id: param,
              queryParameters: qp,
            );
          case 'attempts':
            return CertificationsRoute(
              screen: CertificationsScreen.attempt,
              routeTemplate: '/v1/attempts/:attempt_id',
              id: param,
              queryParameters: qp,
            );
          case 'certificates':
            return CertificationsRoute(
              screen: CertificationsScreen.certificate,
              routeTemplate: '/v1/certificates/:certificate_code',
              id: param,
              queryParameters: qp,
            );
        }
      } else if (segs.length == 4) {
        if (segs[1] == 'quizzes' && segs[3] == 'statistics') {
          return CertificationsRoute(
            screen: CertificationsScreen.publicQuizStatistics,
            routeTemplate: '/v1/quizzes/:quiz_id/statistics',
            id: segs[2],
            queryParameters: qp,
          );
        }
        if (segs[1] == 'studies' && segs[3] == 'questions') {
          return CertificationsRoute(
            screen: CertificationsScreen.studyQuestions,
            routeTemplate: '/v1/studies/:study_id/questions',
            id: segs[2],
            queryParameters: qp,
          );
        }
        if (segs[1] == 'attempts' && segs[3] == 'results') {
          return CertificationsRoute(
            screen: CertificationsScreen.attemptResults,
            routeTemplate: '/v1/attempts/:attempt_id/results',
            id: segs[2],
            queryParameters: qp,
          );
        }
      }
    }

    return CertificationsRoute(
      screen: CertificationsScreen.landing,
      routeTemplate: '/',
      queryParameters: qp,
    );
  }
}
