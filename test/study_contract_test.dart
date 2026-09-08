import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('study contract restores source state and capacity', () {
    final study = Study.fromJson({
      'id': 'study-1', 'name': 'Physics', 'status': 'ready', 'active_size_bytes': 1024,
      'sources': [{'id':'source-1','kind':'pdf','filename':'notes.pdf','status':'ready','size_bytes':1024,'selection':{'page_start':1,'page_end':2}}],
    });
    expect(study.id, 'study-1');
    expect(study.activeSizeBytes, 1024);
    expect(study.sources.single.selection?['page_end'], 2);
  });
  test('question contract preserves visual discriminators', () {
    final question = StudyQuestion.fromJson({'id':'q1','prompt':'Formula?','choices':['A','B'],'visual':{'kind':'latex','source':'E=mc^2','description':'Mass energy'}});
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
