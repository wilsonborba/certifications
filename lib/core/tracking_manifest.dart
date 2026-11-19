import 'package:screen_trail/screen_trail.dart';
export 'package:screen_trail/screen_trail.dart';

/// Screen manifest for Certifications v2 (Area 10 + Area 12).
///
/// Sensitive fields per Area 12 (`source_text`, `question_fields`, `quiz_responses`,
/// `support_body`, `filename`, `private_link`) are marked sensitive so typed values
/// are never recorded in telemetry payloads.
const certificationsScreens = <TrailScreen>[
  TrailScreen(name: 'landing', route: '/', label: 'Landing'),
  TrailScreen(name: 'catalog', route: '/v1/catalog', label: 'Quiz catalog'),
  TrailScreen(name: 'quiz_detail', route: '/v1/quizzes/{quiz_id}', label: 'Quiz detail'),
  TrailScreen(name: 'dashboard', route: '/v1/dashboard', label: 'Personal dashboard'),
  TrailScreen(name: 'studies', route: '/v1/studies', label: 'My studies'),
  TrailScreen(name: 'study_new', route: '/v1/studies/new', label: 'New study'),
  TrailScreen(name: 'study_detail', route: '/v1/studies/{study_id}', label: 'Study preparation'),
  TrailScreen(name: 'generation', route: '/v1/generations/{generation_id}', label: 'Generation progress'),
  TrailScreen(name: 'study_questions', route: '/v1/studies/{study_id}/questions', label: 'Question review'),
  TrailScreen(name: 'attempt', route: '/v1/attempts/{attempt_id}', label: 'Quiz attempt'),
  TrailScreen(name: 'attempt_results', route: '/v1/attempts/{attempt_id}/results', label: 'Attempt results'),
  TrailScreen(name: 'history', route: '/v1/history', label: 'Attempt history'),
  TrailScreen(name: 'certificate', route: '/v1/certificates/{certificate_code}', label: 'Certificate verification'),
];

/// Element IDs marked sensitive under Area 12 (values omitted from telemetry).
const Set<String> certificationsSensitiveFieldIds = {
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

bool isSensitiveTelemetryField(String elementId) =>
    certificationsSensitiveFieldIds.contains(elementId);
