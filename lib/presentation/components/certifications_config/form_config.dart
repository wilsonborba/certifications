import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:flutter/material.dart';



/// A complete, reusable form widget.
/// Place it anywhere (e.g., inside a Column). Call [onSubmit] to receive data.
class CertificationForm extends StatefulWidget {
  const CertificationForm({
    Key? key,
    this.onSubmit,
    this.purple = const Color(0xFF7C4DFF),
    this.pages = 10, // fixed for now (disabled field)
    this.languages = const [
      'English',
      'Português',
      'Español',
      'Français',
      'Deutsch',
      'ไทย',
      '日本語',
      '한국어',
      '中文 (简体)',
      '中文 (繁體)',
      'हिन्दी',  
      'العربية',
    ],
    this.fullNameMaxLen = 60,
    this.titleMaxLen = 50,
  }) : super(key: key);

  final ValueChanged<CertificationFormData>? onSubmit;
  final Color purple;

  /// Disabled, displayed as read-only; minutes = pages * 2 (read-only).
  final int pages;

  /// Languages to choose from (mandatory).
  final List<String> languages;

  /// Reasonable max lengths.
  final int fullNameMaxLen;
  final int titleMaxLen;

  @override
  State<CertificationForm> createState() => _CertificationFormState();
}

class _CertificationFormState extends State<CertificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // live enable/disable of button
    _fullNameCtrl.addListener(_onAnyChange);
    _titleCtrl.addListener(_onAnyChange);
    _phoneCtrl.addListener(_onAnyChange);
  }

  @override
  void dispose() {
    _fullNameCtrl.removeListener(_onAnyChange);
    _titleCtrl.removeListener(_onAnyChange);
    _phoneCtrl.removeListener(_onAnyChange);
    _fullNameCtrl.dispose();
    _titleCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onAnyChange() => setState(() {});

  int get _minutes => widget.pages * 1;

  // E.164 global phone validator: + followed by 7–15 digits
  bool _isValidE164(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    final re = RegExp(r'^\+[0-9]{7,15}$');
    return re.hasMatch(trimmed);
  }

  bool get _isFormSemanticallyValid {
    final name = _fullNameCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    final nameOk = name.isNotEmpty && name.length <= widget.fullNameMaxLen;
    final titleOk = title.isNotEmpty && title.length <= widget.titleMaxLen;
    final langOk = _selectedLanguage != null && _selectedLanguage!.isNotEmpty;

    // phone is optional; if present, must be valid E.164
    final phoneOk = phone.isEmpty || _isValidE164(phone);

    return nameOk && titleOk && phoneOk && langOk;
  }

  InputDecoration _filledDecoration({
    required String labelText,
    String? hintText,
    Widget? suffix,
  }) {
    return InputDecoration(
      label: _buildLabel(labelText),
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
        
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      suffixIcon: suffix,
      counterText: '', // hide built-in counter when using maxLength
      focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF7C4DFF), // your purple when clicked
        width: 2,
      ),
    ),
    );
  }

  // Builds a label like: "Full Name (mandatory)" with colored tag.
    Widget _buildLabel(String labelText) {
      Color optColor = widget.purple;

      bool conditionalLabel = labelText.contains('Full Name') ||
          labelText.contains('Certification Title') ||
          labelText.contains('Language');
      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          children: [
            TextSpan(text: labelText),
            if (conditionalLabel)
              const TextSpan(
                text: ' ',
              ),
            if (conditionalLabel)
              const TextSpan(
                text: '(mandatory)',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
            if (!conditionalLabel)
              TextSpan(
                text: ' (Optional)',
                style: TextStyle(color: optColor, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutesStr = _minutes.toString();

    final buttonEnabled = _isFormSemanticallyValid;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: buttonEnabled ? widget.purple : Colors.grey.shade300,
      foregroundColor: buttonEnabled ? Colors.white : Colors.black45,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: buttonEnabled ? 2 : 0,
    );

    double gapHeightSpace = 20;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth < 560 ? constraints.maxWidth : 520.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full Name (mandatory)
                  TextFormField(
                    controller: _fullNameCtrl,
                    maxLength: widget.fullNameMaxLen,
                    textInputAction: TextInputAction.next,
                    decoration: _filledDecoration(
                      labelText: 'Full Name',
                      hintText: 'James O’Neill',
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Full name is required';
                      if (s.length > widget.fullNameMaxLen) {
                        return 'Must be ≤ ${widget.fullNameMaxLen} characters';
                      }
                      return null;
                    },
                  ),
                   SizedBox(height: gapHeightSpace),

                  // Certification Title (mandatory)
                  TextFormField(
                    controller: _titleCtrl,
                    maxLength: widget.titleMaxLen,
                    textInputAction: TextInputAction.next,
                    decoration: _filledDecoration(
                      labelText: 'Certification Title',
                      hintText: 'Sugar Mommy/Daddy Professional',
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Certification title is required';
                      if (s.length > widget.titleMaxLen) {
                        return 'Must be ≤ ${widget.titleMaxLen} characters';
                      }
                      return null;
                    },
                  ),
                   SizedBox(height: gapHeightSpace),

                  // Phone (optional, E.164)
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _filledDecoration(
                      labelText: 'Phone number',
                      hintText: '+55 00 00000 0000',
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null; // optional
                      if (!_isValidE164(s)) {
                        return 'Use international format, e.g. +14155552671';
                      }
                      return null;
                    },
                  ),
                   SizedBox(height: gapHeightSpace),

                  //Language (mandatory) - dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    items: widget.languages
                        .map(
                          (lang) => DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          ),
                        )
                        .toList(),
                    decoration: _filledDecoration(
                      labelText: 'Language',
                      hintText: 'Select a language',
                    ),
                    onChanged: (v) {
                      setState(() => _selectedLanguage = v);
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Please select a language' : null,
                  ),
                   SizedBox(height: gapHeightSpace),

                  // Amount of Page (disabled, fixed)
                  TextFormField(
                    enabled: false,
                    controller: TextEditingController(
                      text: widget.pages.toString(),
                    ),
                    decoration: _filledDecoration(
                      labelText: 'Amount of Pages',
                    ),
                  ),
                   SizedBox(height: gapHeightSpace),

                  // Minutes (disabled, computed)
                  TextFormField(
                    enabled: false,
                    controller: TextEditingController(text: minutesStr),
                    decoration: _filledDecoration(
                      labelText: 'Minutes',
                      hintText: 'Computed as 2 × pages',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Continue button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Continue',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    style: buttonStyle,
                    onPressed: buttonEnabled
                        ? () {
                            // Also run Flutter validators to show messages if any
                            final ok = _formKey.currentState?.validate() ?? false;
                            if (!ok) return;

                            widget.onSubmit?.call(
                              CertificationFormData(
                                fullName: _fullNameCtrl.text.trim(),
                                certificationTitle: _titleCtrl.text.trim(),
                                phoneE164: _phoneCtrl.text.trim().isEmpty
                                    ? null
                                    : _phoneCtrl.text.trim(),
                                pages: widget.pages,
                                minutes: _minutes,
                                language: _selectedLanguage!,
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
