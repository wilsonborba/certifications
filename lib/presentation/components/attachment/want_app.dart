import 'package:flutter/material.dart';

/// Drop this widget anywhere (e.g., inside a Column).
/// When clicked, it opens a popup that asks for a website link.
/// If the user submits a valid http/https URL, the dialog closes
/// and calls [onRequest] with the URL.
class WantText extends StatefulWidget {
  const WantText({
    Key? key,
    this.onRequest,
    this.purple = const Color(0xFF7C4DFF), // main purple color
  }) : super(key: key);

  /// Called with the valid URL after the user presses "Request".
  final ValueChanged<String>? onRequest;

  /// Main accent color (purple by default).
  final Color purple;

  @override
  State<WantText> createState() => _WantTextState();
}

class _WantTextState extends State<WantText> {
  bool _hovering = false;

  Future<void> _openDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // prevent closing while success box visible
      builder: (ctx) => _LinkRequestDialog(purple: widget.purple),
    );

    if (result != null && result.isNotEmpty) {
      widget.onRequest?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 18);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _openDialog,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _hovering ? 1.05 : 1.0,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: baseStyle.copyWith(
              color: _hovering ? Colors.grey : Colors.black,
              fontWeight: _hovering ? FontWeight.w700 : FontWeight.w600,
            ),
            child: const Text('Want another app? Click here!'),
          ),
        ),
      ),
    );
  }
}

/// Internal dialog widget.
/// White theme, purple accents, responsive width, corner close button,
/// validates only http/https URLs and enables Request accordingly.
class _LinkRequestDialog extends StatefulWidget {
  const _LinkRequestDialog({required this.purple});

  final Color purple;

  @override
  State<_LinkRequestDialog> createState() => _LinkRequestDialogState();
}

class _LinkRequestDialogState extends State<_LinkRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isValid = false;

  bool _success = false;
  String? _finalUrl;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final ok = _validateUrl(_controller.text);
    if (ok != _isValid) {
      setState(() => _isValid = ok);
    }
  }

  bool _validateUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    final pattern = r'^(https?:\/\/)'
        r'(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})'
        r'(:\d+)?'
        r'(\/[^\s]*)?$';
    return RegExp(pattern).hasMatch(trimmed);
  }

  void _submit() {
    if (!_isValid) return;

    setState(() {
      _success = true;
      _finalUrl = _controller.text.trim();
    });

    // Show success box for 3 seconds, then close
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop(_finalUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dialogTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: widget.purple,
        secondary: widget.purple,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF7F7F7),
        border: OutlineInputBorder(),
      ),
    );

    return Theme(
      data: dialogTheme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final maxWidth = screenWidth < 520 ? screenWidth * 0.9 : 480.0;

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Stack(
                children: [
                  if (!_success)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                        color: Colors.black54,
                      ),
                    ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(20, 20 + (_success ? 0 : 36), 20, 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _success
                          ? _SuccessBox(url: _finalUrl ?? '', purple: widget.purple)
                          : _FormContent(
                              formKey: _formKey,
                              controller: _controller,
                              isValid: _isValid,
                              purple: widget.purple,
                              onSubmit: _submit,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.formKey,
    required this.controller,
    required this.isValid,
    required this.purple,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isValid;
  final Color purple;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Request a link',
            style: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website URL',
              hintText: 'https://example.com',
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Please enter a URL';
              final ok = RegExp(r'^(https?:\/\/)(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})(:\d+)?(\/[^\s]*)?$').hasMatch(v);
              return ok ? null : 'Enter a valid http:// or https:// URL';
            },
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? purple : Colors.grey.shade300,
                    foregroundColor: isValid ? Colors.white : Colors.black45,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: isValid ? 2 : 0,
                  ),
                  onPressed: isValid ? onSubmit : null,
                  child: const Text('Request'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Only links starting with http:// or https:// are accepted.',
            style: base.textTheme.bodySmall?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SuccessBox extends StatelessWidget {
  const _SuccessBox({required this.url, required this.purple});

  final String url;
  final Color purple;

  @override
  Widget build(BuildContext context) {
    return  Container(
      height: 300,
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withAlpha((0.08 * 255).toInt()),
        border: Border.all(color: Colors.green.withAlpha((0.35 * 255).toInt())),
      ),
      child: Center( child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 40),
          const SizedBox(height: 8),
          Text(
            // solicitation received
            'Solicitation received!',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(url,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          
        ],
      ),
    ));
  }
}
