import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('study contract restores source state and capacity', () {
    final study = Study.fromJson({
      'id': 'study-1',
      'name': 'Physics',
      'status': 'ready',
      'active_size_bytes': 1024,
      'sources': [
        {
          'id': 'source-1',
          'kind': 'pdf',
          'filename': 'notes.pdf',
          'status': 'ready',
          'size_bytes': 1024,
          'selection': {'page_start': 1, 'page_end': 2},
        },
      ],
    });
    expect(study.id, 'study-1');
    expect(study.activeSizeBytes, 1024);
    expect(study.sources.single.selection?['page_end'], 2);
  });
  test('study quota fields remain nullable and parse backend byte totals', () {
    final study = Study.fromJson({
      'id': 'study-2',
      'name': 'Biology',
      'status': 'draft',
      'active_size_bytes': 12,
      'account_used_bytes': 345,
      'account_max_bytes': 1000,
      'retained_size_bytes': 400,
    });
    expect(study.accountUsedBytes, 345);
    expect(study.accountMaxBytes, 1000);
    expect(study.retainedSizeBytes, 400);
    final unknown = Study.fromJson({
      'id': 'study-3',
      'name': 'Chemistry',
      'status': 'draft',
      'active_size_bytes': 0,
    });
    expect(unknown.accountUsedBytes, isNull);
    expect(unknown.accountMaxBytes, isNull);
  });
  test('wizard quota never invents a limit and counts pending files', () {
    final data = QuizWizardData();
    expect(data.wouldExceedAccountQuota(50), isFalse);
    data.attachedFiles.add(
      AttachedFile(bytes: List.filled(5, 0), name: 'notes.txt', kind: 'txt'),
    );
    data.setAccountQuota(usedBytes: 80, maxBytes: 100);
    expect(data.wouldExceedAccountQuota(15), isFalse);
    expect(data.wouldExceedAccountQuota(16), isTrue);
    expect(data.projectedAccountUsageBytes, 85);
    data.dispose();
  });
  test('question contract preserves visual discriminators', () {
    final question = StudyQuestion.fromJson({
      'id': 'q1',
      'prompt': 'Formula?',
      'choices': ['A', 'B'],
      'visual': {
        'kind': 'latex',
        'source': 'E=mc^2',
        'description': 'Mass energy',
      },
    });
    expect(question.visual['kind'], 'latex');
    expect(question.choices, hasLength(2));
  });
  test('all application locales contain critical study labels', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final copy = AppLocalizations(locale);
      expect(copy.text('newStudy'), isNotEmpty);
      expect(copy.text('errorGeneric'), isNotEmpty);
      expect(copy.text('generate'), isNotEmpty);
    }
    expect(AppLocalizations(const Locale('xx')).text('newStudy'), isNotEmpty);
  });
}
