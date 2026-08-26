import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  static const supportedLocales = [Locale('en'), Locale('pt'), Locale('th')];
  static const _copy = {
    'en': {
      'appName': 'Certifications',
      'welcomeTitle': 'Turn material into mastery.',
      'welcomeBody': 'Build a focused study from the material you choose.',
      'signIn': 'Sign in',
      'openStudies': 'Open studies',
      'newStudy': 'New study',
      'studyName': 'Study name',
      'createStudy': 'Create study',
      'yourStudies': 'Your studies',
      'noStudies': 'No studies yet',
      'continueStudy': 'Continue',
      'addSource': 'Add source',
      'upload': 'Upload',
      'pdf': 'PDF',
      'audio': 'Audio',
      'text': 'Text',
      'selectRange': 'Select range',
      'process': 'Process source',
      'ready': 'Ready',
      'processing': 'Processing',
      'generate': 'Generate questions',
      'useWeb': 'Use web research',
      'useWebDescription':
          'Allow this quiz generation to use web research when needed.',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'theme': 'Theme',
      'language': 'Language',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'remaining': 'Remaining',
      'delete': 'Delete',
      'complete': 'Complete study',
      'errorGeneric': 'Something went wrong. Please try again.',
      'retry': 'Retry',
      'loading': 'Loading…',
      'question': 'Question',
      'next': 'Next',
      'finish': 'Finish',
      'diagramUnavailable': 'Diagram unavailable',
      'studyComplete': 'Study completed',
      'memory': 'Study memory',
    },
    'pt': {
      'appName': 'Certifications',
      'welcomeTitle': 'Transforme material em domínio.',
      'welcomeBody': 'Crie um estudo focado com o material que você escolher.',
      'signIn': 'Entrar',
      'openStudies': 'Abrir estudos',
      'newStudy': 'Novo estudo',
      'studyName': 'Nome do estudo',
      'createStudy': 'Criar estudo',
      'yourStudies': 'Seus estudos',
      'noStudies': 'Nenhum estudo ainda',
      'continueStudy': 'Continuar',
      'addSource': 'Adicionar fonte',
      'upload': 'Enviar',
      'pdf': 'PDF',
      'audio': 'Áudio',
      'text': 'Texto',
      'selectRange': 'Selecionar trecho',
      'process': 'Processar fonte',
      'ready': 'Pronto',
      'processing': 'Processando',
      'generate': 'Gerar perguntas',
      'useWeb': 'Usar pesquisa na web',
      'useWebDescription':
          'Permite que esta geração use pesquisa na web quando necessário.',
      'easy': 'Fácil',
      'medium': 'Médio',
      'hard': 'Difícil',
      'theme': 'Tema',
      'language': 'Idioma',
      'system': 'Sistema',
      'light': 'Claro',
      'dark': 'Escuro',
      'remaining': 'Restante',
      'delete': 'Excluir',
      'complete': 'Concluir estudo',
      'errorGeneric': 'Algo deu errado. Tente novamente.',
      'retry': 'Tentar novamente',
      'loading': 'Carregando…',
      'question': 'Pergunta',
      'next': 'Próxima',
      'finish': 'Finalizar',
      'diagramUnavailable': 'Diagrama indisponível',
      'studyComplete': 'Estudo concluído',
      'memory': 'Memória do estudo',
    },
    'th': {
      'appName': 'Certifications',
      'welcomeTitle': 'เปลี่ยนเนื้อหาให้เป็นความเชี่ยวชาญ',
      'welcomeBody': 'สร้างการเรียนรู้ที่มีสมาธิจากเนื้อหาที่คุณเลือก',
      'signIn': 'เข้าสู่ระบบ',
      'openStudies': 'เปิดการเรียน',
      'newStudy': 'การเรียนใหม่',
      'studyName': 'ชื่อการเรียน',
      'createStudy': 'สร้างการเรียน',
      'yourStudies': 'การเรียนของคุณ',
      'noStudies': 'ยังไม่มีการเรียน',
      'continueStudy': 'ดำเนินการต่อ',
      'addSource': 'เพิ่มแหล่งข้อมูล',
      'upload': 'อัปโหลด',
      'pdf': 'PDF',
      'audio': 'เสียง',
      'text': 'ข้อความ',
      'selectRange': 'เลือกช่วง',
      'process': 'ประมวลผลแหล่งข้อมูล',
      'ready': 'พร้อม',
      'processing': 'กำลังประมวลผล',
      'generate': 'สร้างคำถาม',
      'useWeb': 'ใช้การค้นหาบนเว็บ',
      'useWebDescription':
          'อนุญาตให้การสร้างแบบทดสอบนี้ใช้การค้นหาบนเว็บเมื่อจำเป็น',
      'easy': 'ง่าย',
      'medium': 'ปานกลาง',
      'hard': 'ยาก',
      'theme': 'ธีม',
      'language': 'ภาษา',
      'system': 'ระบบ',
      'light': 'สว่าง',
      'dark': 'มืด',
      'remaining': 'คงเหลือ',
      'delete': 'ลบ',
      'complete': 'เรียนจบ',
      'errorGeneric': 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง',
      'retry': 'ลองอีกครั้ง',
      'loading': 'กำลังโหลด…',
      'question': 'คำถาม',
      'next': 'ถัดไป',
      'finish': 'เสร็จสิ้น',
      'diagramUnavailable': 'แผนภาพไม่พร้อมใช้งาน',
      'studyComplete': 'เรียนจบแล้ว',
      'memory': 'ความจำการเรียน',
    },
  };
  String text(String key) =>
      _copy[locale.languageCode]?[key] ?? _copy['en']![key] ?? key;
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension Translation on BuildContext {
  String tr(String key) => AppLocalizations.of(this).text(key);
}
