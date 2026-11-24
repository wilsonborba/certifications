import 'package:screen_trail/screen_trail.dart';
export 'package:screen_trail/screen_trail.dart';

/// Screen manifest for Certifications v2 (Area 10 + Area 12).
/// Uses `:param` templates required by `screen_trail`.
const certificationsScreens = <TrailScreen>[
  TrailScreen(name: 'landing', route: '/', label: 'Landing'),
  TrailScreen(name: 'catalog', route: '/v1/catalog', label: 'Quiz catalog'),
  TrailScreen(
    name: 'quiz_detail',
    route: '/v1/quizzes/:quiz_id',
    label: 'Quiz detail',
  ),
  TrailScreen(
    name: 'public_quiz_statistics',
    route: '/v1/quizzes/:quiz_id/statistics',
    label: 'Public quiz statistics',
    sensitivePath: true,
  ),
  TrailScreen(
    name: 'dashboard',
    route: '/v1/dashboard',
    label: 'Personal dashboard',
  ),
  TrailScreen(name: 'studies', route: '/v1/studies', label: 'My studies'),
  TrailScreen(name: 'study_new', route: '/v1/studies/new', label: 'New study'),
  TrailScreen(
    name: 'study_detail',
    route: '/v1/studies/:study_id',
    label: 'Study preparation',
  ),
  TrailScreen(
    name: 'generation',
    route: '/v1/generations/:generation_id',
    label: 'Generation progress',
  ),
  TrailScreen(
    name: 'study_questions',
    route: '/v1/studies/:study_id/questions',
    label: 'Question review',
  ),
  TrailScreen(
    name: 'attempt',
    route: '/v1/attempts/:attempt_id',
    label: 'Quiz attempt',
  ),
  TrailScreen(
    name: 'attempt_results',
    route: '/v1/attempts/:attempt_id/results',
    label: 'Attempt results',
  ),
  TrailScreen(name: 'history', route: '/v1/history', label: 'Attempt history'),
  TrailScreen(
    name: 'certificate',
    route: '/v1/certificates/:certificate_code',
    label: 'Certificate verification',
  ),
  TrailScreen(
    name: 'shared_quiz',
    route: '/quizzes/shared/:token',
    label: 'Shared quiz',
    sensitivePath: true,
  ),
  TrailScreen(name: 'plans', route: '/plans', label: 'Plans'),
  TrailScreen(
    name: 'sync',
    route: '/sync',
    label: 'Session sync',
    sensitivePath: true,
  ),
];

/// Segment tokens marked sensitive under Area 12 (values omitted from telemetry).
const Set<String> certificationsSensitiveSegments = {
  'source_text',
  'question_fields',
  'question_prompt',
  'question_option',
  'question_explanation',
  'quiz_responses',
  'support_body',
  'filename',
  'private_link',
};

/// Matches dotted element IDs (e.g. `study_new.source_text.input`) against Area 12 sensitive kinds.
bool isSensitiveTelemetryField(String elementId) {
  final parts = elementId.split('.');
  return parts.any(certificationsSensitiveSegments.contains);
}

/// Domain helper that all Certifications input events go through so Area 12
/// sensitive fields always pass `sensitive: true` to [ScreenTrail].
void recordCertificationsInput(
  ScreenTrail tracker,
  TrailElement element,
  String value,
) {
  tracker.event(
    'input',
    element,
    value: value,
    sensitive: isSensitiveTelemetryField(element.id),
  );
}
