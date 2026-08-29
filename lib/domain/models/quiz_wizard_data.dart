import 'package:flutter/foundation.dart';

enum SourceType { aiGeneral, uploadFile, webSearch }

enum DifficultyLevel { easy, medium, hard }

class QuizWizardData extends ChangeNotifier {
  int currentStep = 0;
  String name = '';
  String categoryPreset = '';
  SourceType sourceType = SourceType.aiGeneral;
  List<int>? fileBytes;
  String? fileName;
  String? fileKind;
  DifficultyLevel difficulty = DifficultyLevel.medium;
  int questionCount = 10;
  bool useWebSearch = false;

  // Granular range selection
  bool isWholeDocument = true;
  int pageStart = 1;
  int pageEnd = 10;
  int lineStart = 1;
  int lineEnd = 50;
  int audioStartMs = 0;
  int audioEndMs = 300000; // 5 minutes default

  bool get isStep1Valid => name.trim().isNotEmpty || categoryPreset.isNotEmpty;
  bool get isStep2Valid => sourceType != SourceType.uploadFile || fileBytes != null;
  bool get isStep3Valid => true;
  bool get isStep4Valid => isStep1Valid && isStep2Valid && isStep3Valid;

  void setStep(int step) {
    if (step >= 0 && step <= 3) {
      currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (currentStep < 3) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void selectCategoryPreset(String preset) {
    categoryPreset = preset;
    name = preset;
    notifyListeners();
  }

  void setSourceType(SourceType type) {
    sourceType = type;
    notifyListeners();
  }

  void setFile({required List<int> bytes, required String name, required String kind}) {
    fileBytes = bytes;
    fileName = name;
    fileKind = kind;
    notifyListeners();
  }

  void reset() {
    currentStep = 0;
    name = '';
    categoryPreset = '';
    sourceType = SourceType.aiGeneral;
    fileBytes = null;
    fileName = null;
    fileKind = null;
    difficulty = DifficultyLevel.medium;
    questionCount = 10;
    useWebSearch = false;
    isWholeDocument = true;
    pageStart = 1;
    pageEnd = 10;
    lineStart = 1;
    lineEnd = 50;
    audioStartMs = 0;
    audioEndMs = 300000;
    notifyListeners();
  }
}
